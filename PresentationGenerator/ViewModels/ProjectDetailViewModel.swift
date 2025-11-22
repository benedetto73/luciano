//
//  ProjectDetailViewModel.swift
//  PresentationGenerator
//
//  ViewModel for project detail and workflow
//

import Foundation

@MainActor
class ProjectDetailViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    private let fileRepository: FileRepositoryProtocol
    let projectID: UUID
    
    @Published var project: Project?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var workflowState: WorkflowState = .needsContent
    @Published var generationProgress: String = ""
    @Published var generationPercentage: Int = 0
    
    enum WorkflowState {
        case needsContent
        case readyToAnalyze
        case analyzing
        case readyToGenerate
        case generating
        case completed
        case error(String)
    }
    
    // MARK: - Initialization
    
    init(
        projectID: UUID,
        projectManager: ProjectManager,
        appCoordinator: AppCoordinator,
        fileRepository: FileRepositoryProtocol
    ) {
        self.projectID = projectID
        self.projectManager = projectManager
        self.appCoordinator = appCoordinator
        self.fileRepository = fileRepository
    }
    
    // MARK: - Computed Properties
    
    var canAnalyze: Bool {
        guard let project = project else { return false }
        return !project.sourceFiles.isEmpty
    }
    
    var canGenerate: Bool {
        guard let project = project else { return false }
        return !project.keyPoints.isEmpty
    }
    
    var canExport: Bool {
        guard let project = project else { return false }
        return !project.slides.isEmpty
    }
    
    var slideCount: Int {
        project?.slides.count ?? 0
    }
    
    var sourceFileCount: Int {
        project?.sourceFiles.count ?? 0
    }
    
    // MARK: - Lifecycle
    
    func loadProject() async {
        isLoading = true
        errorMessage = nil
        
        do {
            project = try await projectManager.loadProject(id: projectID)
            updateWorkflowState()
        } catch {
            errorMessage = error.localizedDescription
            workflowState = .error(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadProject()
    }
    
    // MARK: - Workflow Actions
    
    func importContent() {
        appCoordinator.showContentImport(projectID: projectID)
    }
    
    func analyzeContent() async {
        guard let project = project, canAnalyze else { return }
        
        workflowState = .analyzing
        generationProgress = "Analyzing content..."
        generationPercentage = 0
        
        do {
            let analysisResult = try await projectManager.analyzeContent(
                project: project,
                progressCallback: { progress in
                    self.generationPercentage = progress
                }
            )
            
            // Update project with key points
            var updatedProject = project
            updatedProject.keyPoints = analysisResult.keyPoints
            try await projectManager.updateProject(updatedProject)
            
            await loadProject()
            
        } catch {
            errorMessage = error.localizedDescription
            workflowState = .error(error.localizedDescription)
        }
    }
    
    func generateSlides() async {
        guard let project = project, canGenerate else { return }
        
        workflowState = .generating
        generationProgress = "Generating slides..."
        generationPercentage = 0
        
        do {
            _ = try await projectManager.generatePresentation(
                project: project,
                progressCallback: { message, current, total in
                    self.generationProgress = message
                    self.generationPercentage = current
                }
            )
            
            await loadProject()
            
        } catch {
            errorMessage = error.localizedDescription
            workflowState = .error(error.localizedDescription)
        }
    }
    
    func viewSlides() {
        appCoordinator.showExport(projectID: projectID)
    }
    
    func exportPresentation() {
        appCoordinator.showExport(projectID: projectID)
    }
    
    func deleteProject() async {
        do {
            try await projectManager.deleteProject(id: projectID)
            appCoordinator.popToRoot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Private Methods
    
    private func updateWorkflowState() {
        guard let project = project else {
            workflowState = .needsContent
            return
        }
        
        if !project.slides.isEmpty {
            workflowState = .completed
        } else if !project.keyPoints.isEmpty {
            workflowState = .readyToGenerate
        } else if !project.sourceFiles.isEmpty {
            workflowState = .readyToAnalyze
        } else {
            workflowState = .needsContent
        }
    }
}
