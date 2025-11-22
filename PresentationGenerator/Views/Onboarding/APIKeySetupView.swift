//
//  APIKeySetupView.swift
//  PresentationGenerator
//
//  First-run setup for API key configuration
//

import SwiftUI

struct APIKeySetupView: View {
    @StateObject private var viewModel: APIKeySetupViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(dependencyContainer: DependencyContainer, onComplete: @escaping (Bool) -> Void) {
        _viewModel = StateObject(wrappedValue: APIKeySetupViewModel(
            keychainRepository: dependencyContainer.keychainRepository,
            openAIService: dependencyContainer.openAIService,
            onComplete: onComplete
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
                
                Text("Welcome to Presentation Maker")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose how you'd like to use the app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Options
            VStack(spacing: 20) {
                // Option 1: Use OpenAI Key
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        viewModel.selectedMode = .paidKey
                    }) {
                        HStack {
                            Image(systemName: viewModel.selectedMode == .paidKey ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(viewModel.selectedMode == .paidKey ? .blue : .gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use OpenAI API Key")
                                    .font(.headline)
                                Text("Full access with your own API key")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.selectedMode == .paidKey ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if viewModel.selectedMode == .paidKey {
                        VStack(alignment: .leading, spacing: 8) {
                            SecureField("Enter your OpenAI API key", text: $viewModel.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .disabled(viewModel.isValidating)
                            
                            Text("Your key will be stored securely in the system Keychain")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let error = viewModel.validationError {
                                Label(error, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            if viewModel.validationSuccess {
                                Label("API key validated successfully!", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.leading, 32)
                        .transition(.opacity)
                    }
                }
                
                // Option 2: Use Free Models
                Button(action: {
                    viewModel.selectedMode = .freeModels
                }) {
                    HStack {
                        Image(systemName: viewModel.selectedMode == .freeModels ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(viewModel.selectedMode == .freeModels ? .blue : .gray)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use Free Models")
                                .font(.headline)
                            Text("Limited functionality with simulated responses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.selectedMode == .freeModels ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 16) {
                if viewModel.selectedMode == .paidKey && !viewModel.validationSuccess {
                    Button("Validate Key") {
                        Task {
                            await viewModel.validateAPIKey()
                        }
                    }
                    .keyboardShortcut(.return)
                    .disabled(viewModel.apiKey.isEmpty || viewModel.isValidating)
                }
                
                Button(viewModel.selectedMode == .paidKey && viewModel.validationSuccess ? "Continue" : "Get Started") {
                    Task {
                        await viewModel.complete()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedMode == .paidKey && !viewModel.validationSuccess)
                .disabled(viewModel.selectedMode == nil)
            }
            .padding(.bottom, 40)
        }
        .frame(width: 600, height: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - ViewModel

@MainActor
class APIKeySetupViewModel: ObservableObject {
    enum SetupMode {
        case paidKey
        case freeModels
    }
    
    @Published var selectedMode: SetupMode?
    @Published var apiKey: String = ""
    @Published var isValidating = false
    @Published var validationError: String?
    @Published var validationSuccess = false
    
    private let keychainRepository: KeychainRepositoryProtocol
    private let openAIService: any OpenAIServiceProtocol
    private let onComplete: (Bool) -> Void
    
    init(
        keychainRepository: KeychainRepositoryProtocol,
        openAIService: any OpenAIServiceProtocol,
        onComplete: @escaping (Bool) -> Void
    ) {
        self.keychainRepository = keychainRepository
        self.openAIService = openAIService
        self.onComplete = onComplete
    }
    
    func validateAPIKey() async {
        guard !apiKey.isEmpty else { return }
        
        isValidating = true
        validationError = nil
        validationSuccess = false
        
        do {
            // Create a temporary OpenAI service with the provided key
            let testService = OpenAIService(apiKey: apiKey)
            
            // Validate the key
            let isValid = try await testService.validateAPIKey()
            
            if isValid {
                validationSuccess = true
                validationError = nil
                Logger.shared.info("API key validated successfully", category: .app)
            } else {
                validationError = "Invalid API key. Please check and try again."
                Logger.shared.warning("API key validation failed", category: .app)
            }
        } catch {
            validationError = "Validation failed: \(error.localizedDescription)"
            Logger.shared.error("API key validation error", error: error, category: .app)
        }
        
        isValidating = false
    }
    
    func complete() async {
        switch selectedMode {
        case .paidKey:
            guard validationSuccess else { return }
            
            // Save the API key to Keychain
            do {
                try keychainRepository.save(apiKey: apiKey)
                Logger.shared.info("API key saved to Keychain", category: .app)
                
                // Mark setup as complete with paid mode
                UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
                UserDefaults.standard.set(false, forKey: "useFreeModels")
                
                onComplete(false) // Not using free models
            } catch {
                validationError = "Failed to save API key: \(error.localizedDescription)"
                Logger.shared.error("Failed to save API key", error: error, category: .app)
            }
            
        case .freeModels:
            // Mark setup as complete with free mode
            UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
            UserDefaults.standard.set(true, forKey: "useFreeModels")
            
            Logger.shared.info("Setup completed with free models", category: .app)
            
            onComplete(true) // Using free models
            
        case .none:
            break
        }
    }
}
