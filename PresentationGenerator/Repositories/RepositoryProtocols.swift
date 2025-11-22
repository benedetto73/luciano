import Foundation

// Protocol definitions for repositories (extracted from DependencyContainer)

protocol KeychainRepositoryProtocol {
    func save(apiKey: String) throws
    func retrieve() throws -> String?
    func delete() throws
}

protocol ProjectRepositoryProtocol {
    func save(_ project: Project) async throws
    func load(id: UUID) async throws -> Project
    func loadAll() async throws -> [Project]
    func delete(id: UUID) async throws
    func update(_ project: Project) async throws
}

protocol FileRepositoryProtocol {
    func importDocument(from url: URL) async throws -> String
    func saveImage(_ data: Data, for slideId: UUID) async throws -> URL
    func loadImage(for slideId: UUID) async throws -> Data
}
