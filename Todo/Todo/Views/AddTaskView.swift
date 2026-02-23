import SwiftUI

struct AddTaskView: View {
    @Environment(TaskViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let date: Date
    @State private var title = ""
    @State private var notes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Task")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Title")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("What needs to be done?", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                NotesEditorView(text: $notes)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Done") { submit() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private func submit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }
        viewModel.addTask(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespaces),
            date: date
        )
        dismiss()
    }
}
