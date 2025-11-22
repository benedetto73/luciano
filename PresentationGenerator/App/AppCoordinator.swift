import Foundation

/// Application screens
enum AppScreen: Hashable {
    case projectList
    case projectCreation
    case projectDetail(UUID)
    case contentImport(UUID)
    case contentAnalysis(UUID)
    case slideGeneration(UUID)
    case slideEditor(UUID)
    case export(UUID)
    case settings
    case apiKeySetup
}

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
    
    // MARK: - App Lifecycle
    
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
    
    // MARK: - Navigation
    
    func navigate(to screen: AppScreen) {
        Logger.shared.debug("Navigating to: \(screen)", category: .app)
        currentScreen = screen
    }
    
    func push(_ screen: AppScreen) {
        navigationPath.append(screen)
        currentScreen = screen
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
        currentScreen = navigationPath.last ?? .projectList
    }
    
    func popToRoot() {
        navigationPath.removeAll()
        currentScreen = .projectList
    }
    
    // MARK: - Screen Shortcuts
    
    func showProjectList() {
        navigate(to: .projectList)
    }
    
    func showProjectCreation() {
        push(.projectCreation)
    }
    
    func showProjectDetail(id: UUID) {
        push(.projectDetail(id))
    }
    
    func showContentImport(projectID: UUID) {
        push(.contentImport(projectID))
    }
    
    func showContentAnalysis(projectID: UUID) {
        push(.contentAnalysis(projectID))
    }
    
    func showSlideGeneration(projectID: UUID) {
        push(.slideGeneration(projectID))
    }
    
    func showSlideEditor(projectID: UUID) {
        push(.slideEditor(projectID))
    }
    
    func showExport(projectID: UUID) {
        push(.export(projectID))
    }
    
    func showSettings() {
        push(.settings)
    }
}
