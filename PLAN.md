# Todo macOS App — Build Plan

A personal floating-window TODO app for macOS built with SwiftUI + AppKit.

---

## Features

- Floating window that stays on top of all other apps
- Today's date displayed in the header
- Add / Complete / Remove tasks for today
- Carryover of incomplete tasks to the next day on launch
- Local JSON storage at `~/Library/Application Support/Todo/tasks.json`

---

## File Structure

```
Todo/
├── PLAN.md                       ← this file
├── Todo.xcodeproj/               ← Step 1: create via Xcode
└── Todo/
    ├── App/
    │   ├── TodoApp.swift         ← Step 2: @main entry point
    │   └── AppDelegate.swift     ← Step 3: NSPanel (floating window) setup
    ├── Model/
    │   ├── Task.swift            ← Step 4: Task data model
    │   └── TaskStore.swift       ← Step 5: JSON envelope with lastLaunchDate
    ├── Storage/
    │   └── StorageManager.swift  ← Step 6: read/write JSON to disk
    ├── ViewModel/
    │   └── TaskViewModel.swift   ← Step 7: business logic + carryover
    └── Views/
        ├── ContentView.swift     ← Step 8: root layout (header / list / input)
        ├── TaskRowView.swift     ← Step 9: individual task row
        └── AddTaskBar.swift      ← Step 10: text input + add button
```

---

## Step-by-Step Build Plan

### Step 1 — Create the Xcode Project

- Open Xcode → File → New → Project → macOS → **App**
- Product Name: `Todo`
- Language: Swift | Interface: SwiftUI
- Uncheck "Include Tests"
- Save into `/Users/waynedu/Playground/Todo/`

> This produces the `Todo.xcodeproj` and a default `Todo/` folder with `ContentView.swift` and `TodoApp.swift`.

---

### Step 2 — `TodoApp.swift` (@main entry point)

Attach the custom `AppDelegate` so we can control the window manually.
SwiftUI Scene is set to `Settings { EmptyView() }` to prevent an auto-generated window.

```swift
import SwiftUI

@main
struct TodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
```

---

### Step 3 — `AppDelegate.swift` (Floating NSPanel)

Creates an `NSPanel` that:
- Stays above all normal windows (`.floating` level)
- Does not steal focus from the current app (`.nonactivatingPanel`)
- Stays visible across all Spaces and when another app goes full-screen
- Has no title bar text; draggable by clicking anywhere on the window

```swift
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let vm = TaskViewModel()
        let contentView = ContentView().environmentObject(vm)

        window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 500),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isFloatingPanel = true
        window.hidesOnDeactivate = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 280, height: 300)
        window.maxSize = NSSize(width: 480, height: 800)
        window.contentView = NSHostingView(rootView: contentView)

        // Position: top-right of main screen
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 340
            let y = screen.visibleFrame.maxY - 520
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
```

---

### Step 4 — `Task.swift` (Data Model)

```swift
import Foundation

struct Task: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdDate: Date       // start-of-day; used to filter today's tasks
    var completedDate: Date?
    var isCarriedOver: Bool     // display hint shown in the UI

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdDate: Date = Calendar.current.startOfDay(for: Date()),
        completedDate: Date? = nil,
        isCarriedOver: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdDate = createdDate
        self.completedDate = completedDate
        self.isCarriedOver = isCarriedOver
    }
}
```

---

### Step 5 — `TaskStore.swift` (JSON Envelope)

```swift
import Foundation

struct TaskStore: Codable {
    var tasks: [Task]
    var lastLaunchDate: Date    // carryover trigger: compared against today on launch
}
```

---

### Step 6 — `StorageManager.swift` (Persistence)

Reads and writes `tasks.json` atomically.

```swift
import Foundation

final class StorageManager {
    static let shared = StorageManager()

    private let fileURL: URL

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .prettyPrinted
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("Todo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("tasks.json")
    }

    func load() -> TaskStore {
        guard let data = try? Data(contentsOf: fileURL),
              let store = try? decoder.decode(TaskStore.self, from: data)
        else {
            return TaskStore(tasks: [], lastLaunchDate: Date())
        }
        return store
    }

    func save(_ store: TaskStore) {
        guard let data = try? encoder.encode(store) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
```

---

### Step 7 — `TaskViewModel.swift` (Business Logic + Carryover)

On init: loads data, runs carryover if needed, exposes only today's tasks to the UI.

