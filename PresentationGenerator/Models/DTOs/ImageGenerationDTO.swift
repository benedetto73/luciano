import Foundation

// MARK: - DALL-E Image Generation Request

struct ImageGenerationRequest: Codable {
    let model: String
    let prompt: String
    let n: Int?
    let size: String?
    let quality: String?
    let style: String?
    let responseFormat: String?
    
    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case n
        case size
        case quality
        case style
        case responseFormat = "response_format"
    }
    
    init(
        model: String = APIConstants.Model.defaultImageModel,
        prompt: String,
        n: Int? = APIConstants.Parameters.defaultNumImages,
        size: String? = APIConstants.Parameters.defaultImageSize,
        quality: String? = APIConstants.Parameters.defaultImageQuality,
        style: String? = APIConstants.Parameters.defaultImageStyle
    ) {
        self.model = model
        self.prompt = prompt
        self.n = n
        self.size = size
        self.quality = quality
        self.style = style
        self.responseFormat = "url" // We'll download the image
    }
}

// MARK: - DALL-E Image Generation Response

struct ImageGenerationResponse: Codable {
    let created: Int
    let data: [GeneratedImage]
    
    struct GeneratedImage: Codable {
        let url: String?
        let b64Json: String?
        let revisedPrompt: String?
        
        enum CodingKeys: String, CodingKey {
            case url
            case b64Json = "b64_json"
            case revisedPrompt = "revised_prompt"
        }
    }
    
    var imageURL: String? {
        data.first?.url
    }
    
    var revisedPrompt: String? {
        data.first?.revisedPrompt
    }
}
