//
//  ProjectListViewModel.swift
//  PresentationGenerator
//
//  ViewModel for project list screen
//

import Foundation

@MainActor
class ProjectListViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .modifiedDate
    
    enum SortOption: String, CaseIterable {
        case modifiedDate = "Modified Date"
        case createdDate = "Created Date"
        case name = "Name"
    }
    
    // MARK: - Initialization
    
    init(projectManager: ProjectManager, appCoordinator: AppCoordinator) {
        self.projectManager = projectManager
        self.appCoordinator = appCoordinator
    }
    
    // MARK: - Computed Properties
    
    var filteredProjects: [Project] {
        var filtered = projects
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        switch sortOption {
        case .modifiedDate:
            filtered.sort { $0.modifiedDate > $1.modifiedDate }
        case .createdDate:
            filtered.sort { $0.createdDate > $1.createdDate }
        case .name:
            filtered.sort { $0.name < $1.name }
        }
        
        return filtered
    }
    
    var isEmpty: Bool {
        projects.isEmpty
    }
    
    // MARK: - Actions
    
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        
        await projectManager.loadAllProjects()
        projects = projectManager.allProjects
        
        isLoading = false
    }
    
    func createNewProject() {
        appCoordinator.showProjectCreation()
    }
    
    func openSettings() {
        appCoordinator.showSettings()
    }
    
    func openProject(_ project: Project) {
        appCoordinator.showProjectDetail(id: project.id)
    }
    
    func deleteProject(_ project: Project) async {
        do {
            try await projectManager.deleteProject(id: project.id)
            await loadProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        await loadProjects()
    }
}
