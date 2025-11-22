//
//  ContentAnalysisViewModel.swift
//  PresentationGenerator
//
//  ViewModel for content analysis results and editing
//

import Foundation

@MainActor
class ContentAnalysisViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    let projectID: UUID
    
    @Published var project: Project?
    @Published var keyPoints: [KeyPoint] = []
    @Published var editingIndex: Int?
    @Published var editingText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var suggestedSlideCount: Int = 0
    
    init(
        projectID: UUID,
        projectManager: ProjectManager,
        appCoordinator: AppCoordinator
    ) {
        self.projectID = projectID
        self.projectManager = projectManager
        self.appCoordinator = appCoordinator
    }
    
    // MARK: - Lifecycle
    
    func loadProject() async {
        isLoading = true
        errorMessage = nil
        
        do {
            project = try await projectManager.loadProject(id: projectID)
            keyPoints = project?.keyPoints ?? []
            
            // If we have key points, show them
            if !keyPoints.isEmpty {
                suggestedSlideCount = min(max(keyPoints.count, 3), 20)
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Analysis Actions
    
    func analyzeContent() async {
        guard let project = project else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await projectManager.analyzeContent(
                project: project,
                progressCallback: { progress in
                    // Progress updates handled by ProjectManager
                }
            )
            
            keyPoints = result.keyPoints
            suggestedSlideCount = result.suggestedSlideCount
            
            // Update project
            var updatedProject = project
            updatedProject.keyPoints = result.keyPoints
            try await projectManager.updateProject(updatedProject)
            
            await loadProject()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Editing Actions
    
    func startEditing(at index: Int) {
        editingIndex = index
        editingText = keyPoints[index].content
    }
    
    func saveEdit() async {
        guard let index = editingIndex, var project = project else { return }
        
        keyPoints[index] = KeyPoint(
            id: keyPoints[index].id,
            content: editingText,
            order: keyPoints[index].order
        )
        project.keyPoints = keyPoints
        
        do {
            try await projectManager.updateProject(project)
            editingIndex = nil
            editingText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func cancelEdit() {
        editingIndex = nil
        editingText = ""
    }
    
    func addKeyPoint() async {
        guard var project = project else { return }
        
        let newPoint = KeyPoint(
            id: UUID(),
            content: "New key point",
            order: keyPoints.count
        )
        keyPoints.append(newPoint)
        project.keyPoints = keyPoints
        
        do {
            try await projectManager.updateProject(project)
            // Start editing the new point
            startEditing(at: keyPoints.count - 1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteKeyPoint(at offsets: IndexSet) async {
        guard var project = project else { return }
        
        keyPoints.remove(atOffsets: offsets)
        project.keyPoints = keyPoints
        
        do {
            try await projectManager.updateProject(project)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func moveKeyPoints(from source: IndexSet, to destination: Int) async {
        guard var project = project else { return }
        
        keyPoints.move(fromOffsets: source, toOffset: destination)
        project.keyPoints = keyPoints
        
        do {
            try await projectManager.updateProject(project)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Navigation
    
    func proceedToGeneration() {
        appCoordinator.showSlideGeneration(projectID: projectID)
    }
    
    func close() {
        appCoordinator.pop()
    }
}
