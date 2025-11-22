import SwiftUI

struct RootView: View {
    @StateObject private var coordinator: AppCoordinator
    private let dependencyContainer: DependencyContainer
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        _coordinator = StateObject(wrappedValue: dependencyContainer.appCoordinator)
    }
    
    var body: some View {
        Group {
            switch coordinator.currentState {
            case .splash:
                SplashView(onComplete: {
                    coordinator.completeSplash()
                })
                
            case .apiKeySetup:
                APIKeySetupView(
                    dependencyContainer: dependencyContainer,
                    onComplete: { useFreeModels in
                        coordinator.completeAPIKeySetup(useFreeModels: useFreeModels)
                    }
                )
                
            case .mainApp:
                MainAppView(coordinator: coordinator)
            }
        }
        .onAppear {
            coordinator.start()
        }
    }
}

// MARK: - Main App Navigation

struct MainAppView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            contentView
                .navigationDestination(for: AppScreen.self) { screen in
                    viewForScreen(screen)
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        viewForScreen(coordinator.currentScreen)
    }
    
    @ViewBuilder
    private func viewForScreen(_ screen: AppScreen) -> some View {
        switch screen {
        case .apiKeySetup:
            Text("API Key Setup - Should not appear here")
        case .projectList:
            Text("Project List - To be implemented")
        case .projectCreation:
            Text("Project Creation - To be implemented")
        case .fileImport:
            Text("File Import - To be implemented")
        case .contentAnalysis:
            Text("Content Analysis - To be implemented")
        case .slideGeneration:
            Text("Slide Generation - To be implemented")
        case .slideOverview:
            Text("Slide Overview - To be implemented")
        }
    }
}
