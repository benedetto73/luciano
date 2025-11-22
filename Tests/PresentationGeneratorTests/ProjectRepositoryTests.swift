//
//  ProjectRepositoryTests.swift
//  PresentationGeneratorTests
//
//  Unit tests for ProjectRepository
//

import XCTest
@testable import PresentationGenerator

@MainActor
final class ProjectRepositoryTests: XCTestCase {
    var sut: ProjectRepository!
    var mockStorageManager: MockProjectStorageManager!
    var mockFileManager: FileManager!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        // Create temp directory for testing
        mockFileManager = FileManager.default
        tempDirectory = mockFileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try mockFileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        mockStorageManager = MockProjectStorageManager()
        sut = ProjectRepository(
            storageManager: mockStorageManager,
            fileManager: mockFileManager
        )
    }
    
    override func tearDown() async throws {
        // Clean up temp directory
        if let tempDirectory = tempDirectory {
            try? mockFileManager.removeItem(at: tempDirectory)
        }
        
        sut = nil
        mockStorageManager = nil
        tempDirectory = nil
    }
    
    // MARK: - Save Tests
    
    func testSave_WithValidProject_UpdatesModifiedDate() async throws {
        // Given
        let originalDate = Date(timeIntervalSince1970: 0)
        let project = Project(
            id: UUID(),
            name: "Test Project",
            audience: .kids,
            createdDate: originalDate,
            modifiedDate: originalDate
        )
        
        // When
        try await sut.save(project)
        
        // Then
        XCTAssertTrue(mockStorageManager.saveCalled)
        XCTAssertNotNil(mockStorageManager.lastSavedProject)
        XCTAssertGreaterThan(
            mockStorageManager.lastSavedProject!.modifiedDate,
            originalDate,
            "Modified date should be updated"
        )
    }
    
    func testSave_CallsStorageManager() async throws {
        // Given
        let project = Project(
            id: UUID(),
            name: "Project",
            audience: .adults,
            createdDate: Date(),
            modifiedDate: Date()
        )
        
        // When
        try await sut.save(project)
        
        // Then
        XCTAssertTrue(mockStorageManager.saveCalled)
        XCTAssertEqual(mockStorageManager.lastSavedProject?.id, project.id)
    }
    
    // MARK: - Load Tests
    
    func testLoad_WithExistingProject_ReturnsProject() async throws {
        // Given
        let projectId = UUID()
        let expectedProject = Project(
            id: projectId,
            name: "Existing Project",
            audience: .teenagers,
            createdDate: Date(),
            modifiedDate: Date()
        )
        mockStorageManager.projectsToReturn[projectId] = expectedProject
        
        // When
        let loadedProject = try await sut.load(id: projectId)
        
        // Then
        XCTAssertTrue(mockStorageManager.loadCalled)
        XCTAssertEqual(loadedProject.id, projectId)
        XCTAssertEqual(loadedProject.name, "Existing Project")
    }
    
    func testLoad_WithNonExistentProject_ThrowsError() async {
        // Given
        let nonExistentId = UUID()
        
        // When/Then
        do {
            _ = try await sut.load(id: nonExistentId)
            XCTFail("Should throw error for non-existent project")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - LoadAll Tests
    
    func testLoadAll_ReturnsAllProjects() async throws {
        // Given
        let projects = [
            Project(id: UUID(), name: "Project 1", audience: .kids, createdDate: Date(), modifiedDate: Date()),
            Project(id: UUID(), name: "Project 2", audience: .adults, createdDate: Date(), modifiedDate: Date()),
            Project(id: UUID(), name: "Project 3", audience: .seniors, createdDate: Date(), modifiedDate: Date())
        ]
        
        for project in projects {
            mockStorageManager.projectsToReturn[project.id] = project
        }
        mockStorageManager.allProjectsToReturn = projects
        
        // When
        let loadedProjects = try await sut.loadAll()
        
        // Then
        XCTAssertTrue(mockStorageManager.loadAllCalled)
        XCTAssertEqual(loadedProjects.count, 3)
    }
    
    func testLoadAll_WithNoProjects_ReturnsEmptyArray() async throws {
        // Given
        mockStorageManager.allProjectsToReturn = []
        
        // When
        let projects = try await sut.loadAll()
        
        // Then
        XCTAssertTrue(projects.isEmpty)
    }
    
    // MARK: - Delete Tests
    
    func testDelete_WithExistingProject_DeletesProjectAndImages() async throws {
        // Given
        let projectId = UUID()
        let slide1ImageURL = tempDirectory.appendingPathComponent("image1.png")
        let slide2ImageURL = tempDirectory.appendingPathComponent("image2.png")
        
        // Create dummy image files
        try Data().write(to: slide1ImageURL)
        try Data().write(to: slide2ImageURL)
        
        let slides = [
            Slide(
                id: UUID(),
                slideNumber: 1,
                title: "Slide 1",
                content: "Content",
                imageData: ImageData(id: UUID(), localURL: slide1ImageURL, generationPrompt: "Prompt", fileSize: 100),
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
                title: "Slide 2",
                content: "Content",
                imageData: ImageData(id: UUID(), localURL: slide2ImageURL, generationPrompt: "Prompt", fileSize: 100),
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
        
        let project = Project(
            id: projectId,
            name: "Project to Delete",
            audience: .adults,
            createdDate: Date(),
            modifiedDate: Date(),
            slides: slides
        )
        
        mockStorageManager.projectsToReturn[projectId] = project
        
        // When
        try await sut.delete(id: projectId)
        
        // Then
        XCTAssertTrue(mockStorageManager.deleteCalled)
        XCTAssertFalse(mockFileManager.fileExists(atPath: slide1ImageURL.path))
        XCTAssertFalse(mockFileManager.fileExists(atPath: slide2ImageURL.path))
    }
    
    func testDelete_WithNonExistentProject_ThrowsError() async {
        // Given
        let nonExistentId = UUID()
        
        // When/Then
        do {
            try await sut.delete(id: nonExistentId)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Update Tests
    
    func testUpdate_UpdatesProject() async throws {
        // Given
        let project = Project(
            id: UUID(),
            name: "Updated Project",
            audience: .professionals,
            createdDate: Date(),
            modifiedDate: Date()
        )
        
        // When
        try await sut.update(project)
        
        // Then
        XCTAssertTrue(mockStorageManager.saveCalled)
    }
    
    // MARK: - Create Tests
    
    func testCreate_WithNameAndAudience_CreatesNewProject() async throws {
        // Given
        let name = "New Catholic Presentation"
        let audience = Audience.kids
        
        // When
        let project = try await sut.create(name: name, audience: audience)
        
        // Then
        XCTAssertEqual(project.name, name)
        XCTAssertEqual(project.audience, audience)
        XCTAssertNotNil(project.id)
        XCTAssertTrue(mockStorageManager.saveCalled)
    }
    
    // MARK: - Exists Tests
    
    func testExists_WithExistingProject_ReturnsTrue() {
        // Given
        let projectId = UUID()
        mockStorageManager.existingProjectIds.insert(projectId)
        
        // When
        let exists = sut.exists(id: projectId)
        
        // Then
        XCTAssertTrue(exists)
    }
    
    func testExists_WithNonExistentProject_ReturnsFalse() {
        // Given
        let nonExistentId = UUID()
        
        // When
        let exists = sut.exists(id: nonExistentId)
        
        // Then
        XCTAssertFalse(exists)
    }
    
    // MARK: - Export/Import Tests
    
    func testExport_CallsStorageManager() async throws {
        // Given
        let project = Project(
            id: UUID(),
            name: "Export Project",
            audience: .adults,
            createdDate: Date(),
            modifiedDate: Date()
        )
        let exportURL = tempDirectory.appendingPathComponent("export.json")
        
        // When
        try await sut.export(project: project, to: exportURL)
        
        // Then
        XCTAssertTrue(mockStorageManager.exportCalled)
    }
    
    func testImport_CallsStorageManager() async throws {
        // Given
        let importURL = tempDirectory.appendingPathComponent("import.json")
        let expectedProject = Project(
            id: UUID(),
            name: "Imported Project",
            audience: .teenagers,
            createdDate: Date(),
            modifiedDate: Date()
        )
        mockStorageManager.projectToImport = expectedProject
        
        // When
        let imported = try await sut.import(from: importURL)
        
        // Then
        XCTAssertTrue(mockStorageManager.importCalled)
        XCTAssertEqual(imported.name, "Imported Project")
    }
    
    // MARK: - Duplicate Tests
    
    func testDuplicate_CreatesNewProjectWithCopiedData() async throws {
        // Given
        let originalId = UUID()
        let originalProject = Project(
            id: originalId,
            name: "Original",
            audience: .kids,
            createdDate: Date(timeIntervalSince1970: 0),
            modifiedDate: Date(timeIntervalSince1970: 0)
        )
        mockStorageManager.projectsToReturn[originalId] = originalProject
        
        // When
        let duplicate = try await sut.duplicate(projectID: originalId)
        
        // Then
        XCTAssertNotEqual(duplicate.id, originalId, "Should have new ID")
        XCTAssertEqual(duplicate.name, "Original (Copy)")
        XCTAssertEqual(duplicate.audience, originalProject.audience)
        XCTAssertTrue(mockStorageManager.saveCalled)
    }
    
    func testDuplicate_WithCustomName_UsesProvidedName() async throws {
        // Given
        let originalId = UUID()
        let originalProject = Project(
            id: originalId,
            name: "Original",
            audience: .adults,
            createdDate: Date(),
            modifiedDate: Date()
        )
        mockStorageManager.projectsToReturn[originalId] = originalProject
        
        // When
        let duplicate = try await sut.duplicate(projectID: originalId, newName: "Custom Name")
        
        // Then
        XCTAssertEqual(duplicate.name, "Custom Name")
    }
}

// MARK: - Mock ProjectStorageManager

class MockProjectStorageManager: ProjectStorageManager {
    var saveCalled = false
    var loadCalled = false
    var loadAllCalled = false
    var deleteCalled = false
    var exportCalled = false
    var importCalled = false
    
    var lastSavedProject: Project?
    var projectsToReturn: [UUID: Project] = [:]
    var allProjectsToReturn: [Project] = []
    var existingProjectIds: Set<UUID> = []
    var projectToImport: Project?
    
    override func save(_ project: Project) throws {
        saveCalled = true
        lastSavedProject = project
        projectsToReturn[project.id] = project
    }
    
    override func load(projectID: UUID) throws -> Project {
        loadCalled = true
        
        guard let project = projectsToReturn[projectID] else {
            throw AppError.fileOperationFailed("Project not found")
        }
        
        return project
    }
    
    override func loadAll() throws -> [Project] {
        loadAllCalled = true
        return allProjectsToReturn
    }
    
    override func delete(projectID: UUID) throws {
        deleteCalled = true
        projectsToReturn.removeValue(forKey: projectID)
    }
    
    override func exists(projectID: UUID) -> Bool {
        return existingProjectIds.contains(projectID) || projectsToReturn[projectID] != nil
    }
    
    override func export(project: Project, to url: URL) throws {
        exportCalled = true
    }
    
    override func `import`(from url: URL) throws -> Project {
        importCalled = true
        
        guard let project = projectToImport else {
            throw AppError.fileOperationFailed("No project to import")
        }
        
        return project
    }
}
