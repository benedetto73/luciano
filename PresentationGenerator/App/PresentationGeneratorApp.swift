import SwiftUI

@main
struct PresentationGeneratorApp: App {
    @StateObject private var dependencyContainer = DependencyContainer()
    @StateObject private var coordinator: AppCoordinator
    
    init() {
        // Initialize dependency container and coordinator first
        let container = DependencyContainer()
        let coord = container.appCoordinator
        _dependencyContainer = StateObject(wrappedValue: container)
        _coordinator = StateObject(wrappedValue: coord)
        
        // Perform one-time setup after initialization
        Self.setupLogging()
        Self.createRequiredDirectories()
        
        // Log app startup
        Logger.shared.info("PresentationGenerator app launched", category: .app)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(dependencyContainer: dependencyContainer)
                .environmentObject(coordinator)
                .environmentObject(dependencyContainer)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    coordinator.start()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    coordinator.showProjectCreation()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .saveItem) {
                Button("Export Presentation") {
                    // Export current project if available
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(true) // Will be enabled when project is active
                
                Divider()
                
                Button("Save Project") {
                    // Save current project
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(true) // Will be enabled when project is active
            }
            
            CommandGroup(after: .sidebar) {
                Button("Settings...") {
                    coordinator.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    // MARK: - Setup Methods
    
    /// Configure logging system
    private static func setupLogging() {
        Logger.shared.info("Setting up logging system", category: .app)
        // Logger is already initialized as a singleton
        // Additional configuration can be added here if needed
    }
    
    /// Create required application directories
    private static func createRequiredDirectories() {
        let fileManager = FileManager.default
        let directories = [
            AppConstants.projectsDirectory,
            AppConstants.imagesDirectory,
            AppConstants.exportsDirectory
        ]
        
        for directory in directories {
            do {
                if !fileManager.fileExists(atPath: directory.path) {
                    try fileManager.createDirectory(
                        at: directory,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                    Logger.shared.info("Created directory: \(directory.lastPathComponent)", category: .app)
                }
            } catch {
                Logger.shared.error("Failed to create directory: \(directory.lastPathComponent)", error: error)
            }
        }
    }
}
