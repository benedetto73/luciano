import Foundation
@testable import PresentationGenerator

/// Mock implementation of KeychainRepositoryProtocol for testing
class MockKeychainRepository: KeychainRepositoryProtocol {
    var storedAPIKey: String?
    var shouldThrowError = false
    var errorToThrow: Error = KeychainError.saveFailed(errSecIO)
    
    func save(apiKey: String) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        storedAPIKey = apiKey
    }
    
    func retrieve() throws -> String? {
        if shouldThrowError {
            throw errorToThrow
        }
        return storedAPIKey
    }
    
    func delete() throws {
        if shouldThrowError {
            throw errorToThrow
        }
        storedAPIKey = nil
    }
    
    func reset() {
        storedAPIKey = nil
        shouldThrowError = false
    }
}
