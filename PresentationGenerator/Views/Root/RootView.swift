import SwiftUI

// Placeholder for RootView
// Will be implemented in Phase 6 (Task 37)

struct RootView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
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
            Text("API Key Setup - To be implemented")
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
