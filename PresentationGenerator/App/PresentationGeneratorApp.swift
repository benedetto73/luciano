import SwiftUI

@main
struct PresentationGeneratorApp: App {
    @StateObject private var dependencyContainer = DependencyContainer()
    @StateObject private var coordinator: AppCoordinator
    
    init() {
        let container = DependencyContainer()
        let coord = container.appCoordinator
        _dependencyContainer = StateObject(wrappedValue: container)
        _coordinator = StateObject(wrappedValue: coord)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .environmentObject(dependencyContainer)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    coordinator.showProjectCreation()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
