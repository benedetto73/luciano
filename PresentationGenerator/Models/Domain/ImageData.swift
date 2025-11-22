import Foundation

// Supporting Model: ImageData
// Full implementation will be done in Phase 1 (Task 5)

struct ImageData: Codable, Hashable {
    let id: UUID
    var localURL: URL?
    var remoteURL: String?
    var generationPrompt: String?
    var width: Int
    var height: Int
    var fileSize: Int64
    var format: ImageFormat
    
    init(
        id: UUID = UUID(),
        localURL: URL? = nil,
        remoteURL: String? = nil,
        generationPrompt: String? = nil,
        width: Int = 1024,
        height: Int = 1024,
        fileSize: Int64 = 0,
        format: ImageFormat = .png
    ) {
        self.id = id
        self.localURL = localURL
        self.remoteURL = remoteURL
        self.generationPrompt = generationPrompt
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.format = format
    }
}

enum ImageFormat: String, Codable, Hashable {
    case png
    case jpg
    case jpeg
    
    var fileExtension: String {
        ".\(rawValue)"
    }
    
    var mimeType: String {
        switch self {
        case .png: return "image/png"
        case .jpg, .jpeg: return "image/jpeg"
        }
    }
}
