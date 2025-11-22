import Foundation

/// Content filtering service for Catholic educational appropriateness
/// Validates content against theological accuracy and age-appropriateness
actor ContentFilter {
    private let gptService: GPTService
    
    init(gptService: GPTService) {
        self.gptService = gptService
    }
    
    /// Validates content for Catholic appropriateness and age-suitability
    /// - Parameters:
    ///   - content: Content to validate
    ///   - audience: Target audience (affects standards)
    /// - Returns: Validation result with approval status and feedback
    func validateContent(_ content: String, audience: Audience) async throws -> ContentValidationResult {
        Logger.shared.info("Validating content for \(audience.rawValue) audience", category: .api)
        
        do {
            let result = try await gptService.validateContent(content: content, audience: audience)
            
            if result.isApproved {
                Logger.shared.info("Content validated successfully", category: .api)
            } else {
                Logger.shared.warning("Content validation failed: \(result.concerns.joined(separator: ", "))", category: .api)
            }
            
            return result
            
        } catch {
            Logger.shared.error("Content validation error", error: error, category: .api)
            throw error
        }
    }
    
    /// Performs quick validation of multiple content items
    /// - Parameters:
    ///   - contents: Array of content strings to validate
    ///   - audience: Target audience
    /// - Returns: Array of validation results in same order
    func validateBatch(_ contents: [String], audience: Audience) async throws -> [ContentValidationResult] {
        Logger.shared.info("Batch validating \(contents.count) items", category: .api)
        
        var results: [ContentValidationResult] = []
        
        for content in contents {
            let result = try await validateContent(content, audience: audience)
            results.append(result)
            
            // Small delay to avoid rate limits
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        let approvedCount = results.filter { $0.isApproved }.count
        Logger.shared.info("Batch validation complete: \(approvedCount)/\(contents.count) approved", category: .api)
        
        return results
    }
    
    /// Checks if a prompt is safe for image generation
    /// - Parameter prompt: Image generation prompt
    /// - Returns: true if safe, false if potentially problematic
    func validateImagePrompt(_ prompt: String) async throws -> Bool {
        // Quick check for obviously problematic content
        let lowercasePrompt = prompt.lowercased()
        let prohibitedTerms = ["violence", "blood", "weapon", "death", "nude", "explicit"]
        
        for term in prohibitedTerms {
            if lowercasePrompt.contains(term) {
                Logger.shared.warning("Image prompt contains prohibited term: \(term)", category: .api)
                return false
            }
        }
        
        // For more nuanced validation, use GPT
        let validation = try await validateContent(prompt, audience: .kids) // Use stricter kids standard
        return validation.isApproved
    }
    
    /// Suggests improvements for rejected content
    /// - Parameters:
    ///   - content: Original content that failed validation
    ///   - concerns: List of concerns from validation
    ///   - audience: Target audience
    /// - Returns: Suggested improved version of content
    func suggestImprovement(
        content: String,
        concerns: [String],
        audience: Audience
    ) async throws -> String {
        let systemPrompt = """
        You are a Catholic educational content editor. Your task is to improve content that has been flagged as inappropriate or concerning.
        
        Audience: \(audience.rawValue)
        
        Original concerns:
        \(concerns.joined(separator: "\n"))
        
        Provide an improved version that:
        1. Addresses all the concerns
        2. Maintains the core educational message
        3. Is appropriate for the target audience
        4. Follows Catholic teaching
        5. Uses clear, engaging language
        
        Return ONLY the improved content, no explanations.
        """
        
        let request = ChatCompletionRequest(
            model: APIConstants.defaultModel,
            messages: [
                ChatCompletionRequest.Message(role: .system, content: systemPrompt),
                ChatCompletionRequest.Message(role: .user, content: content)
            ],
            temperature: 0.7,
            maxTokens: 500
        )
        
        let response = try await gptService.chatCompletion(request: request)
        
        guard let improvedContent = response.choices.first?.message.content else {
            throw OpenAIError.emptyResponse
        }
        
        Logger.shared.info("Generated improved content", category: .api)
        return improvedContent
    }
}
