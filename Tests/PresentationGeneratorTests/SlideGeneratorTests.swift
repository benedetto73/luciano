//
//  SlideGeneratorTests.swift
//  PresentationGeneratorTests
//
//  Unit tests for SlideGenerator service
//

import XCTest
@testable import PresentationGenerator

@MainActor
final class SlideGeneratorTests: XCTestCase {
    var sut: SlideGenerator!
    var mockOpenAIService: MockOpenAIService!
    var mockImageService: MockImageService!
    
    override func setUp() async throws {
        mockOpenAIService = MockOpenAIService()
        mockImageService = MockImageService()
        
        sut = SlideGenerator(
            openAIService: mockOpenAIService,
            imageService: mockImageService
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockOpenAIService = nil
        mockImageService = nil
    }
    
    // MARK: - Generate Slides Tests
    
    func testGenerateSlides_WithValidAnalysis_ReturnsSlides() async throws {
        // Given
        let keyPoints = [
            KeyPoint(content: "First teaching point", order: 1),
            KeyPoint(content: "Second teaching point", order: 2),
            KeyPoint(content: "Third teaching point", order: 3)
        ]
        let analysis = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 3)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.mockSlideCount = 3
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let slides = try await sut.generateSlides(
            from: analysis,
            designSpec: designSpec,
            audience: .kids
        )
        
        // Then
        XCTAssertEqual(slides.count, 3, "Should generate 3 slides")
        XCTAssertEqual(slides[0].slideNumber, 1)
        XCTAssertEqual(slides[1].slideNumber, 2)
        XCTAssertEqual(slides[2].slideNumber, 3)
        XCTAssertFalse(sut.isGenerating)
    }
    
    func testGenerateSlides_UpdatesProgressDuringGeneration() async throws {
        // Given
        let keyPoints = [
            KeyPoint(content: "Point 1", order: 1),
            KeyPoint(content: "Point 2", order: 2)
        ]
        let analysis = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 2)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.mockSlideCount = 2
        mockOpenAIService.simulatedDelay = 0.2
        
        var progressUpdates: [(Int, Int)] = []
        
        // When
        _ = try await sut.generateSlides(
            from: analysis,
            designSpec: designSpec,
            audience: .adults,
            progressCallback: { current, total in
                progressUpdates.append((current, total))
            }
        )
        
