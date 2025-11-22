//
//  OpenAIServiceProtocol.swift
//  PresentationGenerator
//
//  Protocol defining OpenAI service interface for dependency injection
//

import Foundation

/// Protocol for OpenAI service functionality
/// Implemented by both real OpenAIService and MockOpenAIService
@MainActor
protocol OpenAIServiceProtocol: ObservableObject {
    var isProcessing: Bool { get }
    var lastError: Error? { get }
    
    /// Analyzes document content and extracts teaching points
    func analyzeContent(
        _ content: String,
        preferredAudience: Audience?
    ) async throws -> ContentAnalysisResult
    
    /// Generates content for a single slide
    func generateSlideContent(
        slideNumber: Int,
        totalSlides: Int,
        mainTheme: String,
        keyPoint: String,
        audience: Audience
    ) async throws -> SlideContentResult
    
    /// Generates all slides with progress tracking
    func generateSlides(
        for analysis: ContentAnalysisResult,
        progressCallback: ((Int, Int) -> Void)?
    ) async throws -> [SlideContentResult]
    
    /// Generates an image based on prompt and audience
    func generateImage(
        prompt: String,
        audience: Audience
    ) async throws -> Data
    
    /// Generates multiple image variations
    func generateImageVariations(
        prompt: String,
        audience: Audience,
        count: Int
    ) async throws -> [Data]
    
    /// Validates if the API key is valid
    func validateAPIKey() async throws -> Bool
}
