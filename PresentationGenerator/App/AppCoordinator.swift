import Foundation

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentState: AppState = .splash
    @Published var currentScreen: AppScreen = .apiKeySetup
    @Published var navigationPath: [AppScreen] = []
    
    private let keychainRepository: KeychainRepositoryProtocol
    private let dependencyContainer: DependencyContainer
    
    enum AppState {
        case splash
        case apiKeySetup
        case mainApp
    }
    
    init(
        keychainRepository: KeychainRepositoryProtocol,
        dependencyContainer: DependencyContainer
    ) {
        self.keychainRepository = keychainRepository
        self.dependencyContainer = dependencyContainer
    }
    
    func start() {
        // Always show splash first
        currentState = .splash
    }
    
    func completeSplash() {
        // Check if user has completed setup
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        
        if hasCompletedSetup {
            // Setup already done, go to main app
            currentState = .mainApp
            currentScreen = .projectList
        } else {
            // First run, show API key setup
            currentState = .apiKeySetup
        }
    }
    
    func completeAPIKeySetup(useFreeModels: Bool) {
        Logger.shared.info("API setup completed, free models: \(useFreeModels)", category: .app)
        currentState = .mainApp
        currentScreen = .projectList
    }
    
    private func checkAPIKeyAndSetInitialScreen() {
        // Deprecated - now using start() method
        currentScreen = .apiKeySetup
    }
    
    func showProjectList() {
        // TODO: Implement navigation
    }
    
    func showProjectCreation() {
        // TODO: Implement navigation
    }
    
    func openProject(_ project: Project) {
        // TODO: Implement navigation
    }
}

enum AppScreen: Hashable {
    case apiKeySetup
    case projectList
    case projectCreation
    case fileImport(UUID)
    case contentAnalysis(UUID)
    case slideGeneration(UUID)
    case slideOverview(UUID)
}