        // Then
        XCTAssertFalse(progressUpdates.isEmpty, "Should receive progress updates")
        XCTAssertEqual(sut.generationProgress.current, 0, "Progress should be reset")
    }
    
    func testGenerateSlides_SetsIsGeneratingFlag() async throws {
        // Given
        let keyPoints = [KeyPoint(content: "Point", order: 1)]
        let analysis = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 1)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.mockSlideCount = 1
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        XCTAssertFalse(sut.isGenerating)
        
        let task = Task {
            try await sut.generateSlides(
                from: analysis,
                designSpec: designSpec,
                audience: .kids
            )
        }
        
        try await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(sut.isGenerating, "Should be generating")
        
        _ = try await task.value
        
        // Then
        XCTAssertFalse(sut.isGenerating, "Should finish generating")
    }
    
    func testGenerateSlides_WhenServiceFails_ThrowsError() async {
        // Given
        let keyPoints = [KeyPoint(content: "Point", order: 1)]
        let analysis = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 1)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.shouldFail = .apiError("Test error")
        
        // When/Then
        do {
            _ = try await sut.generateSlides(
                from: analysis,
                designSpec: designSpec,
                audience: .kids
            )
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertNotNil(sut.lastError)
            XCTAssertFalse(sut.isGenerating)
        }
    }
    
    func testGenerateSlides_WithEmptyKeyPoints_ReturnsEmptyArray() async throws {
        // Given
        let analysis = ContentAnalysisResult(keyPoints: [], suggestedSlideCount: 0)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.mockSlideCount = 0
        
        // When
        let slides = try await sut.generateSlides(
            from: analysis,
            designSpec: designSpec,
            audience: .adults
        )
        
        // Then
        XCTAssertTrue(slides.isEmpty)
    }
    
    // MARK: - Generate Single Slide Tests
    
    func testGenerateSingleSlide_WithValidKeyPoint_ReturnsSlide() async throws {
        // Given
        let keyPoint = KeyPoint(content: "Important teaching", order: 1)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let slide = try await sut.generateSingleSlide(
            keyPoint: keyPoint,
            slideNumber: 3,
            totalSlides: 10,
            designSpec: designSpec,
            audience: .teenagers
        )
        
        // Then
        XCTAssertEqual(slide.slideNumber, 3)
        XCTAssertNotNil(slide.title)
        XCTAssertNotNil(slide.content)
        XCTAssertNotNil(slide.imageData)
        XCTAssertFalse(sut.isGenerating)
    }
    
    func testGenerateSingleSlide_SetsIsGeneratingFlag() async throws {
        // Given
        let keyPoint = KeyPoint(content: "Teaching", order: 1)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        XCTAssertFalse(sut.isGenerating)
        
        let task = Task {
            try await sut.generateSingleSlide(
                keyPoint: keyPoint,
                slideNumber: 1,
                totalSlides: 1,
                designSpec: designSpec,
                audience: .adults
            )
        }
        
        try await Task.sleep(nanoseconds: 10_000_000)
        
        _ = try await task.value
        
        // Then
        XCTAssertFalse(sut.isGenerating)
    }
    
    // MARK: - Regenerate Slide Tests
    
    func testRegenerateSlide_WithExistingSlide_ReturnsNewSlide() async throws {
        // Given
        let originalSlide = Slide(
            id: UUID(),
            slideNumber: 2,
            title: "Original Title",
            content: "Original content",
            imageData: ImageData(
                id: UUID(),
                generationPrompt: "Original prompt",
                fileSize: 1024
            ),
            designSpec: DesignSpec(
                layout: .titleAndContent,
                backgroundColor: "#FFFFFF",
                textColor: "#000000",
                fontSize: .medium,
                fontFamily: "Helvetica",
                imagePosition: .right,
                bulletStyle: .checkmark
            )
        )
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let newSlide = try await sut.regenerateSlide(
            originalSlide,
            totalSlides: 5,
            audience: .kids
        )
        
        // Then
        XCTAssertEqual(newSlide.slideNumber, originalSlide.slideNumber)
        XCTAssertNotEqual(newSlide.id, originalSlide.id, "Should have new ID")
    }
    
    // MARK: - Reorder Slides Tests
    
    func testReorderSlides_UpdatesSlideNumbers() async throws {
        // Given
        let slides = [
            Slide(
                id: UUID(),
                slideNumber: 1,
                title: "First",
                content: "Content 1",
                imageData: ImageData(id: UUID(), generationPrompt: "Prompt", fileSize: 100),
                designSpec: DesignSpec(
                    layout: .titleAndContent,
                    backgroundColor: "#FFFFFF",
                    textColor: "#000000",
                    fontSize: .medium,
                    fontFamily: "Helvetica",
                    imagePosition: .right,
                    bulletStyle: .checkmark
                )
            ),
            Slide(
                id: UUID(),
                slideNumber: 2,
                title: "Second",
                content: "Content 2",
                imageData: ImageData(id: UUID(), generationPrompt: "Prompt", fileSize: 100),
                designSpec: DesignSpec(
                    layout: .titleAndContent,
                    backgroundColor: "#FFFFFF",
                    textColor: "#000000",
                    fontSize: .medium,
                    fontFamily: "Helvetica",
                    imagePosition: .right,
                    bulletStyle: .checkmark
                )
            )
        ]
        
        // When
        let reordered = try await sut.reorderSlides(slides.reversed())
        
        // Then
        XCTAssertEqual(reordered[0].slideNumber, 1)
        XCTAssertEqual(reordered[1].slideNumber, 2)
        XCTAssertEqual(reordered[0].title, "Second")
        XCTAssertEqual(reordered[1].title, "First")
    }
    
    // MARK: - Error Handling Tests
    
    func testGenerateSlides_StoresLastError_WhenFails() async {
        // Given
        let keyPoints = [KeyPoint(content: "Point", order: 1)]
        let analysis = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 1)
        let designSpec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        mockOpenAIService.shouldFail = .invalidAPIKey
        
        // When
        do {
            _ = try await sut.generateSlides(
                from: analysis,
                designSpec: designSpec,
                audience: .adults
            )
        } catch {
            // Expected
        }
        
        // Then
        XCTAssertNotNil(sut.lastError)
    }
    
    // MARK: - Slide Properties Tests
    
    func testGenerateSlides_CreatesSlideWithCorrectProperties() async throws {
        // Given
        let keyPoints = [KeyPoint(content: "Teaching about sacraments", order: 1)]
        let analysis = ContentAnalysisResult(keyPoints: keyPoints, suggestedSlideCount: 1)
        let designSpec = DesignSpec(
            layout: .titleContentAndImage,
            backgroundColor: "#FFEB3B",
            textColor: "#000000",
            fontSize: .large,
            fontFamily: "Arial",
            imagePosition: .left,
            bulletStyle: .arrow
        )
        mockOpenAIService.mockSlideCount = 1
        mockOpenAIService.simulatedDelay = 0.1
        
        // When
        let slides = try await sut.generateSlides(
            from: analysis,
            designSpec: designSpec,
            audience: .kids
        )
        
        // Then
        let slide = slides[0]
        XCTAssertNotNil(slide.id)
        XCTAssertEqual(slide.slideNumber, 1)
        XCTAssertFalse(slide.title.isEmpty)
        XCTAssertFalse(slide.content.isEmpty)
        XCTAssertNotNil(slide.imageData)
        XCTAssertEqual(slide.designSpec.layout, .titleContentAndImage)
        XCTAssertEqual(slide.designSpec.backgroundColor, "#FFEB3B")
    }
}

// MARK: - Mock Image Service

@MainActor
class MockImageService: ImageService {
    var saveImageCalled = false
    var deleteImageCalled = false
    var shouldFail = false
    
    override func saveImage(_ data: Data, for slideId: UUID) async throws -> URL {
        saveImageCalled = true
        
        if shouldFail {
            throw AppError.fileOperationFailed("Mock save failure")
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("\(slideId).png")
    }
    
    override func deleteImage(for slideId: UUID) async throws {
        deleteImageCalled = true
        
        if shouldFail {
            throw AppError.fileOperationFailed("Mock delete failure")
        }
    }
}