**Carryover logic:**
- Fires when `lastLaunchDate` is not today
- Incomplete tasks from prior days → `createdDate` reset to today, `isCarriedOver = true`
- Completed tasks from prior days are pruned (they're done)

```swift
import Foundation

final class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var newTaskTitle: String = ""

    private var store: TaskStore

    init() {
        store = StorageManager.shared.load()
        performCarryoverIfNeeded()
        refreshTodayTasks()
    }

    // MARK: - Public mutations

    func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let task = Task(title: title)
        store.tasks.append(task)
        newTaskTitle = ""
        persist()
        refreshTodayTasks()
    }

    func toggleComplete(_ task: Task) {
        guard let idx = store.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        store.tasks[idx].isCompleted.toggle()
        store.tasks[idx].completedDate = store.tasks[idx].isCompleted ? Date() : nil
        persist()
        refreshTodayTasks()
    }

    func deleteTask(_ task: Task) {
        store.tasks.removeAll { $0.id == task.id }
        persist()
        refreshTodayTasks()
    }

    func deleteTasksAtOffsets(_ offsets: IndexSet) {
        let idsToDelete = offsets.map { tasks[$0].id }
        store.tasks.removeAll { idsToDelete.contains($0.id) }
        persist()
        refreshTodayTasks()
    }

    // MARK: - Private

    private func refreshTodayTasks() {
        let cal = Calendar.current
        tasks = store.tasks.filter { cal.isDateInToday($0.createdDate) }
    }

    private func persist() {
        StorageManager.shared.save(store)
    }

    private func performCarryoverIfNeeded() {
        let cal = Calendar.current
        guard !cal.isDateInToday(store.lastLaunchDate) else { return }
        let today = cal.startOfDay(for: Date())
        for i in store.tasks.indices where !store.tasks[i].isCompleted {
            if !cal.isDateInToday(store.tasks[i].createdDate) {
                store.tasks[i].createdDate = today
                store.tasks[i].isCarriedOver = true
            }
        }
        store.tasks.removeAll { $0.isCompleted && !cal.isDateInToday($0.createdDate) }
        store.lastLaunchDate = Date()
        StorageManager.shared.save(store)
    }
}
```

---

### Step 8 — `ContentView.swift` (Root Layout)

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: TaskViewModel

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateString)
                        .font(.headline)
                    Text("\(vm.tasks.filter(\.isCompleted).count) / \(vm.tasks.count) done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)

            Divider()

            // Task list
            if vm.tasks.isEmpty {
                Spacer()
                Text("No tasks for today")
                    .foregroundStyle(.tertiary)
                    .font(.callout)
                Spacer()
            } else {
                List {
                    ForEach(vm.tasks) { task in
                        TaskRowView(task: task)
                    }
                    .onDelete { vm.deleteTasksAtOffsets($0) }
                }
                .listStyle(.plain)
            }

            Divider()

            // Input bar
            AddTaskBar()
        }
        .frame(minWidth: 280, minHeight: 300)
    }
}
```

---

### Step 9 — `TaskRowView.swift` (Task Row)

```swift
import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject var vm: TaskViewModel
    let task: Task

    var body: some View {
        HStack(spacing: 10) {
            Button { vm.toggleComplete(task) } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                if task.isCarriedOver {
                    Text("Carried over")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Button { vm.deleteTask(task) } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
```

---

### Step 10 — `AddTaskBar.swift` (Input)

```swift
import SwiftUI

struct AddTaskBar: View {
    @EnvironmentObject var vm: TaskViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Add a task…", text: $vm.newTaskTitle)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit { vm.addTask() }

            Button { vm.addTask() } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(vm.newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
```

---

## Build & Run

```bash
# From command line after project exists:
xcodebuild -project Todo.xcodeproj -scheme Todo -configuration Debug build
open .build/Build/Products/Debug/Todo.app

# Or just press Cmd+R inside Xcode
```

---

## Verification Checklist

- [ ] App launches as a floating window above all other apps
- [ ] Window does not steal focus when clicked
- [ ] Header shows today's date and task count
- [ ] Add a task (Enter or + button) — appears in list
- [ ] Check a task — strikethrough applied, count updates
- [ ] Delete (×) removes a task immediately
- [ ] Quit app → relaunch same day → tasks persist unchanged
- [ ] Simulate next-day launch → incomplete tasks show "Carried over", completed are gone
- [ ] `~/Library/Application Support/Todo/tasks.json` is human-readable JSON
