import Foundation
import Security

/// Keychain-specific errors
enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedPasswordData
    case unhandledError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve from Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        case .itemNotFound:
            return "The requested item was not found in Keychain"
        case .duplicateItem:
            return "An item with this identifier already exists in Keychain"
        case .invalidData:
            return "The Keychain data is invalid or corrupted"
        case .unexpectedPasswordData:
            return "Unexpected password data format"
        case .unhandledError(let status):
            return "Unhandled Keychain error (status: \(status))"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .duplicateItem:
            return "Try deleting the existing item and saving again."
        case .retrieveFailed, .itemNotFound:
            return "The item may need to be created first."
        case .deleteFailed:
            return "Check that the item exists before trying to delete it."
        case .invalidData, .unexpectedPasswordData:
            return "The stored data may be corrupted. Try re-entering your API key."
        case .unhandledError:
            return "This is an unexpected Keychain error. Please restart the app."
        }
    }
    
    static func from(status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecSuccess:
            return .unhandledError(status) // This shouldn't happen for errors
        default:
            return .unhandledError(status)
        }
    }
}
