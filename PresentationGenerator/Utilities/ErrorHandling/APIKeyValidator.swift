import Foundation
import SwiftUI

/// Validates and manages API key configuration with secure storage
@MainActor
class APIKeyValidator: ObservableObject {
    
    // MARK: - Properties
    
    private let keychainRepository: KeychainRepository
    private let networkHandler: NetworkErrorHandler
    
    @Published private(set) var validationState: ValidationState = .unknown
    
    // MARK: - Types
    
    enum ValidationState {
        case unknown
        case validating
        case valid(expiresAt: Date?)
        case invalid(reason: String)
        case missing
    }
    
    // MARK: - Initialization
    
    init(keychainRepository: KeychainRepository, networkHandler: NetworkErrorHandler) {
        self.keychainRepository = keychainRepository
        self.networkHandler = networkHandler
    }
    
    // MARK: - Validation
    
    /// Validates the OpenAI API key
    func validateAPIKey() async throws {
        validationState = .validating
        
        // Retrieve API key from keychain
        guard let apiKey = try? keychainRepository.retrieve(),
              !apiKey.isEmpty else {
            validationState = .missing
            throw AppError.apiKeyMissing
        }
        
        // Check format
        guard isValidFormat(apiKey) else {
            validationState = .invalid(reason: "Invalid API key format")
            throw AppError.invalidAPIKey("API key format is invalid")
        }
        
        // Test API key with actual API call
        do {
            try await testAPIKey(apiKey)
            validationState = .valid(expiresAt: nil)
        } catch {
            let reason = extractErrorReason(from: error)
            validationState = .invalid(reason: reason)
            throw error
        }
    }
    
    /// Validates API key format
    private func isValidFormat(_ apiKey: String) -> Bool {
        // OpenAI API keys typically start with "sk-" and have specific length
        return apiKey.hasPrefix("sk-") && apiKey.count > 20
    }
    
    /// Tests API key with actual API call
    private func testAPIKey(_ apiKey: String) async throws {
        // Make a minimal API call to validate the key
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Valid key
            return
        case 401:
            throw AppError.invalidAPIKey("API key is invalid or expired")
        case 429:
            throw AppError.rateLimitExceeded
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.apiError("Validation failed: \(message)")
        }
    }
    
    /// Extracts user-friendly error reason
    private func extractErrorReason(from error: Error) -> String {
        if let appError = error as? AppError {
            switch appError {
            case .invalidAPIKey(let message):
                return message
            case .rateLimitExceeded:
                return "Rate limit exceeded. Please try again later."
            case .networkError(let message):
                return "Network error: \(message)"
            default:
                return appError.localizedDescription
            }
        }
        return error.localizedDescription
    }
    
    // MARK: - API Key Management
    
    /// Saves and validates a new API key
    func saveAndValidateAPIKey(_ apiKey: String) async throws {
        // Validate format first
        guard isValidFormat(apiKey) else {
            throw AppError.invalidAPIKey("API key format is invalid. Must start with 'sk-'")
        }
        
        // Test the key
        validationState = .validating
        try await testAPIKey(apiKey)
        
        // Save to keychain if valid
        try keychainRepository.save(apiKey: apiKey)
        validationState = .valid(expiresAt: nil)
    }
    
    /// Removes the API key
    func removeAPIKey() throws {
        try keychainRepository.delete()
        validationState = .missing
    }
    
    // MARK: - Workflow Integration
    
    /// Ensures API key is valid before proceeding with operation
    func ensureValidAPIKey() async throws {
        switch validationState {
        case .valid:
            return
        case .unknown, .invalid, .missing:
            try await validateAPIKey()
        case .validating:
            // Wait for current validation
            while case .validating = validationState {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            
            // Check result
            if case .valid = validationState {
                return
            } else {
                throw AppError.apiKeyMissing
            }
        }
    }
    
    /// Prompts user for API key if missing
    func promptForAPIKeyIfNeeded() async throws -> Bool {
        switch validationState {
        case .valid:
            return false
        case .unknown:
            do {
                try await validateAPIKey()
                return false
            } catch {
                return true // Need to prompt
            }
        case .missing, .invalid:
            return true // Need to prompt
        case .validating:
            return false // Already handling
        }
    }
}

// MARK: - AppError Extension

extension AppError {
    static let apiKeyMissing = AppError.invalidAPIKey("API key is missing. Please configure your OpenAI API key.")
}
