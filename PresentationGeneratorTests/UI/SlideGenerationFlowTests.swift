import XCTest
@testable import PresentationGenerator

/// UI tests for the slide generation flow
@MainActor
final class SlideGenerationFlowTests: XCTestCase {
    
    var viewModel: SlideGenerationViewModel!
    var mockSlideGenerator: MockSlideGenerator!
    var mockSlideDesigner: MockSlideDesigner!
    var mockProjectRepository: MockProjectRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSlideGenerator = MockSlideGenerator()
        mockSlideDesigner = MockSlideDesigner()
        mockProjectRepository = MockProjectRepository()
        
        let project = Project(
            id: UUID(),
            name: "Test Project",
            createdAt: Date(),
            modifiedAt: Date(),
            settings: ProjectSettings(audience: .business)
        )
        
        viewModel = SlideGenerationViewModel(
            project: project,
            slideGenerator: mockSlideGenerator,
            slideDesigner: mockSlideDesigner,
            projectRepository: mockProjectRepository
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockSlideGenerator = nil
        mockSlideDesigner = nil
        mockProjectRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.generatedSlides.count, 0)
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Slide Generation Tests
    
    func testSuccessfulSlideGeneration() async throws {
        let keyPoints = [
            KeyPoint(text: "Point 1", importance: .high),
            KeyPoint(text: "Point 2", importance: .medium)
        ]
        
        let expectedSlides = [
            Slide(id: UUID(), title: "Slide 1", content: "Content 1", order: 0),
            Slide(id: UUID(), title: "Slide 2", content: "Content 2", order: 1)
        ]
        
        mockSlideGenerator.generateSlidesResult = .success(expectedSlides)
        
        await viewModel.generateSlides(from: keyPoints)
        
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertEqual(viewModel.generatedSlides.count, 2)
        XCTAssertEqual(viewModel.progress, 1.0)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockSlideGenerator.generateSlidesCalled)
    }
    
    func testSlideGenerationFailure() async throws {
        let keyPoints = [KeyPoint(text: "Point 1", importance: .high)]
        
        mockSlideGenerator.generateSlidesResult = .failure(.apiError("Generation failed"))
        
        await viewModel.generateSlides(from: keyPoints)
        
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertEqual(viewModel.generatedSlides.count, 0)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(mockSlideGenerator.generateSlidesCalled)
    }
    
    func testGenerationProgress() async throws {
        let keyPoints = [KeyPoint(text: "Point 1", importance: .high)]
        
        mockSlideGenerator.generateSlidesDelay = 0.5
        mockSlideGenerator.generateSlidesResult = .success([
            Slide(id: UUID(), title: "Slide 1", content: "Content", order: 0)
        ])
        
        let expectation = XCTestExpectation(description: "Generation complete")
        
        Task {
            await viewModel.generateSlides(from: keyPoints)
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(viewModel.isGenerating)
        XCTAssertGreaterThan(viewModel.progress, 0.0)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.progress, 1.0)
    }
    
    // MARK: - Design Application Tests
    
    func testApplyDesignToSlides() async throws {
        let slides = [
            Slide(id: UUID(), title: "Slide 1", content: "Content 1", order: 0)
        ]
        viewModel.generatedSlides = slides
        
        let designSpec = DesignSpec(
            colorScheme: .business,
            fontFamily: "Helvetica",
            fontSize: 24,
            layout: .titleAndContent
        )
        
        let designedSlides = [
            Slide(id: slides[0].id, title: "Slide 1", content: "Content 1", order: 0, designSpec: designSpec)
        ]
        
        mockSlideDesigner.applyDesignResult = .success(designedSlides)
        
        await viewModel.applyDesign(designSpec)
        
        XCTAssertEqual(viewModel.generatedSlides.count, 1)
        XCTAssertNotNil(viewModel.generatedSlides[0].designSpec)
        XCTAssertTrue(mockSlideDesigner.applyDesignCalled)
    }
    
    func testDesignApplicationFailure() async throws {
        viewModel.generatedSlides = [
            Slide(id: UUID(), title: "Slide 1", content: "Content", order: 0)
        ]
        
        let designSpec = DesignSpec(
            colorScheme: .business,
            fontFamily: "Helvetica",
            fontSize: 24,
            layout: .titleAndContent
        )
        
        mockSlideDesigner.applyDesignResult = .failure(.unknown("Design failed"))
        
        await viewModel.applyDesign(designSpec)
        
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Slide Editing Tests
    
    func testUpdateSlideContent() {
        let slide = Slide(id: UUID(), title: "Original", content: "Original content", order: 0)
        viewModel.generatedSlides = [slide]
        
        viewModel.updateSlide(id: slide.id, title: "Updated", content: "Updated content")
        
        XCTAssertEqual(viewModel.generatedSlides[0].title, "Updated")
        XCTAssertEqual(viewModel.generatedSlides[0].content, "Updated content")
    }
    
    func testDeleteSlide() {
        let slide1 = Slide(id: UUID(), title: "Slide 1", content: "Content 1", order: 0)
        let slide2 = Slide(id: UUID(), title: "Slide 2", content: "Content 2", order: 1)
        viewModel.generatedSlides = [slide1, slide2]
        
        viewModel.deleteSlide(id: slide1.id)
        
        XCTAssertEqual(viewModel.generatedSlides.count, 1)
        XCTAssertEqual(viewModel.generatedSlides[0].id, slide2.id)
    }
    
    func testReorderSlides() {
        let slide1 = Slide(id: UUID(), title: "Slide 1", content: "Content 1", order: 0)
        let slide2 = Slide(id: UUID(), title: "Slide 2", content: "Content 2", order: 1)
        let slide3 = Slide(id: UUID(), title: "Slide 3", content: "Content 3", order: 2)
        viewModel.generatedSlides = [slide1, slide2, slide3]
        
        viewModel.moveSlide(from: IndexSet(integer: 0), to: 2)
        
        XCTAssertEqual(viewModel.generatedSlides[0].title, "Slide 2")
        XCTAssertEqual(viewModel.generatedSlides[1].title, "Slide 1")
    }
    
    func testDuplicateSlide() {
        let slide = Slide(id: UUID(), title: "Slide 1", content: "Content 1", order: 0)
        viewModel.generatedSlides = [slide]
        
        viewModel.duplicateSlide(id: slide.id)
        
        XCTAssertEqual(viewModel.generatedSlides.count, 2)
        XCTAssertEqual(viewModel.generatedSlides[1].title, "Slide 1")
        XCTAssertEqual(viewModel.generatedSlides[1].content, "Content 1")
        XCTAssertNotEqual(viewModel.generatedSlides[0].id, viewModel.generatedSlides[1].id)
    }
    
    // MARK: - Save Tests
    
    func testSaveSlides() async throws {
        let slides = [
            Slide(id: UUID(), title: "Slide 1", content: "Content 1", order: 0)
        ]
        viewModel.generatedSlides = slides
        
        mockProjectRepository.updateProjectResult = .success(())
        
        await viewModel.saveSlides()
        
        XCTAssertTrue(mockProjectRepository.updateProjectCalled)
        XCTAssertNil(viewModel.error)
    }
    
    func testSaveFailure() async throws {
        viewModel.generatedSlides = [
            Slide(id: UUID(), title: "Slide 1", content: "Content", order: 0)
        ]
        
        mockProjectRepository.updateProjectResult = .failure(.fileSystemError("Save failed"))
        
        await viewModel.saveSlides()
        
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Validation Tests
    
    func testEmptySlideValidation() {
        let slide = Slide(id: UUID(), title: "", content: "", order: 0)
        
        XCTAssertFalse(viewModel.isSlideValid(slide))
    }
    
    func testValidSlide() {
        let slide = Slide(id: UUID(), title: "Title", content: "Content", order: 0)
        
        XCTAssertTrue(viewModel.isSlideValid(slide))
    }
    
    // MARK: - Edge Cases
    
    func testGenerateEmptyKeyPoints() async throws {
        mockSlideGenerator.generateSlidesResult = .success([])
        
        await viewModel.generateSlides(from: [])
        
        XCTAssertEqual(viewModel.generatedSlides.count, 0)
    }
    
    func testGenerateLargeNumberOfSlides() async throws {
        let keyPoints = (0..<100).map { KeyPoint(text: "Point \($0)", importance: .medium) }
        let slides = (0..<100).map { Slide(id: UUID(), title: "Slide \($0)", content: "Content", order: $0) }
        
        mockSlideGenerator.generateSlidesResult = .success(slides)
        
        await viewModel.generateSlides(from: keyPoints)
        
        XCTAssertEqual(viewModel.generatedSlides.count, 100)
    }
    
    func testConcurrentSlideUpdates() {
        let slide = Slide(id: UUID(), title: "Original", content: "Original", order: 0)
        viewModel.generatedSlides = [slide]
        
        viewModel.updateSlide(id: slide.id, title: "Update 1", content: "Content 1")
        viewModel.updateSlide(id: slide.id, title: "Update 2", content: "Content 2")
        
        XCTAssertEqual(viewModel.generatedSlides[0].title, "Update 2")
    }
}

// MARK: - Mock Slide Generator

@MainActor
class MockSlideGenerator {
    var generateSlidesCalled = false
    var generateSlidesResult: Result<[Slide], AppError>?
    var generateSlidesDelay: TimeInterval = 0
    
    func generateSlides(from keyPoints: [KeyPoint], audience: Audience) async throws -> [Slide] {
        generateSlidesCalled = true
        
        if generateSlidesDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(generateSlidesDelay * 1_000_000_000))
        }
        
        switch generateSlidesResult {
        case .success(let slides):
            return slides
        case .failure(let error):
            throw error
        case .none:
            throw AppError.unknown("No result configured")
        }
    }
}

// MARK: - Mock Slide Designer

@MainActor
class MockSlideDesigner {
    var applyDesignCalled = false
    var applyDesignResult: Result<[Slide], AppError>?
    
    func applyDesign(_ designSpec: DesignSpec, to slides: [Slide]) async throws -> [Slide] {
        applyDesignCalled = true
        
        switch applyDesignResult {
        case .success(let slides):
            return slides
        case .failure(let error):
            throw error
        case .none:
            throw AppError.unknown("No result configured")
        }
    }
}
