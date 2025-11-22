import Foundation

/// Content filtering rules and prompts for ensuring appropriate content
enum ContentFilterPrompts {
    /// System message for content filtering
    static let systemMessage = """
    You are a content moderator specializing in Catholic educational materials. \
    Your role is to ensure all content is appropriate, theologically sound, and \
    suitable for the intended audience.
    
    Evaluation Criteria:
    1. Theological Accuracy: Content aligns with Catholic teaching
    2. Age Appropriateness: Content is suitable for the target audience
    3. Respectfulness: Content treats religious themes with proper reverence
    4. Educational Value: Content serves a clear educational purpose
    5. Safety: Content is free from harmful or inappropriate material
    """
    
    /// Validation rules for Catholic educational content
    static let validationRules = """
    ACCEPTABLE CONTENT:
    - Biblical stories and teachings
    - Lives of saints and holy figures
    - Catholic prayers and devotions
    - Moral and ethical teachings
    - Liturgical and sacramental instruction
    - Church history and tradition
    - Virtues and character development
    - Age-appropriate theological concepts
    
    CONTENT TO AVOID:
    - Theological errors or heresies
    - Disrespectful treatment of sacred subjects
    - Content that could cause fear or anxiety (especially for children)
    - Overly complex concepts for young audiences
    - Culturally insensitive material
    - Political or divisive topics unrelated to faith
    - Any violent or disturbing imagery
    - Content that undermines Catholic teaching
    """
    
    /// Prompt for validating generated content
    static func validateContentPrompt(
        content: String,
        contentType: ContentType,
        audience: Audience
    ) -> String {
        """
        Please evaluate the following \(contentType.rawValue) for appropriateness in a Catholic \
        educational presentation for \(audience.rawValue.lowercased()).
        
        CONTENT TO EVALUATE:
        \(content)
        
        \(validationRules)
        
        Provide your response in JSON format:
        {
            "isApproved": true/false,
            "concerns": ["list", "of", "any", "concerns"],
            "suggestions": ["list", "of", "improvements"],
            "severity": "none|minor|moderate|major"
        }
        
        Severity levels:
        - none: No issues, content is appropriate
        - minor: Small improvements recommended but content is acceptable
        - moderate: Content needs revision before use
        - major: Content is inappropriate and should not be used
        """
    }
    
    /// Prompt for validating image descriptions
    static func validateImagePrompt(
        imageDescription: String,
        slideContext: String,
        audience: Audience
    ) -> String {
        """
        Evaluate this image description for appropriateness in a Catholic educational context.
        
        IMAGE DESCRIPTION:
        \(imageDescription)
        
        SLIDE CONTEXT:
        \(slideContext)
        
        TARGET AUDIENCE: \(audience.rawValue)
        
        Check for:
        - Respectful representation of religious themes
        - Age-appropriate imagery
        - Cultural sensitivity
        - Avoidance of potentially disturbing content
        - Theological accuracy in visual representation
        
        Respond in JSON:
        {
            "isApproved": true/false,
            "concerns": ["list of concerns"],
            "alternativeDescription": "improved description if needed"
        }
        """
    }
    
    /// Age-specific content guidelines
    static func ageAppropriatenessCheck(content: String, audience: Audience) -> String {
        let guidelines = audience == .kids ? kidsGuidelines : adultsGuidelines
        
        return """
        Check if this content is age-appropriate for \(audience.rawValue.lowercased()):
        
        CONTENT:
        \(content)
        
        GUIDELINES:
        \(guidelines)
        
        Respond with:
        {
            "isAgeAppropriate": true/false,
            "reason": "explanation",
            "ageAdjustment": "how to modify for appropriate age level if needed"
        }
        """
    }
    
    private static let kidsGuidelines = """
    FOR CHILDREN:
    ✓ Simple language and concepts
    ✓ Positive, encouraging messages
    ✓ Stories with clear moral lessons
    ✓ Concrete, relatable examples
    ✓ Age-appropriate explanations of faith
    
    ✗ Complex theological debates
    ✗ Graphic descriptions of suffering
    ✗ Themes of hell or damnation
    ✗ Abstract philosophical concepts
    ✗ Content that could cause nightmares or anxiety
    """
    
    private static let adultsGuidelines = """
    FOR ADULTS:
    ✓ Deeper theological exploration
    ✓ Complex moral reasoning
    ✓ Historical and doctrinal details
    ✓ Challenging spiritual concepts
    ✓ Mature discussion of faith and doubt
    
    ✗ Content that is condescending
    ✗ Oversimplification of important concepts
    ✗ Dismissal of genuine questions
    ✗ Extremist or fringe interpretations
    ✗ Content that divides rather than unifies
    """
    
    /// Prompt for checking theological accuracy
    static func theologicalAccuracyCheck(content: String) -> String {
        """
        Verify the theological accuracy of this content according to Catholic teaching.
        
        CONTENT:
        \(content)
        
        Check against:
        - Sacred Scripture
        - Catechism of the Catholic Church
        - Magisterial teaching
        - Sacred Tradition
        
        Respond with:
        {
            "isTheologicallySound": true/false,
            "issues": ["any doctrinal concerns"],
            "corrections": ["suggested corrections if needed"],
            "references": ["relevant Catechism paragraphs or scripture"]
        }
        """
    }
    
    enum ContentType: String {
        case slideTitle = "slide title"
        case slideContent = "slide content"
        case imageDescription = "image description"
        case keyPoint = "key teaching point"
        case speakerNotes = "speaker notes"
    }
}
