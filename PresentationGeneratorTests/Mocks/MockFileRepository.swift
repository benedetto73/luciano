import Foundation
@testable import PresentationGenerator

/// Mock implementation of FileRepositoryProtocol for testing
class MockFileRepository: FileRepositoryProtocol {
    var importedDocuments: [URL: String] = [:]
    var savedImages: [UUID: Data] = [:]
    var shouldThrowError = false
    var errorToThrow: Error = AppError.fileImportError(
        NSError(domain: "Mock", code: 500, userInfo: nil)
    )
    
    func importDocument(from url: URL) async throws -> String {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let content = importedDocuments[url] {
            return content
        }
        
        // Return mock content
        return "This is mock document content from \(url.lastPathComponent)"
    }
    
    func saveImage(_ data: Data, for slideId: UUID) async throws -> URL {
        if shouldThrowError {
            throw errorToThrow
        }
        savedImages[slideId] = data
        return URL(fileURLWithPath: "/mock/images/\(slideId).png")
    }
    
    func loadImage(for slideId: UUID) async throws -> Data {
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let data = savedImages[slideId] else {
            throw AppError.imageProcessingError("Image not found")
        }
        return data
    }
    
    func deleteImage(for slideId: UUID) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        savedImages.removeValue(forKey: slideId)
    }
    
    func cleanupUnusedImages(usedSlideIds: Set<UUID>) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        let allSlideIds = Set(savedImages.keys)
        let unusedIds = allSlideIds.subtracting(usedSlideIds)
        for id in unusedIds {
            savedImages.removeValue(forKey: id)
        }
    }
    
    func setMockDocument(url: URL, content: String) {
        importedDocuments[url] = content
    }
    
    func reset() {
        importedDocuments.removeAll()
        savedImages.removeAll()
        shouldThrowError = false
    }
}
