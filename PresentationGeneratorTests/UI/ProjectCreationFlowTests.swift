import XCTest
@testable import PresentationGenerator

/// UI tests for the project creation flow
@MainActor
final class ProjectCreationFlowTests: XCTestCase {
    
    var viewModel: ProjectCreationViewModel!
    var mockProjectManager: MockProjectManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockProjectManager = MockProjectManager()
        viewModel = ProjectCreationViewModel(projectManager: mockProjectManager)
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockProjectManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Form Validation Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.projectName, "")
        XCTAssertEqual(viewModel.projectDescription, "")
        XCTAssertNil(viewModel.selectedAudience)
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNil(viewModel.error)
    }
    
    func testProjectNameValidation() {
        // Empty name should be invalid
        viewModel.projectName = ""
        XCTAssertFalse(viewModel.isFormValid)
        
        // Whitespace only should be invalid
        viewModel.projectName = "   "
        XCTAssertFalse(viewModel.isFormValid)
        
        // Valid name
        viewModel.projectName = "My Presentation"
        viewModel.selectedAudience = .business
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func testAudienceSelection() {
        viewModel.projectName = "Test Project"
        
        // No audience selected
        viewModel.selectedAudience = nil
        XCTAssertFalse(viewModel.isFormValid)
        
        // Each audience type
        for audience in Audience.allCases {
            viewModel.selectedAudience = audience
            XCTAssertTrue(viewModel.isFormValid)
        }
    }
    
    func testDescriptionIsOptional() {
        viewModel.projectName = "Test Project"
        viewModel.selectedAudience = .business
        viewModel.projectDescription = ""
        
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    // MARK: - Project Creation Tests
    
    func testSuccessfulProjectCreation() async throws {
        viewModel.projectName = "My Presentation"
        viewModel.projectDescription = "A test presentation"
        viewModel.selectedAudience = .business
        
        mockProjectManager.createProjectResult = .success(Project(
            id: UUID(),
            name: "My Presentation",
            description: "A test presentation",
            createdAt: Date(),
            modifiedAt: Date(),
            settings: ProjectSettings(audience: .business)
        ))
        
        await viewModel.createProject()
        
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockProjectManager.createProjectCalled)
    }
    
    func testProjectCreationFailure() async throws {
        viewModel.projectName = "Test Project"
        viewModel.selectedAudience = .business
        
        mockProjectManager.createProjectResult = .failure(.fileSystemError("Failed to create project"))
        
        await viewModel.createProject()
        
        XCTAssertFalse(viewModel.isCreating)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(mockProjectManager.createProjectCalled)
    }
    
    func testProjectCreationLoadingState() async throws {
        viewModel.projectName = "Test Project"
        viewModel.selectedAudience = .business
        
        mockProjectManager.createProjectDelay = 0.5
        mockProjectManager.createProjectResult = .success(Project(
            id: UUID(),
            name: "Test Project",
            createdAt: Date(),
            modifiedAt: Date(),
            settings: ProjectSettings(audience: .business)
        ))
        
        let expectation = XCTestExpectation(description: "Project creation")
        
        Task {
            await viewModel.createProject()
            expectation.fulfill()
        }
        
        // Check loading state is set
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        XCTAssertTrue(viewModel.isCreating)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isCreating)
    }
    
    // MARK: - Form Reset Tests
    
    func testFormReset() {
        viewModel.projectName = "Test Project"
        viewModel.projectDescription = "Description"
        viewModel.selectedAudience = .business
        
        viewModel.reset()
        
        XCTAssertEqual(viewModel.projectName, "")
        XCTAssertEqual(viewModel.projectDescription, "")
        XCTAssertNil(viewModel.selectedAudience)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationAfterSuccessfulCreation() async throws {
        viewModel.projectName = "Test Project"
        viewModel.selectedAudience = .business
        
        let project = Project(
            id: UUID(),
            name: "Test Project",
            createdAt: Date(),
            modifiedAt: Date(),
            settings: ProjectSettings(audience: .business)
        )
        
        mockProjectManager.createProjectResult = .success(project)
        
        await viewModel.createProject()
        
        XCTAssertNotNil(viewModel.createdProject)
        XCTAssertEqual(viewModel.createdProject?.id, project.id)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorDismissal() async throws {
        viewModel.projectName = "Test"
        viewModel.selectedAudience = .business
        
        mockProjectManager.createProjectResult = .failure(.fileSystemError("Error"))
        
        await viewModel.createProject()
        XCTAssertNotNil(viewModel.error)
        
        viewModel.dismissError()
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Edge Cases
    
    func testLongProjectName() {
        let longName = String(repeating: "A", count: 1000)
        viewModel.projectName = longName
        viewModel.selectedAudience = .business
        
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func testSpecialCharactersInName() {
        let specialChars = "Project @#$%^&*()_+-=[]{}|;':\",./<>?"
        viewModel.projectName = specialChars
        viewModel.selectedAudience = .business
        
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func testUnicodeCharactersInName() {
        viewModel.projectName = "プレゼンテーション 演示文稿 🎯"
        viewModel.selectedAudience = .business
        
        XCTAssertTrue(viewModel.isFormValid)
    }
}

// MARK: - Mock Project Manager

@MainActor
class MockProjectManager {
    var createProjectCalled = false
    var createProjectResult: Result<Project, AppError>?
    var createProjectDelay: TimeInterval = 0
    
    func createProject(name: String, description: String?, audience: Audience) async throws -> Project {
        createProjectCalled = true
        
        if createProjectDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(createProjectDelay * 1_000_000_000))
        }
        
        switch createProjectResult {
        case .success(let project):
            return project
        case .failure(let error):
            throw error
        case .none:
            throw AppError.unknown("No result configured")
        }
    }
}
