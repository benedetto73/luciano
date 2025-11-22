//
//  ContentAnalyzer.swift
//  PresentationGenerator
//
//  Analyzes source documents and extracts teaching points
//

import Foundation

/// Service for analyzing content and preparing it for slide generation
@MainActor
class ContentAnalyzer: ObservableObject {
    private let openAIService: any OpenAIServiceProtocol
    private let fileRepository: FileRepositoryProtocol
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var lastError: Error?
    
    // MARK: - Initialization
    
    init(openAIService: any OpenAIServiceProtocol, fileRepository: FileRepositoryProtocol) {
        self.openAIService = openAIService
        self.fileRepository = fileRepository
    }
    
    // MARK: - Analysis
    
    /// Analyzes a source file and extracts teaching points
    /// - Parameters:
    ///   - sourceFile: The file to analyze
    ///   - preferredAudience: Optional audience preference
    /// - Returns: Analysis result with key points and suggested slide count
    func analyze(
        sourceFile: SourceFile,
        preferredAudience: Audience? = nil
    ) async throws -> ContentAnalysisResult {
        isAnalyzing = true
        analysisProgress = 0.0
        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }
        
        Logger.shared.info("Starting content analysis for: \(sourceFile.filename)", category: .business)
        
        do {
            // Step 1: Get content from source file (20%)
            analysisProgress = 0.1
            let content = sourceFile.content
            analysisProgress = 0.2
            
            // Validate content length
            guard !content.isEmpty else {
                throw AppError.insufficientContent
            }
            
            Logger.shared.info("Document imported, \(content.count) characters", category: .business)
            
            // Step 2: Analyze with OpenAI (20% -> 80%)
            analysisProgress = 0.3
            let result = try await openAIService.analyzeContent(
                content,
                preferredAudience: preferredAudience
            )
            analysisProgress = 0.9
            
            Logger.shared.info("Analysis complete: \(result.keyPoints.count) key points", category: .business)
            
            // Step 3: Validate results
            validateAnalysisResult(result)
            analysisProgress = 1.0
            
            return result
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Analysis failed", error: error, category: .business)
            throw error
        } catch let error as AppError {
            lastError = error
            Logger.shared.error("Analysis failed", error: error, category: .business)
            throw error
        } catch {
            let appError = AppError.unknown(error.localizedDescription)
            lastError = appError
            Logger.shared.error("Analysis failed with unknown error", error: error, category: .business)
            throw appError
        }
    }
    
    /// Analyzes content directly from text (useful for testing)
    /// - Parameters:
    ///   - text: Content to analyze
    ///   - preferredAudience: Optional audience preference
    /// - Returns: Analysis result
    func analyzeText(
        _ text: String,
        preferredAudience: Audience? = nil
    ) async throws -> ContentAnalysisResult {
        isAnalyzing = true
        analysisProgress = 0.0
        defer {
            isAnalyzing = false
            analysisProgress = 1.0
        }
        
        Logger.shared.info("Starting text analysis, \(text.count) characters", category: .business)
        
        do {
            guard !text.isEmpty else {
                throw AppError.insufficientContent
            }
            
            analysisProgress = 0.3
            let result = try await openAIService.analyzeContent(
                text,
                preferredAudience: preferredAudience
            )
            analysisProgress = 0.9
            
            validateAnalysisResult(result)
            analysisProgress = 1.0
            
            Logger.shared.info("Text analysis complete: \(result.keyPoints.count) key points", category: .business)
            
            return result
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Text analysis failed", error: error, category: .business)
            throw error
        } catch let error as AppError {
            lastError = error
            Logger.shared.error("Text analysis failed", error: error, category: .business)
            throw error
        } catch {
            let appError = AppError.unknown(error.localizedDescription)
            lastError = appError
            throw appError
        }
    }
    
    /// Re-analyzes content with different audience
    /// - Parameters:
    ///   - sourceFile: The file to re-analyze
    ///   - newAudience: New target audience
    /// - Returns: Updated analysis result
    func reanalyze(
        sourceFile: SourceFile,
        for newAudience: Audience
    ) async throws -> ContentAnalysisResult {
        Logger.shared.info("Re-analyzing for \(newAudience.rawValue) audience", category: .business)
        return try await analyze(sourceFile: sourceFile, preferredAudience: newAudience)
    }
    
    // MARK: - Private Helpers
    
    // Helper removed - SourceFile already contains content
    
    private func validateAnalysisResult(_ result: ContentAnalysisResult) {
        // Ensure we have at least one key point
        guard !result.keyPoints.isEmpty else {
            Logger.shared.warning("Analysis returned no key points", category: .business)
            return
        }
        
        // Warn if slide count seems unreasonable
        if result.suggestedSlideCount > 50 {
            Logger.shared.warning("Suggested slide count is very high: \(result.suggestedSlideCount)", category: .business)
        } else if result.suggestedSlideCount < 3 {
            Logger.shared.warning("Suggested slide count is very low: \(result.suggestedSlideCount)", category: .business)
        }
        
        // Ensure key points match suggested slide count
        if result.keyPoints.count != result.suggestedSlideCount {
            Logger.shared.info("Key points (\(result.keyPoints.count)) differs from suggested slides (\(result.suggestedSlideCount))", category: .business)
        }
    }
}

// MARK: - Analysis Statistics

extension ContentAnalyzer {
    /// Provides statistics about analyzed content
    struct AnalysisStatistics {
        let keyPointCount: Int
        let suggestedSlideCount: Int
        let averagePointLength: Int
        let totalContentLength: Int
        
        init(result: ContentAnalysisResult) {
            self.keyPointCount = result.keyPoints.count
            self.suggestedSlideCount = result.suggestedSlideCount
            
            let totalLength = result.keyPoints.reduce(0) { $0 + $1.content.count }
            self.totalContentLength = totalLength
            self.averagePointLength = keyPointCount > 0 ? totalLength / keyPointCount : 0
        }
        
        var isValid: Bool {
            keyPointCount > 0 && suggestedSlideCount > 0
        }
        
        var needsReview: Bool {
            suggestedSlideCount > 30 || suggestedSlideCount < 3
        }
    }
    
    /// Gets statistics for an analysis result
    func statistics(for result: ContentAnalysisResult) -> AnalysisStatistics {
        AnalysisStatistics(result: result)
    }
}
