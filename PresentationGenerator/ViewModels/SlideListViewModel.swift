//
//  SlideListViewModel.swift
//  PresentationGenerator
//
//  ViewModel for viewing and editing slides
//

import Foundation

@MainActor
class SlideListViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    let projectID: UUID
    
    @Published var project: Project?
    @Published var slides: [Slide] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSlide: Slide?
    
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
            slides = project?.slides ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Slide Actions
    
    func moveSlides(from source: IndexSet, to destination: Int) async {
        guard var project = project else { return }
        
        var updatedSlides = slides
        updatedSlides.move(fromOffsets: source, toOffset: destination)
        
        // Update slide numbers
        for (index, var slide) in updatedSlides.enumerated() {
            slide.slideNumber = index + 1
            updatedSlides[index] = slide
        }
        
        project.slides = updatedSlides
        
        do {
            try await projectManager.updateProject(project)
            await loadProject()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteSlides(at offsets: IndexSet) async {
        guard var project = project else { return }
        
        project.slides.remove(atOffsets: offsets)
        
        // Update slide numbers
        for (index, var slide) in project.slides.enumerated() {
            slide.slideNumber = index + 1
            project.slides[index] = slide
        }
        
        do {
            try await projectManager.updateProject(project)
            await loadProject()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func selectSlide(_ slide: Slide) {
        selectedSlide = slide
        appCoordinator.showSlideEditor(projectID: projectID, slideID: slide.id)
    }
    
    func close() {
        appCoordinator.pop()
    }
}
