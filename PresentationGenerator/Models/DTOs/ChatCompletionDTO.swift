import Foundation

// MARK: - Chat Completion Request

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double?
    let maxTokens: Int?
    let topP: Double?
    let presencePenalty: Double?
    let frequencyPenalty: Double?
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case topP = "top_p"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
    }
    
    struct Message: Codable {
        let role: Role
        let content: String
        
        enum Role: String, Codable {
            case system
            case user
            case assistant
        }
    }
    
    init(
        model: String = APIConstants.Model.defaultTextModel,
        messages: [Message],
        temperature: Double? = APIConstants.Parameters.defaultTemperature,
        maxTokens: Int? = APIConstants.Parameters.defaultMaxTokens,
        topP: Double? = APIConstants.Parameters.defaultTopP,
        presencePenalty: Double? = APIConstants.Parameters.defaultPresencePenalty,
        frequencyPenalty: Double? = APIConstants.Parameters.defaultFrequencyPenalty
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
    }
}

// MARK: - Chat Completion Response

struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    var text: String? {
        choices.first?.message.content
    }
}
