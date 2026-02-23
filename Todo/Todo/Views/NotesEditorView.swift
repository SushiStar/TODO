import SwiftUI

struct NotesEditorView: View {
    @Binding var text: String
    var placeholder: String = "Add details…"

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .frame(minHeight: 80, maxHeight: 120)
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .font(.body)
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
                    .padding(.leading, 4)
                    .allowsHitTesting(false)
            }
        }
        .padding(4)
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
    }
}
