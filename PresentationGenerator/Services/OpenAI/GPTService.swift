import Foundation

/// Service for interacting with OpenAI's GPT models
/// Handles chat completions for content analysis and slide generation
actor GPTService {
    private let apiKey: String
    private let maxRetries: Int = 3
    private let baseDelay: TimeInterval = 1.0
    
    // MARK: - Initialization
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    /// Sends a chat completion request to OpenAI
    /// - Parameters:
    ///   - request: The chat completion request with messages and parameters
    /// - Returns: The chat completion response
    /// - Throws: OpenAIError for API failures
    func chatCompletion(request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        return try await withRetry(maxAttempts: maxRetries) {
            try await self.performChatCompletion(request: request)
        }
    }
    
    /// Analyzes document content and extracts key teaching points
    /// - Parameters:
    ///   - content: The document content to analyze
    ///   - audience: Target audience (kids or adults)
    /// - Returns: Structured analysis result with key points
    func analyzeContent(content: String, audience: Audience) async throws -> ContentAnalysisResult {
        let systemPrompt = ContentAnalysisPrompts.systemPrompt(for: audience)
        let userPrompt = ContentAnalysisPrompts.userPrompt(documentContent: content)
        
        let request = ChatCompletionRequest(
            model: APIConstants.defaultModel,
            messages: [
                ChatCompletionRequest.Message(role: .system, content: systemPrompt),
                ChatCompletionRequest.Message(role: .user, content: userPrompt)
            ],
            temperature: APIConstants.defaultTemperature,
            maxTokens: APIConstants.defaultMaxTokens
        )
        
        let response = try await chatCompletion(request: request)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.emptyResponse
        }
        
        return try parseContentAnalysis(content, audience: audience)
    }
    
    /// Generates slide content for a specific key point
    /// - Parameters:
    ///   - keyPoint: The teaching point to create slide for
    ///   - audience: Target audience
    ///   - slideNumber: Current slide number
    ///   - totalSlides: Total number of slides
    /// - Returns: Generated slide content including title, body, and image prompt
    func generateSlideContent(
        keyPoint: KeyPoint,
        audience: Audience,
        slideNumber: Int,
        totalSlides: Int
    ) async throws -> SlideContentResult {
        let systemPrompt = SlideGenerationPrompts.systemPrompt(for: audience)
        let userPrompt = SlideGenerationPrompts.userPrompt(
            keyPoint: keyPoint,
            slideNumber: slideNumber,
            totalSlides: totalSlides
        )
        
        let request = ChatCompletionRequest(
            model: APIConstants.defaultModel,
            messages: [
                ChatCompletionRequest.Message(role: .system, content: systemPrompt),
                ChatCompletionRequest.Message(role: .user, content: userPrompt)
            ],
            temperature: APIConstants.defaultTemperature,
            maxTokens: 500
        )
        
        let response = try await chatCompletion(request: request)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.emptyResponse
        }
        
        return try parseSlideContent(content)
    }
    
    /// Validates content for Catholic appropriateness
    /// - Parameters:
    ///   - content: Content to validate
    ///   - audience: Target audience
    /// - Returns: Validation result with approval status and suggestions
    func validateContent(content: String, audience: Audience) async throws -> ContentValidationResult {
        let systemPrompt = ContentFilterPrompts.systemPrompt(for: audience)
        let userPrompt = ContentFilterPrompts.userPrompt(content: content)
        
        let request = ChatCompletionRequest(
            model: APIConstants.defaultModel,
            messages: [
                ChatCompletionRequest.Message(role: .system, content: systemPrompt),
                ChatCompletionRequest.Message(role: .user, content: userPrompt)
            ],
            temperature: 0.3, // Lower temperature for more consistent validation
            maxTokens: 300
        )
        
        let response = try await chatCompletion(request: request)
        
        guard let content = response.choices.first?.message.content else {
            throw OpenAIError.emptyResponse
        }
        
        return try parseValidationResult(content)
    }
    
    // MARK: - Private Methods
    
    private func performChatCompletion(request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        // Create URL request
        guard let url = URL(string: APIConstants.chatCompletionsEndpoint) else {
            throw OpenAIError.invalidRequest("Invalid API endpoint")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)
        
        // Perform request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        // Check status code
        guard httpResponse.statusCode == 200 else {
            throw handleHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let chatResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
            return chatResponse
        } catch {
            Logger.shared.error("Failed to decode OpenAI response", error: error, category: .api)
            throw OpenAIError.decodingError(error)
        }
    }
    
    private func handleHTTPError(statusCode: Int, data: Data) -> OpenAIError {
        // Try to parse error from response
        if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = errorDict["error"] as? [String: Any],
           let message = error["message"] as? String {
            
            switch statusCode {
            case 401:
                return .invalidAPIKey
            case 429:
                return .rateLimitExceeded
            case 402:
                return .insufficientQuota
            default:
                return .serverError(statusCode)
            }
        }
        
        return .serverError(statusCode)
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
                        "API request failed (attempt \(attempt + 1)/\(maxAttempts)), retrying in \(delay)s",
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
        
        if errorDescription.contains("insufficient") || errorDescription.contains("quota") {
            return .insufficientQuota
        }
        
        if errorDescription.contains("content policy") || errorDescription.contains("filtered") {
            return .contentFiltered
        }
        
        return .unknownError(error.localizedDescription)
    }
    
    // MARK: - Parsing Methods
    
    /// Parses content analysis response into structured data
    private func parseContentAnalysis(_ content: String, audience: Audience) throws -> ContentAnalysisResult {
        // Expected JSON format:
        // {
        //   "keyPoints": [
        //     {"content": "...", "order": 1},
        //     ...
        //   ],
        //   "suggestedSlideCount": 5
        // }
        
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponseFormat("Could not convert response to data")
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ContentAnalysisJSON.self, from: jsonData)
            
            let keyPoints = result.keyPoints.map { point in
                KeyPoint(
                    id: UUID(),
                    content: point.content,
                    order: point.order,
                    isIncluded: true
                )
            }
            
            return ContentAnalysisResult(
                keyPoints: keyPoints,
                suggestedSlideCount: result.suggestedSlideCount
            )
        } catch {
            Logger.shared.error("Failed to parse content analysis", error: error, category: .api)
            throw OpenAIError.invalidResponseFormat("Invalid JSON format: \(error.localizedDescription)")
        }
    }
    
    /// Parses slide content response
    private func parseSlideContent(_ content: String) throws -> SlideContentResult {
        // Expected JSON format:
        // {
        //   "title": "...",
        //   "content": "...",
        //   "imagePrompt": "..."
        // }
        
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponseFormat("Could not convert response to data")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SlideContentResult.self, from: jsonData)
        } catch {
            Logger.shared.error("Failed to parse slide content", error: error, category: .api)
            throw OpenAIError.invalidResponseFormat("Invalid JSON format: \(error.localizedDescription)")
        }
    }
    
    /// Parses content validation response
    private func parseValidationResult(_ content: String) throws -> ContentValidationResult {
        // Expected JSON format:
        // {
        //   "isApproved": true,
        //   "concerns": [],
        //   "suggestions": []
        // }
        
        guard let jsonData = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponseFormat("Could not convert response to data")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ContentValidationResult.self, from: jsonData)
        } catch {
            Logger.shared.error("Failed to parse validation result", error: error, category: .api)
            throw OpenAIError.invalidResponseFormat("Invalid JSON format: \(error.localizedDescription)")
        }
    }
}

// MARK: - Result Types

struct ContentAnalysisResult: Codable {
    let keyPoints: [KeyPoint]
    let suggestedSlideCount: Int
}

struct SlideContentResult: Codable {
    let title: String
    let content: String
    let imagePrompt: String
}

struct ContentValidationResult: Codable {
    let isApproved: Bool
    let concerns: [String]
    let suggestions: [String]
}

// MARK: - Private JSON Structures

private struct ContentAnalysisJSON: Codable {
    struct KeyPointJSON: Codable {
        let content: String
        let order: Int
    }
    
    let keyPoints: [KeyPointJSON]
    let suggestedSlideCount: Int
}
