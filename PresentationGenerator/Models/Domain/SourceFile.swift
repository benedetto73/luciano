import Foundation

// Supporting Model: SourceFile
// Full implementation will be done in Phase 1 (Task 5)

struct SourceFile: Codable, Identifiable, Hashable {
    let id: UUID
    var filename: String
    var content: String
    var fileSize: Int64
    var importedDate: Date
    var fileType: DocumentType
    
    init(
        id: UUID = UUID(),
        filename: String,
        content: String,
        fileSize: Int64,
        importedDate: Date = Date(),
        fileType: DocumentType
    ) {
        self.id = id
        self.filename = filename
        self.content = content
        self.fileSize = fileSize
        self.importedDate = importedDate
        self.fileType = fileType
    }
}

enum DocumentType: String, Codable, Hashable {
    case doc
    case docx
    case txt
    case rtf
    
    var fileExtension: String {
        ".\(rawValue)"
    }
}
