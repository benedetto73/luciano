//
//  SettingsViewModel.swift
//  PresentationGenerator
//
//  ViewModel for app settings
//

import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    private let appCoordinator: AppCoordinator
    private let keychainRepository: KeychainRepositoryProtocol
    
    @Published var apiKey: String = ""
    @Published var isUsingFreeModels: Bool = false
    @Published var hasChanges: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isValidating: Bool = false
    
    init(
        appCoordinator: AppCoordinator,
        keychainRepository: KeychainRepositoryProtocol
    ) {
        self.appCoordinator = appCoordinator
        self.keychainRepository = keychainRepository
    }
    
    // MARK: - Lifecycle
    
    func loadSettings() {
        // Load API key (masked for display)
        if let key = try? keychainRepository.retrieve() {
            apiKey = String(repeating: "\u{2022}", count: 20) + key.suffix(4)
        }
        
        // Load free models preference
        isUsingFreeModels = UserDefaults.standard.bool(forKey: "useFreeModels")
    }
    
    // MARK: - Actions
    
    func updateAPIKey(_ newKey: String) async {
        guard !newKey.isEmpty else {
            errorMessage = "API key cannot be empty"
            return
        }
        
        // Validate format
        guard newKey.hasPrefix("sk-") else {
            errorMessage = "Invalid API key format. OpenAI keys start with 'sk-'"
            return
        }
        
        // Test the key with OpenAI
        do {
            let testService = OpenAIService(apiKey: newKey)
            let isValid = try await testService.validateAPIKey()
            
            guard isValid else {
                errorMessage = "API key validation failed. Please check your key and try again."
                return
            }
            
            // Save to keychain if valid
            try keychainRepository.save(apiKey: newKey)
            successMessage = "API key validated and saved successfully"
            hasChanges = false
            
            // Reload settings to show masked key
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.successMessage = nil
                self.loadSettings()
            }
            
        } catch {
            errorMessage = "Failed to validate API key: \(error.localizedDescription)"
        }
    }
    
    func toggleFreeModels(_ useFree: Bool) {
        UserDefaults.standard.set(useFree, forKey: "useFreeModels")
        isUsingFreeModels = useFree
        successMessage = "Model preference updated"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.successMessage = nil
        }
    }
    
    func clearAPIKey() async {
        do {
            try keychainRepository.delete()
            apiKey = ""
            successMessage = "API key removed"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.successMessage = nil
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func close() {
        appCoordinator.pop()
    }
}
