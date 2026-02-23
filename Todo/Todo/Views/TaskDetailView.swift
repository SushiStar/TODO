import SwiftUI

struct TaskDetailView: View {
    @Environment(TaskViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let task: Task
    @State private var title: String
    @State private var notes: String

    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                NotesEditorView(text: $notes, placeholder: "No notes")
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Save") { save() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        viewModel.updateTask(task, title: trimmedTitle, notes: notes.trimmingCharacters(in: .whitespaces))
        dismiss()
    }
}
