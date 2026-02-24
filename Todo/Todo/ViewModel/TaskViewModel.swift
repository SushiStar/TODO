import Foundation
import Observation

@Observable
final class TaskViewModel {
    var store: TaskStore

    func tasks(for date: Date) -> [Task] {
        store.tasks
            .filter { Calendar.current.isDate($0.createdDate, inSameDayAs: date) }
            .sorted { !$0.isCompleted && $1.isCompleted }
    }

    init() {
        store = StorageManager.shared.load()
        performCarryoverIfNeeded()
    }

    func performCarryoverIfNeeded() {
        guard !Calendar.current.isDateInToday(store.lastLaunchDate) else { return }
        let today = Calendar.current.startOfDay(for: Date())
        for i in store.tasks.indices where !store.tasks[i].isCompleted {
            store.tasks[i].createdDate = today
            store.tasks[i].isCarriedOver = true
        }
        store.lastLaunchDate = Date()
        StorageManager.shared.save(store)
    }

    func addTask(title: String, notes: String = "", date: Date = Calendar.current.startOfDay(for: Date())) {
        let task = Task(title: title, notes: notes, createdDate: date)
        store.tasks.append(task)
        StorageManager.shared.save(store)
    }

    func toggleComplete(_ task: Task) {
        guard let i = store.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        store.tasks[i].isCompleted.toggle()
        store.tasks[i].completedDate = store.tasks[i].isCompleted ? Date() : nil
        StorageManager.shared.save(store)
    }

    func updateTask(_ task: Task, title: String, notes: String) {
        guard let i = store.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        store.tasks[i].title = title
        store.tasks[i].notes = notes
        StorageManager.shared.save(store)
    }

    func deleteTask(_ task: Task) {
        store.tasks.removeAll { $0.id == task.id }
        StorageManager.shared.save(store)
    }
}
