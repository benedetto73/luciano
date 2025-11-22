import Foundation

/// Main service coordinating OpenAI API interactions
/// Combines GPT and DALL-E services with content filtering
@MainActor
class OpenAIService: OpenAIServiceProtocol, ObservableObject {
    private let gptService: GPTService
    private let dalleService: DALLEService
    private let contentFilter: ContentFilter
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    
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
    ///   - content: Document content to analyze
    ///   - preferredAudience: Optional preferred audience (if nil, AI will suggest)
    /// - Returns: Analysis result with key points and suggested slide count
    func analyzeContent(
        _ content: String,
        preferredAudience: Audience?
    ) async throws -> ContentAnalysisResult {
        isProcessing = true
        defer { isProcessing = false }
        
        let audience = preferredAudience ?? .adults // Default to adults if not specified
        
        Logger.shared.info("Analyzing content for \(audience.rawValue) audience", category: .api)
        
        do {
            // First validate the content is appropriate
            let validation = try await contentFilter.validateContent(content, audience: audience)
            
            if !validation.isApproved {
                Logger.shared.warning("Content validation failed: \(validation.concerns.joined(separator: ", "))", category: .api)
                throw OpenAIError.contentFiltered("Content validation failed")
            }
            
            // Analyze the content
            let result = try await gptService.analyzeContent(content: content, audience: audience)
            
            Logger.shared.info("Analysis complete: \(result.keyPoints.count) key points, \(result.suggestedSlideCount) suggested slides", category: .api)
            
            return result
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Content analysis failed", error: error, category: .api)
            throw error
        } catch {
            let mappedError = OpenAIError.unknown(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
    
    // MARK: - Slide Generation
    
    /// Generates content for a single slide
    /// - Parameters:
    ///   - slideNumber: Current slide number
    ///   - totalSlides: Total slides in presentation
    ///   - mainTheme: Overall theme of the presentation
    ///   - keyPoint: Specific teaching point for this slide
    ///   - audience: Target audience
    /// - Returns: Generated slide content
    func generateSlideContent(
        slideNumber: Int,
        totalSlides: Int,
        mainTheme: String,
        keyPoint: String,
        audience: Audience
    ) async throws -> SlideContentResult {
        isProcessing = true
        defer { isProcessing = false }
        
        Logger.shared.info("Generating slide \(slideNumber)/\(totalSlides)", category: .api)
        
        do {
            // Create KeyPoint model for GPTService
            let keyPointModel = KeyPoint(content: keyPoint, order: slideNumber)
            
            // Generate text content
            let slideContent = try await gptService.generateSlideContent(
                keyPoint: keyPointModel,
                audience: audience,
                slideNumber: slideNumber,
                totalSlides: totalSlides
            )
            
            // Validate content before proceeding
            let validation = try await contentFilter.validateContent(
                slideContent.content,
                audience: audience
            )
            
            if !validation.isApproved {
                Logger.shared.warning("Slide content validation failed", category: .api)
                throw OpenAIError.contentFiltered("Slide content validation failed")
            }
            
            Logger.shared.info("Slide \(slideNumber) content generated successfully", category: .api)
            
            return slideContent
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Slide generation failed", error: error, category: .api)
            throw error
        } catch {
            let mappedError = OpenAIError.unknown(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
    
    /// Generates all slides with progress tracking
    /// - Parameters:
    ///   - analysis: Content analysis result with key points
    ///   - progressCallback: Optional callback for progress updates (current, total)
    /// - Returns: Array of generated slide content
    func generateSlides(
        for analysis: ContentAnalysisResult,
        progressCallback: ((Int, Int) -> Void)?
    ) async throws -> [SlideContentResult] {
        isProcessing = true
        defer { isProcessing = false }
        
        let totalSlides = analysis.keyPoints.count
        var generatedSlides: [SlideContentResult] = []
        
        // Extract main theme from first key point or use a generic theme
        let mainTheme = analysis.keyPoints.first?.content ?? "Catholic Teaching"
        
        Logger.shared.info("Generating \(totalSlides) slides", category: .api)
        
        for (index, keyPoint) in analysis.keyPoints.enumerated() {
            let slideNumber = index + 1
            
            do {
                let slide = try await generateSlideContent(
                    slideNumber: slideNumber,
                    totalSlides: totalSlides,
                    mainTheme: mainTheme,
                    keyPoint: keyPoint.content,
                    audience: .adults // Note: Should come from analysis or project settings
                )
                
                generatedSlides.append(slide)
                
                // Update progress
                progressCallback?(slideNumber, totalSlides)
                
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
    
    /// Generates image for a slide
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
            let mappedError = OpenAIError.unknown(error.localizedDescription)
            lastError = mappedError
            throw mappedError
        }
    }
    
    /// Generates multiple image variations
    /// - Parameters:
    ///   - prompt: Image description
    ///   - audience: Target audience
    ///   - count: Number of variations (1-4)
    /// - Returns: Array of image data
    func generateImageVariations(
        prompt: String,
        audience: Audience,
        count: Int
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
            let mappedError = OpenAIError.unknown(error.localizedDescription)
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
            throw OpenAIError.unknown(error.localizedDescription)
        }
    }
}
