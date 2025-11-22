import Foundation
import AppKit

/// Service for managing image operations with caching and optimization
@MainActor
class ImageService {
    // MARK: - Properties
    private var cache: [UUID: CachedImage] = [:]
    private var accessOrder: [UUID] = [] // For LRU tracking
    private let maxCacheSize: Int
    private let maxCacheSizeBytes: Int64
    private let fileRepository: FileRepositoryProtocol
    
    // MARK: - Cached Image Model
    private struct CachedImage {
        let data: Data
        let image: NSImage
        let size: Int64
        var lastAccessed: Date
    }
    
    // MARK: - Initialization
    init(
        fileRepository: FileRepositoryProtocol,
        maxCacheSize: Int = AppConstants.maxImageCacheSize,
        maxCacheSizeBytes: Int64 = AppConstants.maxImageCacheSizeBytes
    ) {
        self.fileRepository = fileRepository
        self.maxCacheSize = maxCacheSize
        self.maxCacheSizeBytes = maxCacheSizeBytes
    }
    
    // MARK: - Public Methods
    
    /// Loads an image, using cache if available
    func loadImage(for slideId: UUID) async throws -> NSImage {
        // Check cache first
        if let cached = cache[slideId] {
            updateAccessOrder(for: slideId)
            cache[slideId]?.lastAccessed = Date()
            Logger.shared.debug("Image loaded from cache for slide \(slideId)", category: .storage)
            return cached.image
        }
        
        // Load from file repository
        let data = try await fileRepository.loadImage(for: slideId)
        guard let image = NSImage(data: data) else {
            throw AppError.imageProcessingError("Failed to create image from data")
        }
        
        // Cache the image
        cacheImage(data: data, image: image, for: slideId)
        
        Logger.shared.debug("Image loaded from disk for slide \(slideId)", category: .storage)
        return image
    }
    
    /// Saves an image (data) to storage and cache
    func saveImage(_ data: Data, for slideId: UUID) async throws -> URL {
        let url = try await fileRepository.saveImage(data, for: slideId)
        
        // Also cache it
        if let image = NSImage(data: data) {
            cacheImage(data: data, image: image, for: slideId)
        }
        
        return url
    }
    
    /// Saves an NSImage to storage and cache
    func saveImage(_ image: NSImage, for slideId: UUID, quality: ImageQuality = .high) async throws -> URL {
        // Optimize and compress the image
        let optimizedData = try optimizeImage(image, quality: quality)
        return try await saveImage(optimizedData, for: slideId)
    }
    
    /// Deletes an image from storage and cache
    func deleteImage(for slideId: UUID) async throws {
        // Remove from cache
        removeFromCache(slideId: slideId)
        
        // Delete from storage
        try await fileRepository.deleteImage(for: slideId)
    }
    
    /// Downloads image from URL and saves it
    func downloadAndSave(from urlString: String, for slideId: UUID) async throws -> NSImage {
        guard let url = URL(string: urlString) else {
            throw AppError.imageProcessingError("Invalid image URL")
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = NSImage(data: data) else {
            throw AppError.imageProcessingError("Failed to create image from downloaded data")
        }
        
        // Save the image
        _ = try await saveImage(data, for: slideId)
        
        return image
    }
    
    /// Processes and optimizes an image
    func processImage(_ data: Data, maxSize: CGSize = CGSize(width: 1920, height: 1080)) throws -> Data {
        guard let image = NSImage(data: data) else {
            throw AppError.imageProcessingError("Invalid image data")
        }
        
        let resizedImage = resizeImage(image, to: maxSize)
        return try optimizeImage(resizedImage, quality: .high)
    }
    
    // MARK: - Cache Management
    
    private func cacheImage(data: Data, image: NSImage, for slideId: UUID) {
        let size = Int64(data.count)
        let cachedImage = CachedImage(
            data: data,
            image: image,
            size: size,
            lastAccessed: Date()
        )
        
        cache[slideId] = cachedImage
        updateAccessOrder(for: slideId)
        
        // Enforce cache limits
        enforceCacheLimits()
    }
    
    private func updateAccessOrder(for slideId: UUID) {
        // Remove from current position
        accessOrder.removeAll { $0 == slideId }
        // Add to end (most recently used)
        accessOrder.append(slideId)
    }
    
    private func removeFromCache(slideId: UUID) {
        cache.removeValue(forKey: slideId)
        accessOrder.removeAll { $0 == slideId }
    }
    
    private func enforceCacheLimits() {
        // Check size limit
        while getCurrentCacheSize() > maxCacheSizeBytes && !cache.isEmpty {
            evictLeastRecentlyUsed()
        }
        
        // Check count limit
        while cache.count > maxCacheSize && !cache.isEmpty {
            evictLeastRecentlyUsed()
        }
    }
    
    private func evictLeastRecentlyUsed() {
        guard let lruSlideId = accessOrder.first else { return }
        removeFromCache(slideId: lruSlideId)
        Logger.shared.debug("Evicted image from cache (LRU): \(lruSlideId)", category: .storage)
    }
    
    private func getCurrentCacheSize() -> Int64 {
        cache.values.reduce(0) { $0 + $1.size }
    }
    
    /// Clears entire cache
    func clearCache() {
        cache.removeAll()
        accessOrder.removeAll()
        Logger.shared.info("Image cache cleared", category: .storage)
    }
    
    /// Returns cache statistics
    func getCacheStats() -> CacheStats {
        CacheStats(
            count: cache.count,
            totalSizeBytes: getCurrentCacheSize(),
            maxSizeBytes: maxCacheSizeBytes,
            maxCount: maxCacheSize
        )
    }
    
    struct CacheStats {
        let count: Int
        let totalSizeBytes: Int64
        let maxSizeBytes: Int64
        let maxCount: Int
        
        var utilizationPercentage: Double {
            Double(totalSizeBytes) / Double(maxSizeBytes) * 100
        }
        
        var formattedSize: String {
            ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file)
        }
    }
    
    // MARK: - Image Processing
    
    private func resizeImage(_ image: NSImage, to maxSize: CGSize) -> NSImage {
        let originalSize = image.size
        
        // Calculate new size maintaining aspect ratio
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio)
        
        // If image is already smaller, return original
        if ratio >= 1.0 {
            return image
        }
        
        let newSize = CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func optimizeImage(_ image: NSImage, quality: ImageQuality) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw AppError.imageProcessingError("Failed to create bitmap representation")
        }
        
        let compressionFactor = quality.compressionQuality
        
        guard let pngData = bitmap.representation(
            using: .png,
            properties: [.compressionFactor: compressionFactor]
        ) else {
            throw AppError.imageProcessingError("Failed to create PNG data")
        }
        
        return pngData
    }
}
