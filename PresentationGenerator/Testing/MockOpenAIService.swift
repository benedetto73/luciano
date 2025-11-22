//
//  MockOpenAIService.swift
//  PresentationGenerator
//
//  Mock implementation of OpenAIServiceProtocol for testing UI without API calls
//

import Foundation

/// Mock OpenAI service for testing without consuming API quota
@MainActor
final class MockOpenAIService: OpenAIServiceProtocol {
    
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    // MARK: - Configuration
    
    /// Simulated delay for API responses (default: 1 second)
    var simulatedDelay: TimeInterval = 1.0
    
    /// If set, all operations will fail with this error
    var shouldFail: OpenAIError?
    
    /// If true, content filtering will fail
    var shouldFilterContent = false
    
    /// Number of slides to return from generateSlides
    var mockSlideCount: Int = 5
    
    // MARK: - Mock Data
    
    private var mockAnalysisResult: ContentAnalysisResult {
        ContentAnalysisResult(
            keyPoints: [
                KeyPoint(content: "Blessed are the poor in spirit, for theirs is the kingdom of heaven", order: 1),
                KeyPoint(content: "Blessed are those who mourn, for they will be comforted", order: 2),
                KeyPoint(content: "Blessed are the meek, for they will inherit the earth", order: 3),
                KeyPoint(content: "Blessed are those who hunger and thirst for righteousness", order: 4),
                KeyPoint(content: "Blessed are the merciful, for they will be shown mercy", order: 5)
            ],
            suggestedSlideCount: 5
        )
    }
    
    private func mockSlideContent(slideNumber: Int) -> SlideContentResult {
        let titles = [
            "Introduction to the Beatitudes",
            "The Poor in Spirit",
            "Those Who Mourn",
            "The Meek Shall Inherit",
            "Hunger for Righteousness"
        ]
        
        let contents = [
            "Jesus' sermon on true happiness\nThe path to the Kingdom of God\nEight blessings for believers",
            "Recognizing our need for God\nHumility before the Lord\nOpening our hearts to grace",
            "Finding comfort in God's love\nThe gift of compassion\nHealing through faith",
            "Gentleness in a harsh world\nTrusting God's promises\nInheriting God's kingdom",
            "Seeking God's will above all\nLiving according to God's law\nThe fulfillment of justice"
        ]
        
        let prompts = [
            "A peaceful mountain landscape at sunrise with people gathered listening to Jesus teach, inspirational Catholic art style",
            "A person kneeling in prayer with hands clasped, humble posture, warm divine light from above, Catholic religious art",
            "A comforting scene of someone being consoled, gentle light, peaceful atmosphere, Catholic artistic style",
            "A calm pastoral scene with sheep grazing, gentle shepherd, peaceful kingdom imagery, Catholic art",
            "A person reading scripture with holy light illuminating the pages, seeking truth, Catholic religious art"
        ]
        
        let index = min(slideNumber - 1, titles.count - 1)
        
        return SlideContentResult(
            title: titles[index],
            content: contents[index],
            imagePrompt: prompts[index]
        )
    }
    
