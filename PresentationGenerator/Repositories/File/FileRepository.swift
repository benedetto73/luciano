import Foundation
import AppKit

/// Repository for file operations (documents and images)
class FileRepository: FileRepositoryProtocol {
    private let documentParser: DocumentParser
    private let fileManager: FileManager
    
    init(
        documentParser: DocumentParser = DocumentParser(),
        fileManager: FileManager = .default
    ) {
        self.documentParser = documentParser
        self.fileManager = fileManager
    }
    
    // MARK: - FileRepositoryProtocol
    
    func importDocument(from url: URL) async throws -> String {
        Logger.shared.info("Importing document from \(url.lastPathComponent)", category: .fileImport)
        
        // Parse the document
        let text = try await documentParser.parse(url)
        
        // Validate the extracted text
        try documentParser.validate(text: text)
        
        Logger.shared.info(
            "Document imported successfully (\(text.count) characters)",
            category: .fileImport
        )
        
        return text
    }
    
    func saveImage(_ data: Data, for slideId: UUID) async throws -> URL {
        let filename = "\(slideId.uuidString).png"
        let imageURL = AppConstants.imagesDirectory.appendingPathComponent(filename)
        
        // Ensure images directory exists
        try createImagesDirectoryIfNeeded()
        
        do {
            try data.write(to: imageURL, options: [.atomic])
            Logger.shared.info("Image saved for slide \(slideId)", category: .storage)
            return imageURL
        } catch {
            Logger.shared.error("Failed to save image", error: error, category: .storage)
            throw AppError.imageProcessingError("Failed to save image: \(error.localizedDescription)")
        }
    }
    
    func loadImage(for slideId: UUID) async throws -> Data {
        let filename = "\(slideId.uuidString).png"
        let imageURL = AppConstants.imagesDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: imageURL.path) else {
            throw AppError.imageProcessingError("Image not found for slide \(slideId)")
        }
        
        do {
            let data = try Data(contentsOf: imageURL)
            Logger.shared.debug("Image loaded for slide \(slideId)", category: .storage)
            return data
        } catch {
            Logger.shared.error("Failed to load image", error: error, category: .storage)
            throw AppError.imageProcessingError("Failed to load image: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Additional Methods
    
    func saveCustomImage(_ image: NSImage, for slideId: UUID) async throws -> URL {
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw AppError.imageProcessingError("Failed to convert image to PNG format")
        }
        
        return try await saveImage(pngData, for: slideId)
    }
    
    func deleteImage(for slideId: UUID) async throws {
        let filename = "\(slideId.uuidString).png"
        let imageURL = AppConstants.imagesDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: imageURL.path) else {
            // Image doesn't exist, nothing to delete
            return
        }
        
        do {
            try fileManager.removeItem(at: imageURL)
            Logger.shared.info("Image deleted for slide \(slideId)", category: .storage)
        } catch {
            Logger.shared.error("Failed to delete image", error: error, category: .storage)
            throw AppError.imageProcessingError("Failed to delete image: \(error.localizedDescription)")
        }
    }
    
    func imageExists(for slideId: UUID) -> Bool {
        let filename = "\(slideId.uuidString).png"
        let imageURL = AppConstants.imagesDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: imageURL.path)
    }
    
    // MARK: - Helper Methods
    
    private func createImagesDirectoryIfNeeded() throws {
        let imagesDir = AppConstants.imagesDirectory
        
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try fileManager.createDirectory(
                at: imagesDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            Logger.shared.info("Created images directory", category: .storage)
        }
    }
    
    func cleanupUnusedImages(usedSlideIds: Set<UUID>) async throws {
        let imagesDir = AppConstants.imagesDirectory
        
        guard fileManager.fileExists(atPath: imagesDir.path) else {
            return
        }
        
        let imageFiles = try fileManager.contentsOfDirectory(
            at: imagesDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        var deletedCount = 0
        for fileURL in imageFiles {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            if let slideId = UUID(uuidString: filename),
               !usedSlideIds.contains(slideId) {
                try? fileManager.removeItem(at: fileURL)
                deletedCount += 1
            }
        }
        
        if deletedCount > 0 {
            Logger.shared.info("Cleaned up \(deletedCount) unused images", category: .storage)
        }
    }
    
    func getTotalImagesSize() throws -> Int64 {
        let imagesDir = AppConstants.imagesDirectory
        
        guard fileManager.fileExists(atPath: imagesDir.path) else {
            return 0
        }
        
        let imageFiles = try fileManager.contentsOfDirectory(
            at: imagesDir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        
        var totalSize: Int64 = 0
        for fileURL in imageFiles {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
}
