//
//  ContentAnalyzerTests.swift
//  PresentationGeneratorTests
//
//  Unit tests for ContentAnalyzer service
//

import XCTest
@testable import PresentationGenerator

@MainActor
final class ContentAnalyzerTests: XCTestCase {
    var sut: ContentAnalyzer!
    var mockOpenAIService: MockOpenAIService!
    var mockFileRepository: MockFileRepository!
    
    override func setUp() async throws {
        mockOpenAIService = MockOpenAIService()
        mockFileRepository = MockFileRepository()
        
        sut = ContentAnalyzer(
            openAIService: mockOpenAIService,
            fileRepository: mockFileRepository
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockOpenAIService = nil
        mockFileRepository = nil
    }
    
    // MARK: - Analyze Source File Tests
    
    func testAnalyze_WithValidSourceFile_ReturnsAnalysisResult() async throws {
        // Given
        let content = "The Beatitudes are Jesus' teachings on true happiness and the path to the Kingdom of God."
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: content,
            importedDate: Date()
        )
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let result = try await sut.analyze(sourceFile: sourceFile)
        
        // Then
        XCTAssertFalse(result.keyPoints.isEmpty, "Should return key points")
        XCTAssertGreaterThan(result.suggestedSlideCount, 0, "Should suggest slides")
        XCTAssertFalse(sut.isAnalyzing, "Should finish analyzing")
        XCTAssertEqual(sut.analysisProgress, 1.0, "Progress should be complete")
    }
    
