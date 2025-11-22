import Foundation

/// Prompts for content analysis using GPT
enum ContentAnalysisPrompts {
    /// System message for content analysis
    static let systemMessage = """
    You are an expert educational content analyzer specializing in Catholic religious education. \
    Your role is to analyze text documents and extract key teaching points suitable for presentation slides.
    
    Guidelines:
    - Identify the most important teaching points that would work well as individual slides
    - Ensure all content is theologically sound and appropriate for Catholic education
    - Consider the target audience (children or adults) when determining complexity and language
    - Extract 3-20 key points depending on content length and complexity
    - Each key point should be clear, concise, and focused on a single concept
    - Prioritize clarity and educational value
    - Maintain reverence and respect for religious content
    """
    
    /// User message template for content analysis
    static func analysisPrompt(text: String, audience: Audience) -> String {
        """
        Please analyze the following text and extract key teaching points suitable for a presentation.
        
        TARGET AUDIENCE: \(audience.rawValue)
        
        \(audienceGuidelines(for: audience))
        
        TEXT TO ANALYZE:
        \(text)
        
        Please provide your response in the following JSON format:
        {
            "keyPoints": [
                "First key teaching point",
                "Second key teaching point",
                ...
            ],
            "suggestedSlideCount": <number between 3 and 20>,
            "contentSummary": "Brief summary of the main topic"
        }
        
        Ensure each key point is:
        - Clear and focused on one main idea
        - Appropriate for the target audience
        - Suitable for a single presentation slide
        - Theologically accurate for Catholic teaching
        """
    }
    
    /// Additional guidelines based on audience
    private static func audienceGuidelines(for audience: Audience) -> String {
        switch audience {
        case .kids:
            return """
            For CHILDREN:
            - Use simple, age-appropriate language
            - Focus on concrete concepts and stories
            - Keep points shorter and more visual
            - Use engaging, relatable examples
            - Avoid complex theological terminology
            - Emphasize love, kindness, and basic faith concepts
            """
        case .adults:
            return """
            For ADULTS:
            - Use more sophisticated language and concepts
            - Can include deeper theological insights
            - May reference scripture and church teaching
            - Can address complex moral and spiritual topics
            - Maintain intellectual rigor while being accessible
            """
        }
    }
    
    /// Prompt for suggesting optimal slide count
    static func slideCountPrompt(keyPoints: [KeyPoint], audience: Audience) -> String {
        """
        Given these \(keyPoints.count) key points for a \(audience.rawValue.lowercased()) audience, \
        suggest an optimal number of slides (between 3 and 20) that would create an effective presentation.
        
        Key Points:
        \(keyPoints.enumerated().map { "\($0 + 1). \($1.content)" }.joined(separator: "\n"))
        
        Consider:
        - Some points may be combined into single slides
        - Some points may require multiple slides
        - The attention span and engagement level of the audience
        - The need for title and conclusion slides
        
        Respond with just a number.
        """
    }
    
    /// Prompt for refining a key point
    static func refineKeyPointPrompt(keyPoint: String, audience: Audience) -> String {
        """
        Please refine this key teaching point to make it more suitable for a presentation slide \
        targeted at a \(audience.rawValue.lowercased()) audience:
        
        "\(keyPoint)"
        
        Make it:
        - Clear and concise
        - Appropriate for the audience
        - Focused on one main idea
        - Suitable as a slide title or main point
        
        Respond with just the refined key point text.
        """
    }
}
