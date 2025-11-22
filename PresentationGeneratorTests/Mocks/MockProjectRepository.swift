import Foundation
@testable import PresentationGenerator

/// Mock implementation of ProjectRepositoryProtocol for testing
class MockProjectRepository: ProjectRepositoryProtocol {
    var projects: [UUID: Project] = [:]
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknownError("Mock error")
    
    func save(_ project: Project) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        projects[project.id] = project
    }
    
    func load(id: UUID) async throws -> Project {
        if shouldThrowError {
            throw errorToThrow
        }
        guard let project = projects[id] else {
            throw AppError.projectNotFound(id)
        }
        return project
    }
    
    func loadAll() async throws -> [Project] {
        if shouldThrowError {
            throw errorToThrow
        }
        return Array(projects.values).sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    func delete(id: UUID) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        projects.removeValue(forKey: id)
    }
    
    func update(_ project: Project) async throws {
        try await save(project)
    }
    
    func reset() {
        projects.removeAll()
        shouldThrowError = false
    }
}
