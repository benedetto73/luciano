//
//  FilePreviewView.swift
//  PresentationGenerator
//
//  Preview component for imported files
//

import SwiftUI

struct FilePreviewView: View {
    let file: SourceFile
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // File Icon
            fileIcon
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text(file.filename)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // File Size
                    Label(formatFileSize(file.fileSize), systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Import Date
                    Label(formatDate(file.importedDate), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Text Preview
                if let preview = file.textPreview {
                    Text(preview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .opacity(isHovered ? 1.0 : 0.6)
            }
            .buttonStyle(.plain)
            .help("Remove file")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - File Icon
    
    private var fileIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(fileTypeColor.opacity(0.15))
                .frame(width: 50, height: 50)
            
            Image(systemName: fileTypeIcon)
                .font(.system(size: 24))
                .foregroundColor(fileTypeColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var fileTypeIcon: String {
        let ext = file.fileExtension.lowercased()
        switch ext {
        case "txt":
            return "doc.text"
        case "doc", "docx":
            return "doc.richtext"
        case "pdf":
            return "doc.fill"
        default:
            return "doc"
        }
    }
    
    private var fileTypeColor: Color {
        let ext = file.fileExtension.lowercased()
        switch ext {
        case "txt":
            return .blue
        case "doc", "docx":
            return .indigo
        case "pdf":
            return .red
        default:
            return .gray
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - SourceFile Extension for Preview

extension SourceFile {
    var textPreview: String? {
        guard !content.isEmpty else { return nil }
        let preview = String(content.prefix(200))
        return preview.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var fileExtension: String {
        (filename as NSString).pathExtension
    }
}

#if DEBUG
struct FilePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FilePreviewView(
                file: SourceFile(
                    id: UUID(),
                    filename: "sample_content.txt",
                    content: "This is a sample text file with some content that demonstrates the preview functionality. It shows how the file preview will look in the application.",
                    fileSize: 15234,
                    importedDate: Date(),
                    fileType: .txt
                ),
                onRemove: {}
            )
            .padding()
            .frame(width: 600)
            .previewDisplayName("Text File")

            FilePreviewView(
                file: SourceFile(
                    id: UUID(),
                    filename: "presentation_outline.docx",
                    content: "Introduction to Machine Learning\n\nMachine learning is a subset of artificial intelligence that enables systems to learn and improve from experience without being explicitly programmed.",
                    fileSize: 45678,
                    importedDate: Date(),
                    fileType: .docx
                ),
                onRemove: {}
            )
            .padding()
            .frame(width: 600)
            .previewDisplayName("Word Document")
            
            FilePreviewView(
                file: SourceFile(
                    id: UUID(),
                    filename: "comprehensive_research_document.doc",
                    content: "",
                    fileSize: 2_500_000,
                    importedDate: Date(),
                    fileType: .doc
                ),
                onRemove: {}
            )
            .padding()
            .frame(width: 600)
            .previewDisplayName("Large File")
        }
    }
}
#endif
