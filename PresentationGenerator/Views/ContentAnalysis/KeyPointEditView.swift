//
//  KeyPointEditView.swift
//  PresentationGenerator
//
//  View for editing key point text
//

import SwiftUI

struct KeyPointEditView: View {
    @Binding var keyPoint: KeyPoint
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedText: String
    @State private var characterCount: Int = 0
    
    private let maxCharacters = 500
    
    init(keyPoint: Binding<KeyPoint>) {
        self._keyPoint = keyPoint
        self._editedText = State(initialValue: keyPoint.wrappedValue.content)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView
            
            Divider()
            
            // Editor
            editorView
            
            // Character Count
            characterCountView
            
            Spacer()
            
            // Action Buttons
            actionButtons
        }
        .padding()
        .frame(width: 500, height: 350)
        .onAppear {
            updateCharacterCount()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Edit Key Point")
                .font(.headline)
            
            Text("Modify the text of this key point")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Editor
    
    private var editorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Point Text")
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextEditor(text: $editedText)
                .font(.body)
                .frame(height: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: editedText) { _ in
                    updateCharacterCount()
                    enforceCharacterLimit()
                }
        }
    }
    
    // MARK: - Character Count
    
    private var characterCountView: some View {
        HStack {
            Spacer()
            
            Text("\(characterCount) / \(maxCharacters)")
                .font(.caption)
                .foregroundColor(characterCount > maxCharacters ? .red : .secondary)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button("Save") {
                saveChanges()
            }
            .buttonStyle(.borderedProminent)
            .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || characterCount > maxCharacters)
            .keyboardShortcut(.defaultAction)
        }
    }
    
    // MARK: - Methods
    
    private func updateCharacterCount() {
        characterCount = editedText.count
    }
    
    private func enforceCharacterLimit() {
        if characterCount > maxCharacters {
            editedText = String(editedText.prefix(maxCharacters))
        }
    }
    
    private func saveChanges() {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        keyPoint.content = trimmedText
        dismiss()
    }
}

#if DEBUG
struct KeyPointEditView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State private var keyPoint = KeyPoint(
            id: UUID(),
            content: "This is a sample key point that can be edited",
            order: 0,
            isIncluded: true
        )
        
        var body: some View {
            KeyPointEditView(keyPoint: $keyPoint)
        }
    }
}
#endif