    private var mockImageData: Data {
        // Create a simple PNG placeholder (1x1 red pixel)
        let png: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
            0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
            0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
            0x44, 0xAE, 0x42, 0x60, 0x82
        ]
        return Data(png)
    }
    
    // MARK: - Initialization
    
    init(
        delay: TimeInterval = 1.0,
        shouldFail: OpenAIError? = nil,
        shouldFilterContent: Bool = false
    ) {
        self.simulatedDelay = delay
        self.shouldFail = shouldFail
        self.shouldFilterContent = shouldFilterContent
    }
    
    // MARK: - OpenAIServiceProtocol Implementation
    
    func analyzeContent(
        _ content: String,
        preferredAudience: Audience?
    ) async throws -> ContentAnalysisResult {
        isProcessing = true
        defer { isProcessing = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Check for forced failure
        if let error = shouldFail {
            lastError = error
            throw error
        }
        
        // Check content filtering
        if shouldFilterContent {
            let error = OpenAIError.contentFiltered("Mock content filter triggered")
            lastError = error
            throw error
        }
        
        // Return mock result
        return mockAnalysisResult
    }
    
    func generateSlideContent(
        slideNumber: Int,
        totalSlides: Int,
        mainTheme: String,
        keyPoint: String,
        audience: Audience
    ) async throws -> SlideContentResult {
        isProcessing = true
        defer { isProcessing = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Check for forced failure
        if let error = shouldFail {
            lastError = error
            throw error
        }
        
        // Check content filtering
        if shouldFilterContent {
            let error = OpenAIError.contentFiltered("Mock content filter triggered")
            lastError = error
            throw error
        }
        
        return mockSlideContent(slideNumber: slideNumber)
    }
    
    func generateSlides(
        for analysis: ContentAnalysisResult,
        progressCallback: ((Int, Int) -> Void)?
    ) async throws -> [SlideContentResult] {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check for forced failure
        if let error = shouldFail {
            lastError = error
            throw error
        }
        
        var slides: [SlideContentResult] = []
        let slideCount = min(mockSlideCount, analysis.keyPoints.count)
        
        for i in 1...slideCount {
            // Simulate progress
            progressCallback?(i, slideCount)
            
            // Simulate per-slide delay
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
            
            // Check content filtering
            if shouldFilterContent && i == 2 {
                let error = OpenAIError.contentFiltered("Mock content filter triggered on slide \(i)")
                lastError = error
                throw error
            }
            
            let keyPoint = i <= analysis.keyPoints.count ? analysis.keyPoints[i - 1].content : "Additional point"
            
            let slide = try await generateSlideContent(
                slideNumber: i,
                totalSlides: slideCount,
                mainTheme: "The Beatitudes",
                keyPoint: keyPoint,
                audience: .adults
            )
            
            slides.append(slide)
        }
        
        return slides
    }
    
    func generateImage(
        prompt: String,
        audience: Audience
    ) async throws -> Data {
        isProcessing = true
        defer { isProcessing = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Check for forced failure
        if let error = shouldFail {
            lastError = error
            throw error
        }
        
        // Check content filtering
        if shouldFilterContent {
            let error = OpenAIError.contentFiltered("Mock image prompt filtered")
            lastError = error
            throw error
        }
        
        return mockImageData
    }
    
    func generateImageVariations(
        prompt: String,
        audience: Audience,
        count: Int
    ) async throws -> [Data] {
        isProcessing = true
        defer { isProcessing = false }
        
        // Simulate network delay (longer for multiple images)
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * Double(count) * 1_000_000_000))
        
        // Check for forced failure
        if let error = shouldFail {
            lastError = error
            throw error
        }
        
        // Check content filtering
        if shouldFilterContent {
            let error = OpenAIError.contentFiltered("Mock image prompt filtered")
            lastError = error
            throw error
        }
        
        // Return array of mock images
        return Array(repeating: mockImageData, count: count)
    }
    
    func validateAPIKey() async throws -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        
        // Check for forced failure
        if let error = shouldFail {
            lastError = error
            throw error
        }
        
        // Mock validation always succeeds unless configured to fail
        return true
    }
}

// MARK: - Convenience Factories

extension MockOpenAIService {
    
    /// Fast mock for rapid UI testing (100ms delay)
    static var fast: MockOpenAIService {
        MockOpenAIService(delay: 0.1)
    }
    
    /// Realistic mock with network delays (2s)
    static var realistic: MockOpenAIService {
        MockOpenAIService(delay: 2.0)
    }
    
    /// Mock that always fails with rate limit error
    static var rateLimited: MockOpenAIService {
        MockOpenAIService(shouldFail: .rateLimitExceeded)
    }
    
    /// Mock that fails content filtering
    static var filtered: MockOpenAIService {
        MockOpenAIService(shouldFilterContent: true)
    }
    
    /// Mock with authentication failure
    static var unauthorized: MockOpenAIService {
        MockOpenAIService(shouldFail: .invalidAPIKey)
    }
    
    /// Mock with network error
    static var networkError: MockOpenAIService {
        MockOpenAIService(shouldFail: .networkError(NSError(domain: "MockNetwork", code: -1009)))
    }
}
