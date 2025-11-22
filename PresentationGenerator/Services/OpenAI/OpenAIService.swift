import Foundation

/// Main service coordinating OpenAI API interactions
/// Combines GPT and DALL-E services with content filtering
@MainActor
class OpenAIService: ObservableObject {
    private let gptService: GPTService
    private let dalleService: DALLEService
    private let contentFilter: ContentFilter
    
    @Published var isProcessing = false
    @Published var lastError: OpenAIError?
    
    // MARK: - Initialization
    
    init(apiKey: String) {
        self.gptService = GPTService(apiKey: apiKey)
        self.dalleService = DALLEService(apiKey: apiKey)
        self.contentFilter = ContentFilter(gptService: gptService)
    }
    
    // For testing with mock services
    init(gptService: GPTService, dalleService: DALLEService, contentFilter: ContentFilter) {
        self.gptService = gptService
        self.dalleService = dalleService
        self.contentFilter = contentFilter
    }
    
    // MARK: - Content Analysis
    
    /// Analyzes document content and extracts teaching points
    /// - Parameters:
    ///   - text: Document content to analyze
    ///   - audience: Target audience
    /// - Returns: Analysis result with key points and suggested slide count
    func analyzeContent(text: String, audience: Audience) async throws -> ContentAnalysisResult {
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.shared.info("Analyzing content for \(audience.rawValue) audience", category: .api)
        
        do {
            // First validate the content is appropriate
            let validation = try await contentFilter.validateContent(text, audience: audience)
            
            if !validation.isApproved {
                Logger.shared.warning("Content validation failed: \(validation.concerns.joined(separator: ", "))", category: .api)
                throw OpenAIError.contentFiltered
            }
            
            // Analyze the content
            let result = try await gptService.analyzeContent(content: text, audience: audience)
            
            Logger.shared.info("Analysis complete: \(result.keyPoints.count) key points, \(result.suggestedSlideCount) suggested slides", category: .api)
            
            return result
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Content analysis failed", error: error, category: .api)
            throw error
        } catch {
            let mappedError = OpenAIError.unknownError(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
    
    // MARK: - Slide Generation
    
    /// Generates complete slide content (text + image)
    /// - Parameters:
    ///   - keyPoint: Teaching point to create slide for
    ///   - audience: Target audience
    ///   - slideNumber: Current slide number
    ///   - totalSlides: Total slides in presentation
    /// - Returns: Complete slide data
    func generateSlideContent(
        keyPoint: KeyPoint,
        audience: Audience,
        slideNumber: Int,
        totalSlides: Int
    ) async throws -> GeneratedSlide {
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.shared.info("Generating slide \(slideNumber)/\(totalSlides)", category: .api)
        
        do {
            // Generate text content
            let slideContent = try await gptService.generateSlideContent(
                keyPoint: keyPoint,
                audience: audience,
                slideNumber: slideNumber,
                totalSlides: totalSlides
            )
            
            // Validate content before generating image
            let validation = try await contentFilter.validateContent(
                slideContent.content,
                audience: audience
            )
            
            if !validation.isApproved {
                Logger.shared.warning("Slide content validation failed", category: .api)
                throw OpenAIError.contentFiltered
            }
            
            // Generate image
            let imageData = try await dalleService.generateImageForAudience(
                prompt: slideContent.imagePrompt,
                audience: audience
            )
            
            Logger.shared.info("Slide \(slideNumber) generated successfully", category: .api)
            
            return GeneratedSlide(
                slideNumber: slideNumber,
                title: slideContent.title,
                content: slideContent.content,
                imageData: imageData,
                imagePrompt: slideContent.imagePrompt
            )
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Slide generation failed", error: error, category: .api)
            throw error
        } catch {
            let mappedError = OpenAIError.unknownError(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
    
    /// Generates multiple slides in batch
    /// - Parameters:
    ///   - keyPoints: Teaching points to create slides for
    ///   - audience: Target audience
    ///   - progressCallback: Optional callback for progress updates (0.0-1.0)
    /// - Returns: Array of generated slides
    func generateSlides(
        keyPoints: [KeyPoint],
        audience: Audience,
        progressCallback: ((Double) -> Void)? = nil
    ) async throws -> [GeneratedSlide] {
        isProcessing = true
        defer { isProcessing = false }
        
        let totalSlides = keyPoints.count
        var generatedSlides: [GeneratedSlide] = []
        
        Logger.shared.info("Generating \(totalSlides) slides for \(audience.rawValue) audience", category: .api)
        
        for (index, keyPoint) in keyPoints.enumerated() {
            let slideNumber = index + 1
            
            do {
                let slide = try await generateSlideContent(
                    keyPoint: keyPoint,
                    audience: audience,
                    slideNumber: slideNumber,
                    totalSlides: totalSlides
                )
                
                generatedSlides.append(slide)
                
                // Update progress
                let progress = Double(slideNumber) / Double(totalSlides)
                progressCallback?(progress)
                
                // Small delay between slides to avoid rate limits
                if slideNumber < totalSlides {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
                
            } catch {
                Logger.shared.error("Failed to generate slide \(slideNumber)", error: error, category: .api)
                throw error
            }
        }
        
        Logger.shared.info("Successfully generated all \(totalSlides) slides", category: .api)
        return generatedSlides
    }
    
    // MARK: - Image Generation
    
    /// Generates image for an existing slide
    /// - Parameters:
    ///   - prompt: Image description
    ///   - audience: Target audience
    /// - Returns: Image data
    func generateImage(prompt: String, audience: Audience) async throws -> Data {
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.shared.info("Generating image: \(prompt.prefix(50))...", category: .api)
        
        do {
            let imageData = try await dalleService.generateImageForAudience(
                prompt: prompt,
                audience: audience
            )
            
            Logger.shared.info("Image generated successfully", category: .api)
            return imageData
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Image generation failed", error: error, category: .api)
            throw error
        } catch {
            let mappedError = OpenAIError.unknownError(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
    
    /// Generates multiple image variations
    /// - Parameters:
    ///   - prompt: Image description
    ///   - count: Number of variations (1-4)
    ///   - audience: Target audience
    /// - Returns: Array of image data
    func generateImageVariations(
        prompt: String,
        count: Int = 2,
        audience: Audience
    ) async throws -> [Data] {
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.shared.info("Generating \(count) image variations", category: .api)
        
        do {
            let images = try await dalleService.generateVariations(
                prompt: prompt,
                count: count,
                audience: audience
            )
            
            Logger.shared.info("Generated \(images.count) variations", category: .api)
            return images
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Image variations generation failed", error: error, category: .api)
            throw error
        } catch {
            let mappedError = OpenAIError.unknownError(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
    
    // MARK: - API Key Validation
    
    /// Validates the API key by making a test request
    /// - Returns: true if key is valid
    func validateAPIKey() async throws -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.shared.info("Validating API key", category: .api)
        
        do {
            // Make a minimal request to test the key
            let request = ChatCompletionRequest(
                model: APIConstants.defaultModel,
                messages: [
                    ChatCompletionRequest.Message(role: .user, content: "Test")
                ],
                temperature: 0.5,
                maxTokens: 10
            )
            
            _ = try await gptService.chatCompletion(request: request)
            
            Logger.shared.info("API key validated successfully", category: .api)
            return true
            
        } catch let error as OpenAIError {
            lastError = error
            
            if case .invalidAPIKey = error {
                Logger.shared.error("Invalid API key", category: .api)
                return false
            }
            
            throw error
        } catch {
            throw OpenAIError.unknownError(error.localizedDescription)
        }
    }
    
    // MARK: - Content Filtering
    
    /// Validates content for appropriateness
    /// - Parameters:
    ///   - content: Content to validate
    ///   - audience: Target audience
    /// - Returns: Validation result
    func validateContent(_ content: String, audience: Audience) async throws -> ContentValidationResult {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            return try await contentFilter.validateContent(content, audience: audience)
        } catch let error as OpenAIError {
            lastError = error
            throw error
        } catch {
            let mappedError = OpenAIError.unknownError(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
}

// MARK: - Generated Slide Type

struct GeneratedSlide {
    let slideNumber: Int
    let title: String
    let content: String
    let imageData: Data
    let imagePrompt: String
}
