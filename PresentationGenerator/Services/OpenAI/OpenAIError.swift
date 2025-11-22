import Foundation

/// OpenAI-specific errors
enum OpenAIError: LocalizedError {
    case invalidAPIKey
    case rateLimitExceeded
    case insufficientQuota
    case invalidRequest(String)
    case modelNotAvailable(String)
    case contentFiltered(String)
    case serverError(Int)
    case timeout
    case networkError(Error)
    case invalidResponse
    case invalidResponseFormat(String) // Added for JSON parsing failures
    case emptyResponse // Added for missing content
    case decodingError(Error)
    case imageGenerationFailed(String)
    case imageProcessingError(String) // Added for image processing
    case textGenerationFailed(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid OpenAI API key"
        case .rateLimitExceeded:
            return "OpenAI rate limit exceeded"
        case .insufficientQuota:
            return "Insufficient OpenAI quota or credits"
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .modelNotAvailable(let model):
            return "Model '\(model)' is not available"
        case .contentFiltered(let reason):
            return reason.isEmpty ? "Content was filtered by OpenAI" : "Content was filtered: \(reason)"
        case .serverError(let code):
            return "OpenAI server error (code: \(code))"
        case .timeout:
            return "Request timed out"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .invalidResponseFormat(let message):
            return "Invalid response format: \(message)"
        case .emptyResponse:
            return "OpenAI returned an empty response"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .imageGenerationFailed(let reason):
            return "Image generation failed: \(reason)"
        case .imageProcessingError(let reason):
            return "Image processing error: \(reason)"
        case .textGenerationFailed(let reason):
            return "Text generation failed: \(reason)"
        case .unknown(let message):
            return "Unknown OpenAI error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAPIKey:
            return "Please check your API key in Settings and ensure it's correct."
        case .rateLimitExceeded:
            return "Please wait a moment before trying again. Consider upgrading your OpenAI plan for higher limits."
        case .insufficientQuota:
            return "Please check your OpenAI account balance and add credits if needed."
        case .invalidRequest:
            return "Check the request parameters and try again."
        case .modelNotAvailable:
            return "Try using a different model or check your OpenAI account access."
        case .contentFiltered:
            return "Modify the content to comply with OpenAI's content policy."
        case .serverError:
            return "This is a temporary server issue. Please try again in a few moments."
        case .timeout:
            return "The request took too long. Please try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .invalidResponse, .invalidResponseFormat, .emptyResponse, .decodingError:
            return "This might be a temporary issue. Please try again."
        case .imageGenerationFailed, .imageProcessingError, .textGenerationFailed:
            return "Try regenerating with a different prompt or parameters."
        case .unknown:
            return "Please try again or contact support if the issue persists."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidAPIKey:
            return "The API key was rejected by OpenAI"
        case .rateLimitExceeded:
            return "Too many requests in a short period"
        case .insufficientQuota:
            return "Your OpenAI account has insufficient credits"
        case .invalidRequest:
            return "The request format or parameters are invalid"
        case .modelNotAvailable:
            return "The requested AI model is not accessible"
        case .contentFiltered:
            return "OpenAI's content filter blocked the request"
        case .serverError:
            return "OpenAI's servers encountered an error"
        case .timeout:
            return "The request exceeded the time limit"
        case .networkError:
            return "Unable to reach OpenAI's servers"
        case .invalidResponse, .invalidResponseFormat, .emptyResponse:
            return "The server response was malformed"
        case .decodingError:
            return "Unable to parse the server response"
        case .imageGenerationFailed, .imageProcessingError:
            return "DALL-E could not generate the requested image"
        case .textGenerationFailed:
            return "GPT could not generate the requested text"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
    
    /// HTTP status code if applicable
    var statusCode: Int? {
        if case .serverError(let code) = self {
            return code
        }
        return nil
    }
    
    /// Whether this error is retryable
    var isRetryable: Bool {
        switch self {
        case .rateLimitExceeded, .timeout, .serverError, .networkError:
            return true
        case .invalidAPIKey, .insufficientQuota, .contentFiltered:
            return false
        default:
            return false
        }
    }
}
