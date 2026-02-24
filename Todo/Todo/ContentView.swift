import SwiftUI
import Combine

struct ContentView: View {
    @Environment(TaskViewModel.self) private var viewModel
    @State private var showingAddTask = false
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var today = Calendar.current.startOfDay(for: Date())

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private var dateLabel: String {
        Self.dateFormatter.string(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var tasks: [Task] { viewModel.tasks(for: selectedDate) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Button(action: prevDay) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Text(dateLabel)
                    .font(.headline)
                    .foregroundStyle(isToday ? .green : .primary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Button(action: nextDay) {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Divider().frame(height: 16)

                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            if tasks.isEmpty {
                VStack {
                    Spacer()
                    Text("No tasks")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TaskRowView(task: task)
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            let newToday = Calendar.current.startOfDay(for: Date())
            guard newToday != today else { return }
            today = newToday
            viewModel.performCarryoverIfNeeded()
            selectedDate = newToday
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(date: selectedDate)
                .environment(viewModel)
        }
    }

    private func prevDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
    }

    private func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
    }
}
