import Foundation

/// Prompts for slide generation using GPT
enum SlideGenerationPrompts {
    /// System message for slide generation
    static let systemMessage = """
    You are an expert presentation designer specializing in Catholic educational content. \
    Your role is to create engaging, visually appealing presentation slides that effectively \
    communicate religious and educational concepts.
    
    Guidelines:
    - Create clear, visually balanced slide designs
    - Ensure content is theologically accurate and appropriate
    - Match design complexity to the target audience
    - Use language and imagery suitable for the audience age group
    - Maintain reverence and respect for religious content
    - Create engaging but not distracting designs
    - Follow best practices for presentation design
    """
    
    /// User message template for generating slide content
    static func generateSlidePrompt(
        keyPoint: KeyPoint,
        audience: Audience,
        slideNumber: Int,
        totalSlides: Int
    ) -> String {
        """
        Create content for slide \(slideNumber) of \(totalSlides) in a presentation.
        
        TARGET AUDIENCE: \(audience.rawValue)
        
        KEY POINT TO PRESENT:
        \(keyPoint.content)
        
        \(audienceDesignGuidelines(for: audience))
        
        Please provide your response in the following JSON format:
        {
            "title": "Concise, engaging slide title",
            "content": "Main content text (2-5 bullet points or 1-2 paragraphs)",
            "imagePrompt": "Detailed description for generating an appropriate image",
            "designSpec": {
                "layout": "titleContentAndImage",
                "backgroundColor": "#HEXCOLOR",
                "textColor": "#HEXCOLOR",
                "fontSize": "medium|large|extraLarge",
                "imagePosition": "right|left|top|bottom"
            },
            "speakerNotes": "Additional notes for the presenter"
        }
        
        Layout options: titleOnly, titleAndContent, titleContentAndImage, imageOnly, splitView, fullImage
        
        Ensure:
        - Title is clear and engaging (max 60 characters)
        - Content is well-structured and not overcrowded
        - Image prompt will generate appropriate, respectful imagery
        - Design is visually appealing and age-appropriate
        - Colors are harmonious and readable
        """
    }
    
    /// Audience-specific design guidelines
    private static func audienceDesignGuidelines(for audience: Audience) -> String {
        switch audience {
        case .kids:
            return """
            DESIGN FOR CHILDREN:
            - Use bright, cheerful colors (yellows, light blues, soft reds)
            - Large, easy-to-read text (minimum 24pt)
            - Simple, cartoon-style or friendly imagery
            - Playful but not chaotic layouts
            - Limit text to 3-4 short bullet points maximum
            - Use simple, fun fonts
            - Include engaging visual elements
            """
        case .adults:
            return """
            DESIGN FOR ADULTS:
            - Use professional, sophisticated colors (blues, grays, earth tones)
            - Clear, readable text (18-24pt)
            - Realistic, reverent imagery
            - Clean, organized layouts
            - Can include more detailed content (5-7 points maximum)
            - Use classic, professional fonts
            - Balance professionalism with engagement
            """
        }
    }
    
    /// Prompt for generating image description
    static func imagePrompt(
        slideTitle: String,
        slideContent: String,
        audience: Audience
    ) -> String {
        """
        Create a detailed image prompt for DALL-E to generate an appropriate image for this slide.
        
        SLIDE TITLE: \(slideTitle)
        SLIDE CONTENT: \(slideContent)
        TARGET AUDIENCE: \(audience.rawValue)
        
        \(imageStyleGuidelines(for: audience))
        
        Create a prompt that will generate:
        - An image that illustrates the slide's main concept
        - Appropriate style for the audience (\(audience == .kids ? "cartoon, playful" : "realistic, reverent"))
        - Respectful representation of religious themes
        - Clear, high-quality composition
        - No text in the image
        
        Respond with just the DALL-E prompt text (max 400 characters).
        """
    }
    
    /// Image style guidelines based on audience
    private static func imageStyleGuidelines(for audience: Audience) -> String {
        switch audience {
        case .kids:
            return """
            IMAGE STYLE FOR CHILDREN:
            - Cartoon or illustrated style
            - Bright, cheerful colors
            - Friendly, approachable characters
            - Simple, clear compositions
            - Playful but respectful
            - Age-appropriate depictions
            """
        case .adults:
            return """
            IMAGE STYLE FOR ADULTS:
            - Realistic or artistic style
            - Sophisticated color palette
            - Reverent, contemplative mood
            - Professional composition
            - Appropriate gravitas for religious content
            - Can include symbolic or abstract elements
            """
        }
    }
    
    /// Prompt for refining slide content
    static func refineSlidePrompt(
        currentContent: String,
        feedback: String,
        audience: Audience
    ) -> String {
        """
        Please refine this slide content based on the following feedback.
        
        TARGET AUDIENCE: \(audience.rawValue)
        
        CURRENT CONTENT:
        \(currentContent)
        
        FEEDBACK:
        \(feedback)
        
        Provide improved content in the same JSON format, maintaining appropriateness for the audience.
        """
    }
    
    /// Prompt for generating speaker notes
    static func speakerNotesPrompt(
        slideTitle: String,
        slideContent: String,
        keyPoint: KeyPoint,
        audience: Audience
    ) -> String {
        """
        Create helpful speaker notes for a presenter delivering this slide.
        
        SLIDE TITLE: \(slideTitle)
        SLIDE CONTENT: \(slideContent)
        KEY TEACHING POINT: \(keyPoint.content)
        TARGET AUDIENCE: \(audience.rawValue)
        
        Include:
        - Key points to emphasize
        - Examples or stories to share
        - Potential questions to ask the audience
        - Transition to next slide
        - Estimated time to spend on this slide (1-3 minutes)
        
        Keep notes concise but helpful (100-200 words).
        """
    }
}
