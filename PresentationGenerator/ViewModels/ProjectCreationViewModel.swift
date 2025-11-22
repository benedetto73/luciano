//
//  ProjectCreationViewModel.swift
//  PresentationGenerator
//
//  ViewModel for creating new projects
//

import Foundation

@MainActor
class ProjectCreationViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    
    @Published var projectName = ""
    @Published var selectedAudience: Audience = .adults
    @Published var isCreating = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    init(projectManager: ProjectManager, appCoordinator: AppCoordinator) {
        self.projectManager = projectManager
        self.appCoordinator = appCoordinator
    }
    
    // MARK: - Validation
    
    var canCreate: Bool {
        !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    func createProject() async {
        guard canCreate else { return }
        
        isCreating = true
        errorMessage = nil
        
        do {
            let project = try await projectManager.createProject(
                name: projectName.trimmingCharacters(in: .whitespacesAndNewlines),
                audience: selectedAudience
            )
            
            isCreating = false
            
            // Navigate to project detail
            appCoordinator.showProjectDetail(id: project.id)
            
        } catch {
            isCreating = false
            errorMessage = error.localizedDescription
        }
    }
    
    func cancel() {
        appCoordinator.pop()
    }
}
