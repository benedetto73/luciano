import Foundation

// Placeholder for AppCoordinator
// Will be implemented in Phase 6 (Tasks 35-37)

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentScreen: AppScreen = .apiKeySetup
    @Published var navigationPath: [AppScreen] = []
    
    private let keychainRepository: KeychainRepositoryProtocol
    private let dependencyContainer: DependencyContainer
    
    init(
        keychainRepository: KeychainRepositoryProtocol,
        dependencyContainer: DependencyContainer
    ) {
        self.keychainRepository = keychainRepository
        self.dependencyContainer = dependencyContainer
        checkAPIKeyAndSetInitialScreen()
    }
    
    private func checkAPIKeyAndSetInitialScreen() {
        // TODO: Implement in Phase 6
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
