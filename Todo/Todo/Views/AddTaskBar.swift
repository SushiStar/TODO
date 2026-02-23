import SwiftUI

struct AddTaskBar: View {
    @Environment(TaskViewModel.self) private var viewModel
    @State private var text = ""

    var body: some View {
        HStack(spacing: 8) {
            TextField("New task…", text: $text)
                .textFieldStyle(.plain)
                .onSubmit { submit() }

            Button(action: submit) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.addTask(title: trimmed)
        text = ""
    }
}
