import Foundation
import OpenAI
import AppKit

/// Service for interacting with OpenAI's DALL-E image generation API
/// Handles creating, downloading, and optimizing AI-generated images
actor DALLEService {
    private let apiKey: String
    private let client: OpenAIProtocol
    private let maxRetries: Int = 3
    private let baseDelay: TimeInterval = 2.0 // DALL-E is slower
    
    // MARK: - Initialization
    
    init(apiKey: String, client: OpenAIProtocol? = nil) {
        self.apiKey = apiKey
        self.client = client ?? OpenAI(apiKey: apiKey)
    }
    
    // MARK: - Public Methods
    
    /// Generates an image from a text prompt
    /// - Parameters:
    ///   - request: The image generation request with prompt and parameters
    /// - Returns: The generated image data
    /// - Throws: OpenAIError for API failures or image processing errors
    func generateImage(request: ImageGenerationRequest) async throws -> Data {
        let imageURLs = try await withRetry(maxAttempts: maxRetries) {
            try await self.performImageGeneration(request: request)
        }
        
        guard let firstURL = imageURLs.first else {
            throw OpenAIError.emptyResponse
        }
        
        // Download the image
        let imageData = try await downloadImage(from: firstURL)
        
        // Optimize if needed
        if request.optimize {
            return try optimizeImage(imageData, targetSizeKB: 500)
        }
        
        return imageData
    }
    
    /// Generates an image optimized for a specific audience
    /// - Parameters:
    ///   - prompt: Base description of the image
    ///   - audience: Target audience (affects style)
    ///   - size: Image size (defaults to 1024x1024)
    /// - Returns: Optimized image data
    func generateImageForAudience(
        prompt: String,
        audience: Audience,
        size: ImageSize = .large
    ) async throws -> Data {
        let enhancedPrompt = enhancePromptForAudience(prompt, audience: audience)
        
        let request = ImageGenerationRequest(
            prompt: enhancedPrompt,
            size: size.rawValue,
            quality: audience == .kids ? "standard" : "hd",
            style: audience == .kids ? "vivid" : "natural",
            optimize: true
        )
        
        Logger.shared.info(
            "Generating \(audience.rawValue) image with prompt: \(enhancedPrompt.prefix(50))...",
            category: .api
        )
        
        return try await generateImage(request: request)
    }
    
    /// Generates multiple variations of an image
    /// - Parameters:
    ///   - prompt: Image description
    ///   - count: Number of variations (1-4)
    ///   - audience: Target audience
    /// - Returns: Array of image data
    func generateVariations(
        prompt: String,
        count: Int = 2,
        audience: Audience
    ) async throws -> [Data] {
        let validCount = min(max(count, 1), 4) // OpenAI limits to 10, we cap at 4
        let enhancedPrompt = enhancePromptForAudience(prompt, audience: audience)
        
        let request = ImageGenerationRequest(
            prompt: enhancedPrompt,
            n: validCount,
            size: ImageSize.medium.rawValue,
            quality: "standard",
            style: audience == .kids ? "vivid" : "natural",
            optimize: true
        )
        
        let imageURLs = try await withRetry(maxAttempts: maxRetries) {
            try await self.performImageGeneration(request: request)
        }
        
        // Download all images concurrently
        return try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            for (index, url) in imageURLs.enumerated() {
                group.addTask {
                    let data = try await self.downloadImage(from: url)
                    let optimized = try self.optimizeImage(data, targetSizeKB: 300)
                    return (index, optimized)
                }
            }
            
            var results: [(Int, Data)] = []
            for try await result in group {
                results.append(result)
            }
            
            // Sort by original index and return data only
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    // MARK: - Private Methods
    
    private func performImageGeneration(request: ImageGenerationRequest) async throws -> [URL] {
        do {
            // Convert our DTO to OpenAI SDK format
            let query = ImagesQuery(
                prompt: request.prompt,
                model: .dall_e_3, // Use DALL-E 3 for better quality
                n: request.n ?? 1,
                quality: ImagesQuery.Quality(rawValue: request.quality ?? "standard") ?? .standard,
                responseFormat: .url, // Get URLs instead of base64 for efficiency
                size: ImagesQuery.Size(rawValue: request.size ?? "1024x1024") ?? ._1024x1024,
                style: ImagesQuery.Style(rawValue: request.style ?? "vivid") ?? .vivid
            )
            
            let result = try await client.images(query: query)
            
            // Extract URLs from response
            let urls = result.data.compactMap { imageResult -> URL? in
                guard let urlString = imageResult.url else { return nil }
                return URL(string: urlString)
            }
            
            guard !urls.isEmpty else {
                throw OpenAIError.emptyResponse
            }
            
            Logger.shared.info("Generated \(urls.count) image(s)", category: .api)
            return urls
            
        } catch {
            throw mapError(error)
        }
    }
    
    /// Downloads image data from URL
    private func downloadImage(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIError.networkError(URLError(.badServerResponse))
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OpenAIError.networkError(
                    URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                )
            }
            
            guard !data.isEmpty else {
                throw OpenAIError.imageProcessingError("Downloaded image is empty")
            }
            
            Logger.shared.info("Downloaded image: \(data.count) bytes", category: .api)
            return data
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            throw OpenAIError.networkError(error)
        }
    }
    
    /// Optimizes image by compressing if needed
    private func optimizeImage(_ data: Data, targetSizeKB: Int) throws -> Data {
        guard let image = NSImage(data: data) else {
            throw OpenAIError.imageProcessingError("Could not create image from data")
        }
        
        // If already small enough, return as-is
        let currentSizeKB = data.count / 1024
        if currentSizeKB <= targetSizeKB {
            Logger.shared.info("Image already optimized: \(currentSizeKB)KB", category: .api)
            return data
        }
        
        // Convert to bitmap and compress
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            throw OpenAIError.imageProcessingError("Could not create bitmap representation")
        }
        
        // Try different compression levels
        var compressionFactor: Float = 0.8
        var optimizedData: Data?
        
        while compressionFactor > 0.1 {
            let properties: [NSBitmapImageRep.PropertyKey: Any] = [
                .compressionFactor: compressionFactor
            ]
            
            if let pngData = bitmapImage.representation(using: .png, properties: properties) {
                let sizeKB = pngData.count / 1024
                if sizeKB <= targetSizeKB {
                    optimizedData = pngData
                    Logger.shared.info(
                        "Optimized image from \(currentSizeKB)KB to \(sizeKB)KB (compression: \(compressionFactor))",
                        category: .api
                    )
                    break
                }
            }
            
            compressionFactor -= 0.1
        }
        
        // If we couldn't compress enough, return the best we got or original
        return optimizedData ?? data
    }
    
    /// Enhances prompt with audience-specific styling
    private func enhancePromptForAudience(_ prompt: String, audience: Audience) -> String {
        let designPrefs = audience.designPreferences
        
        var enhancedPrompt = prompt
        
        // Add style guidance based on audience
        switch audience {
        case .kids:
            enhancedPrompt += ", cartoon style, bright colors, simple shapes, cheerful and friendly"
            if designPrefs.imageStyle.contains("playful") {
                enhancedPrompt += ", playful and fun illustration"
            }
            
        case .adults:
            enhancedPrompt += ", professional style, clean composition, sophisticated"
            if designPrefs.imageStyle.contains("modern") {
                enhancedPrompt += ", modern and contemporary aesthetic"
            }
        }
        
        // Add Catholic context if not already present
        if !prompt.lowercased().contains("catholic") &&
           !prompt.lowercased().contains("christian") &&
           !prompt.lowercased().contains("religious") {
            enhancedPrompt += ", Catholic religious educational context"
        }
        
        // Ensure appropriate content
        enhancedPrompt += ", appropriate for all ages, respectful"
        
        return enhancedPrompt
    }
    
    /// Retries an operation with exponential backoff
    private func withRetry<T>(
        maxAttempts: Int,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch let error as OpenAIError {
                lastError = error
                
                // Only retry on rate limits and server errors
                if error.isRetryable && attempt < maxAttempts - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    Logger.shared.warning(
                        "Image generation failed (attempt \(attempt + 1)/\(maxAttempts)), retrying in \(delay)s",
                        category: .api
                    )
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw error
                }
            } catch {
                throw mapError(error)
            }
        }
        
        throw lastError ?? OpenAIError.unknownError("Retry failed")
    }
    
    /// Maps SDK errors to our OpenAIError type
    private func mapError(_ error: Error) -> OpenAIError {
        // Check if it's already an OpenAIError
        if let openAIError = error as? OpenAIError {
            return openAIError
        }
        
        // Map URLErrors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(urlError)
            case .timedOut:
                return .timeout
            default:
                return .networkError(urlError)
            }
        }
        
        // Check error description for common API errors
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("rate limit") || errorDescription.contains("429") {
            return .rateLimitExceeded
        }
        
        if errorDescription.contains("invalid api key") || errorDescription.contains("401") {
            return .invalidAPIKey
        }
        
        if errorDescription.contains("content policy") || errorDescription.contains("filtered") {
            return .contentFiltered
        }
        
        if errorDescription.contains("billing") || errorDescription.contains("quota") {
            return .insufficientQuota
        }
        
        return .unknownError(error.localizedDescription)
    }
}

// MARK: - Supporting Types

enum ImageSize: String {
    case small = "256x256"
    case medium = "512x512"
    case large = "1024x1024"
    case extraLarge = "1792x1024"
    case portrait = "1024x1792"
}
