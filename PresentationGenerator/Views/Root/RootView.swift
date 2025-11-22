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
                MainAppView(coordinator: coordinator, dependencyContainer: dependencyContainer)
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
    let dependencyContainer: DependencyContainer
    
    init(coordinator: AppCoordinator, dependencyContainer: DependencyContainer) {
        self.coordinator = coordinator
        self.dependencyContainer = dependencyContainer
    }
    
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
            ProjectListView(
                viewModel: dependencyContainer.makeProjectListViewModel()
            )
        case .projectCreation:
            ProjectCreationView(
                viewModel: dependencyContainer.makeProjectCreationViewModel()
            )
        case .projectDetail(let projectID):
            ProjectDetailView(
                viewModel: dependencyContainer.makeProjectDetailViewModel(projectID: projectID)
            )
        case .contentImport(let projectID):
            ContentImportView(
                viewModel: dependencyContainer.makeContentImportViewModel(projectID: projectID)
            )
        case .contentAnalysis:
            Text("Content Analysis - To be implemented")
        case .slideGeneration:
            Text("Slide Generation - To be implemented")
        case .slideEditor(let projectID):
            SlideListView(
                viewModel: dependencyContainer.makeSlideListViewModel(projectID: projectID)
            )
        case .export(let projectID):
            ExportView(
                viewModel: dependencyContainer.makeExportViewModel(projectID: projectID)
            )
        case .settings:
            SettingsView(
                viewModel: dependencyContainer.makeSettingsViewModel()
            )
        }
    }
}
