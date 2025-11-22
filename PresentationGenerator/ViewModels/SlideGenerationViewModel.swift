//
//  SlideGenerationViewModel.swift
//  PresentationGenerator
//
//  ViewModel for slide generation progress
//

import Foundation

@MainActor
class SlideGenerationViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    let projectID: UUID
    
    @Published var project: Project?
    @Published var isGenerating = false
    @Published var generationProgress: String = ""
    @Published var currentSlide: Int = 0
    @Published var totalSlides: Int = 0
    @Published var errorMessage: String?
    @Published var isComplete = false
    
    init(
        projectID: UUID,
        projectManager: ProjectManager,
        appCoordinator: AppCoordinator
    ) {
        self.projectID = projectID
        self.projectManager = projectManager
        self.appCoordinator = appCoordinator
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Double {
        guard totalSlides > 0 else { return 0 }
        return Double(currentSlide) / Double(totalSlides)
    }
    
    var progressText: String {
        if isComplete {
            return "Generation complete! Created \(totalSlides) slides"
        } else if isGenerating {
            return generationProgress
        } else {
            return "Ready to generate slides"
        }
    }
    
    // MARK: - Lifecycle
    
    func loadProject() async {
        do {
            project = try await projectManager.loadProject(id: projectID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Generation
    
    func startGeneration() async {
        guard let project = project else { return }
        
        isGenerating = true
        isComplete = false
        currentSlide = 0
        totalSlides = 0
        errorMessage = nil
        
        do {
            let updatedProject = try await projectManager.generatePresentation(
                project: project,
                progressCallback: { message, current, total in
                    self.generationProgress = message
                    self.currentSlide = current
                    self.totalSlides = total
                }
            )
            
            self.project = updatedProject
            isComplete = true
            totalSlides = updatedProject.slides.count
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    func viewSlides() {
        guard let project = project else { return }
        appCoordinator.showExport(projectID: project.id)
    }
    
    func exportPresentation() {
        guard let project = project else { return }
        appCoordinator.showExport(projectID: project.id)
    }
    
    func close() {
        appCoordinator.pop()
    }
}
