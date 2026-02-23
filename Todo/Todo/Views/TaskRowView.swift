import SwiftUI

struct TaskRowView: View {
    @Environment(TaskViewModel.self) private var viewModel
    let task: Task
    @State private var showingDetail = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: { viewModel.toggleComplete(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            Button(action: { showingDetail = true }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)

                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if task.isCarriedOver {
                        Text("Carried over")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button(action: { viewModel.deleteTask(task) }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0.7)
            .padding(.top, 2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .sheet(isPresented: $showingDetail) {
            TaskDetailView(task: task)
                .environment(viewModel)
        }
    }
}
