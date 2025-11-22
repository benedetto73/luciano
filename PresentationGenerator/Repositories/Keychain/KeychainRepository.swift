import Foundation
import Security

/// Repository for managing API keys in Keychain
class KeychainRepository: KeychainRepositoryProtocol {
    private let service: String
    private let account: String
    
    init(
        service: String = APIConstants.keychainService,
        account: String = APIConstants.keychainAccount
    ) {
        self.service = service
        self.account = account
    }
    
    // MARK: - KeychainRepositoryProtocol
    
    func save(apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw KeychainError.invalidData
        }
        
        let data = apiKey.data(using: .utf8)!
        
        // Build query to check if item exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            Logger.shared.error("Failed to save API key to Keychain", category: .keychain)
            throw KeychainError.saveFailed(status)
        }
        
        Logger.shared.info("API key saved to Keychain successfully", category: .keychain)
    }
    
    func retrieve() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            Logger.shared.debug("No API key found in Keychain", category: .keychain)
            return nil
        }
        
        guard status == errSecSuccess else {
            Logger.shared.error("Failed to retrieve API key from Keychain", category: .keychain)
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            Logger.shared.error("Invalid API key data in Keychain", category: .keychain)
            throw KeychainError.unexpectedPasswordData
        }
        
        Logger.shared.debug("API key retrieved from Keychain successfully", category: .keychain)
        return apiKey
    }
    
    func delete() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            Logger.shared.error("Failed to delete API key from Keychain", category: .keychain)
            throw KeychainError.deleteFailed(status)
        }
        
        Logger.shared.info("API key deleted from Keychain successfully", category: .keychain)
    }
    
    // MARK: - Additional Helper Methods
    
    /// Checks if an API key exists in Keychain
    func hasAPIKey() -> Bool {
        return (try? retrieve()) != nil
    }
    
    /// Updates existing API key or saves new one
    func update(apiKey: String) throws {
        try save(apiKey: apiKey)
    }
}
