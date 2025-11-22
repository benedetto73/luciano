import Foundation

/// OpenAI API constants
enum APIConstants {
    // MARK: - API Endpoints
    static let baseURL = "https://api.openai.com/v1"
    static let chatCompletionsEndpoint = "\(baseURL)/chat/completions"
    static let imagesGenerationsEndpoint = "\(baseURL)/images/generations"
    static let modelsEndpoint = "\(baseURL)/models"
    
    // MARK: - Model Names
    enum Model {
        // GPT Models
        static let gpt4 = "gpt-4"
        static let gpt4Turbo = "gpt-4-turbo-preview"
        static let gpt35Turbo = "gpt-3.5-turbo"
        
        // DALL-E Models
        static let dalle3 = "dall-e-3"
        static let dalle2 = "dall-e-2"
        
        // Default models to use
        static let defaultTextModel = gpt4Turbo
        static let defaultImageModel = dalle3
    }
    
    // Legacy top-level constants for backward compatibility
    static let defaultModel = Model.defaultTextModel
    static let defaultTemperature = Parameters.defaultTemperature
    static let defaultMaxTokens = Parameters.defaultMaxTokens
    
    // MARK: - Request Parameters
    enum Parameters {
        // Text generation
        static let defaultTemperature: Double = 0.7
        static let defaultMaxTokens = 2000
        static let defaultTopP: Double = 1.0
        static let defaultPresencePenalty: Double = 0.0
        static let defaultFrequencyPenalty: Double = 0.0
        
        // Image generation
        static let defaultImageSize = "1024x1024"
        static let defaultImageQuality = "standard" // or "hd" for DALL-E 3
        static let defaultImageStyle = "natural" // or "vivid" for DALL-E 3
        static let defaultNumImages = 1
    }
    
    // MARK: - Rate Limiting
    static let maxRetries = 3
    static let retryDelay: TimeInterval = 2.0
    static let rateLimitDelay: TimeInterval = 60.0
    
    // MARK: - Headers
    enum Headers {
        static let authorization = "Authorization"
        static let contentType = "Content-Type"
        static let contentTypeJSON = "application/json"
    }
    
    // MARK: - Timeouts
    static let requestTimeout: TimeInterval = 30.0
    static let imageRequestTimeout: TimeInterval = 60.0
    static let longRequestTimeout: TimeInterval = 120.0
    
    // MARK: - Token Limits
    enum TokenLimits {
        static let gpt4 = 8192
        static let gpt4Turbo = 128000
        static let gpt35Turbo = 4096
    }
    
    // MARK: - Keychain
    static let keychainService = "com.catholic.presentationgenerator.openai"
    static let keychainAccount = "openai-api-key"
    
    // MARK: - Error Messages
    enum ErrorMessages {
        static let invalidAPIKey = "Invalid API key provided"
        static let rateLimitExceeded = "Rate limit exceeded"
        static let insufficientQuota = "Insufficient quota"
        static let serverError = "OpenAI server error"
        static let networkError = "Network connection error"
    }
}