    func testAnalyze_WithPreferredAudience_PassesAudienceToService() async throws {
        // Given
        let content = "Educational content about the Ten Commandments."
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: content,
            importedDate: Date()
        )
        let audience = Audience.kids
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let result = try await sut.analyze(sourceFile: sourceFile, preferredAudience: audience)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertFalse(result.keyPoints.isEmpty)
    }
    
    func testAnalyze_WithEmptyContent_ThrowsInsufficientContentError() async {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "empty.txt",
            fileType: .txt,
            content: "",
            importedDate: Date()
        )
        
        // When/Then
        do {
            _ = try await sut.analyze(sourceFile: sourceFile)
            XCTFail("Should throw insufficient content error")
        } catch let error as AppError {
            XCTAssertEqual(error, .insufficientContent)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testAnalyze_WhenServiceFails_ThrowsOpenAIError() async {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: "Some content",
            importedDate: Date()
        )
        let expectedError = OpenAIError.apiError("Test error")
        mockOpenAIService.shouldFail = expectedError
        
        // When/Then
        do {
            _ = try await sut.analyze(sourceFile: sourceFile)
            XCTFail("Should throw OpenAI error")
        } catch let error as OpenAIError {
            XCTAssertNotNil(error)
            XCTAssertNotNil(sut.lastError, "Should store last error")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testAnalyze_UpdatesProgressDuringAnalysis() async throws {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: "Test content for progress tracking",
            importedDate: Date()
        )
        mockOpenAIService.simulatedDelay = 0.2
        
        var progressValues: [Double] = []
        
        // When
        Task {
            // Sample progress during analysis
            for _ in 0..<5 {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                progressValues.append(sut.analysisProgress)
            }
        }
        
        _ = try await sut.analyze(sourceFile: sourceFile)
        
        // Then
        XCTAssertTrue(progressValues.contains { $0 > 0 && $0 < 1.0 }, "Progress should update during analysis")
        XCTAssertEqual(sut.analysisProgress, 1.0, "Final progress should be 1.0")
    }
    
    func testAnalyze_SetsIsAnalyzingFlag() async throws {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: "Test content",
            importedDate: Date()
        )
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        XCTAssertFalse(sut.isAnalyzing, "Should start false")
        
        let analysisTask = Task {
            try await sut.analyze(sourceFile: sourceFile)
        }
        
        // Give it a moment to start
        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(sut.isAnalyzing, "Should be true during analysis")
        
        _ = try await analysisTask.value
        
        // Then
        XCTAssertFalse(sut.isAnalyzing, "Should be false after completion")
    }
    
    // MARK: - Analyze Text Tests
    
    func testAnalyzeText_WithValidText_ReturnsAnalysisResult() async throws {
        // Given
        let text = "The Lord's Prayer teaches us how to pray and what to ask for in our prayers."
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let result = try await sut.analyzeText(text)
        
        // Then
        XCTAssertFalse(result.keyPoints.isEmpty)
        XCTAssertGreaterThan(result.suggestedSlideCount, 0)
    }
    
    func testAnalyzeText_WithEmptyString_ThrowsInsufficientContentError() async {
        // When/Then
        do {
            _ = try await sut.analyzeText("")
            XCTFail("Should throw insufficient content error")
        } catch let error as AppError {
            XCTAssertEqual(error, .insufficientContent)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    func testAnalyzeText_WithAudience_PassesAudienceToService() async throws {
        // Given
        let text = "Teaching about the Sacraments"
        let audience = Audience.teenagers
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let result = try await sut.analyzeText(text, preferredAudience: audience)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertFalse(result.keyPoints.isEmpty)
    }
    
    // MARK: - Reanalyze Tests
    
    func testReanalyze_WithNewAudience_ReturnsNewAnalysis() async throws {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: "Religious education content",
            importedDate: Date()
        )
        let newAudience = Audience.adults
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let result = try await sut.reanalyze(sourceFile: sourceFile, for: newAudience)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertFalse(result.keyPoints.isEmpty)
    }
    
    // MARK: - Statistics Tests
    
    func testStatistics_WithValidResult_CalculatesCorrectly() {
        // Given
        let keyPoints = [
            KeyPoint(content: "First point with some content", order: 1),
            KeyPoint(content: "Second point with more content here", order: 2),
            KeyPoint(content: "Third point", order: 3)
        ]
        let result = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 3)
        
        // When
        let stats = sut.statistics(for: result)
        
        // Then
        XCTAssertEqual(stats.keyPointCount, 3)
        XCTAssertEqual(stats.suggestedSlideCount, 3)
        XCTAssertGreaterThan(stats.totalContentLength, 0)
        XCTAssertGreaterThan(stats.averagePointLength, 0)
        XCTAssertTrue(stats.isValid)
        XCTAssertFalse(stats.needsReview)
    }
    
    func testStatistics_WithEmptyResult_MarksAsInvalid() {
        // Given
        let result = ContentAnalysisResult(keyPoints: [], suggestedSlideCount: 0)
        
        // When
        let stats = sut.statistics(for: result)
        
        // Then
        XCTAssertEqual(stats.keyPointCount, 0)
        XCTAssertFalse(stats.isValid)
    }
    
    func testStatistics_WithHighSlideCount_MarksAsNeedsReview() {
        // Given
        let keyPoints = Array(repeating: KeyPoint(content: "Point", order: 1), count: 35)
        let result = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 35)
        
        // When
        let stats = sut.statistics(for: result)
        
        // Then
        XCTAssertTrue(stats.needsReview, "High slide count should need review")
    }
    
    func testStatistics_WithLowSlideCount_MarksAsNeedsReview() {
        // Given
        let keyPoints = [KeyPoint(content: "Single point", order: 1)]
        let result = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 1)
        
        // When
        let stats = sut.statistics(for: result)
        
        // Then
        XCTAssertTrue(stats.needsReview, "Low slide count should need review")
    }
    
    // MARK: - Error Handling Tests
    
    func testAnalyze_StoresLastError_WhenFails() async {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: "Test",
            importedDate: Date()
        )
        mockOpenAIService.shouldFail = .apiError("Test failure")
        
        // When
        do {
            _ = try await sut.analyze(sourceFile: sourceFile)
        } catch {
            // Expected
        }
        
        // Then
        XCTAssertNotNil(sut.lastError, "Should store error")
    }
    
    func testAnalyze_ResetsProgressOnCompletion() async throws {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: "Test content",
            importedDate: Date()
        )
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        _ = try await sut.analyze(sourceFile: sourceFile)
        
        // Then
        XCTAssertFalse(sut.isAnalyzing)
        XCTAssertEqual(sut.analysisProgress, 1.0)
    }
    
    func testAnalyze_ResetsProgressOnError() async {
        // Given
        let sourceFile = SourceFile(
            id: UUID(),
            filename: "test.txt",
            fileType: .txt,
            content: "Test",
            importedDate: Date()
        )
        mockOpenAIService.shouldFail = .invalidAPIKey
        
        // When
        do {
            _ = try await sut.analyze(sourceFile: sourceFile)
        } catch {
            // Expected
        }
        
        // Then
        XCTAssertFalse(sut.isAnalyzing, "Should stop analyzing")
        XCTAssertEqual(sut.analysisProgress, 1.0, "Progress should be reset")
    }
}
