//
//  ProjectManagerTests.swift
//  PresentationGeneratorTests
//
//  Unit tests for ProjectManager
//

import XCTest
@testable import PresentationGenerator

@MainActor
final class ProjectManagerTests: XCTestCase {
    var sut: ProjectManager!
    var mockProjectRepository: MockProjectRepository!
    var mockContentAnalyzer: MockContentAnalyzer!
    var mockSlideDesigner: MockSlideDesigner!
    var mockSlideGenerator: MockSlideGenerator!
    var mockSlideRenderer: MockSlideRenderer!
    var mockPowerPointExporter: MockPowerPointExporter!
    var mockImageService: MockImageService!
    
    override func setUp() async throws {
        mockProjectRepository = MockProjectRepository()
        mockContentAnalyzer = MockContentAnalyzer()
        mockSlideDesigner = MockSlideDesigner()
        mockSlideGenerator = MockSlideGenerator()
        mockSlideRenderer = MockSlideRenderer()
        mockPowerPointExporter = MockPowerPointExporter()
        mockImageService = MockImageService()
        
        sut = ProjectManager(
            projectRepository: mockProjectRepository,
            contentAnalyzer: mockContentAnalyzer,
            slideDesigner: mockSlideDesigner,
            slideGenerator: mockSlideGenerator,
            slideRenderer: mockSlideRenderer,
            powerPointExporter: mockPowerPointExporter,
            imageService: mockImageService
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockProjectRepository = nil
        mockContentAnalyzer = nil
        mockSlideDesigner = nil
        mockSlideGenerator = nil
        mockSlideRenderer = nil
        mockPowerPointExporter = nil
        mockImageService = nil
    }
    
    // MARK: - Project CRUD Tests
    
    func testCreateProject_Success() async throws {
        // Given
        let name = "Test Presentation"
        let audience = Audience.kids
        
        // When
        let project = try await sut.createProject(name: name, audience: audience)
        
        // Then
        XCTAssertEqual(project.name, name)
        XCTAssertEqual(project.audience, audience)
        XCTAssertTrue(mockProjectRepository.saveCalled)
        XCTAssertNotNil(sut.currentProject)
    }
    
    func testLoadProject_Success() async throws {
        // Given
        let project = Project(
            id: UUID(),
            name: "Test Project",
            audience: .adults,
            createdDate: Date(),
            modifiedDate: Date()
        )
        mockProjectRepository.projectToReturn = project
        
        // When
        let loadedProject = try await sut.loadProject(id: project.id)
        
        // Then
        XCTAssertEqual(loadedProject.id, project.id)
        XCTAssertEqual(loadedProject.name, project.name)
        XCTAssertTrue(mockProjectRepository.loadCalled)
    }
    
    func testDeleteProject_Success() async throws {
        // Given
        let projectId = UUID()
        
        // When
        try await sut.deleteProject(id: projectId)
        
        // Then
        XCTAssertTrue(mockProjectRepository.deleteCalled)
        XCTAssertNil(sut.currentProject)
    }
    
    // MARK: - Content Analysis Tests
    
    func testAnalyzeContent_WithSourceFiles_Success() async throws {
        // Given
        let project = Project(
            id: UUID(),
            name: "Test",
            audience: .kids,
            createdDate: Date(),
            modifiedDate: Date(),
            sourceFiles: [
                SourceFile(
                    filename: "test.txt",
                    content: "Sample content for testing",
                    fileSize: 100,
                    fileType: .txt
                )
            ]
        )
        
        let expectedResult = ContentAnalysisResult(
            keyPoints: ["Point 1", "Point 2"],
            suggestedSlideCount: 5,
            complexity: .beginner
        )
        mockContentAnalyzer.resultToReturn = expectedResult
        
        // When
        let result = try await sut.analyzeContent(project: project)
        
        // Then
        XCTAssertEqual(result.keyPoints.count, 2)
        XCTAssertTrue(mockContentAnalyzer.analyzeTextCalled)
    }
    
    func testAnalyzeContent_WithoutSourceFiles_ThrowsError() async {
        // Given
        let project = Project(
            id: UUID(),
            name: "Test",
            audience: .kids,
            createdDate: Date(),
            modifiedDate: Date()
        )
        
        // When/Then
        do {
            _ = try await sut.analyzeContent(project: project)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
}

// MARK: - Mock Implementations

class MockProjectRepository: ProjectRepositoryProtocol {
    var saveCalled = false
    var loadCalled = false
    var deleteCalled = false
    var projectToReturn: Project?
    
    func save(_ project: Project) async throws {
        saveCalled = true
    }
    
    func load(id: UUID) async throws -> Project {
        loadCalled = true
        return projectToReturn ?? Project(
            id: id,
            name: "Mock Project",
            audience: .kids,
            createdDate: Date(),
            modifiedDate: Date()
        )
    }
    
    func loadAll() async throws -> [Project] {
        return projectToReturn.map { [$0] } ?? []
    }
    
    func update(_ project: Project) async throws {
        saveCalled = true
    }
    
    func delete(id: UUID) async throws {
        deleteCalled = true
    }
}

class MockContentAnalyzer: ContentAnalyzerProtocol {
    var analyzeTextCalled = false
    var resultToReturn: ContentAnalysisResult?
    
    func analyzeText(_ text: String) async throws -> ContentAnalysisResult {
        analyzeTextCalled = true
        return resultToReturn ?? ContentAnalysisResult(
            keyPoints: ["Mock Point"],
            suggestedSlideCount: 3,
            complexity: .beginner
        )
    }
}

class MockSlideDesigner: SlideDesignerProtocol {
    func createDesignSpec(for audience: Audience) async throws -> DesignSpec {
        return DesignSpec(
            primaryColor: "#4A90E2",
            secondaryColor: "#50E3C2",
            backgroundColor: "#FFFFFF",
            textColor: "#333333",
            fontFamily: "Arial",
            fontSize: 24
        )
    }
}

class MockSlideGenerator: SlideGeneratorProtocol {
    func generateSlides(
        from analysis: ContentAnalysisResult,
        designSpec: DesignSpec,
        audience: Audience,
        progressCallback: ((Int, Int) -> Void)?
    ) async throws -> [Slide] {
        return [
            Slide(
                slideNumber: 1,
                title: "Mock Slide",
                content: "Mock content",
                designSpec: designSpec
            )
        ]
    }
}

class MockSlideRenderer: SlideRendererProtocol {
    func renderSlide(_ slide: Slide) async throws -> NSImage {
        return NSImage()
    }
}

class MockPowerPointExporter: PowerPointExporterProtocol {
    func exportPresentation(
        slides: [Slide],
        title: String,
        to url: URL,
        progressCallback: ((Int, Int) -> Void)?
    ) async throws {
        // Mock export
    }
}

class MockImageService: ImageServiceProtocol {
    func generateImage(prompt: String, size: ImageSize) async throws -> NSImage {
        return NSImage()
    }
    
    func loadImage(from url: URL) async throws -> NSImage {
        return NSImage()
    }
    
    func saveImage(_ image: NSImage, to url: URL) async throws {
        // Mock save
    }
}
