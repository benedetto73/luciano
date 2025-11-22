//
//  SlideEditorViewModel.swift
//  PresentationGenerator
//
//  ViewModel for editing individual slides
//

import Foundation

@MainActor
class SlideEditorViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    private let autoSaveManager = AutoSaveManager(debounceInterval: 2.0)
    private var isInitialLoad = true
    let projectID: UUID
    let slideID: UUID
    
    @Published var project: Project?
    @Published var slide: Slide?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Editable properties
    @Published var title: String = "" {
        didSet {
            guard !isInitialLoad else { return }
            hasUnsavedChanges = true
            autoSaveManager.scheduleSave()
        }
    }
    @Published var content: String = "" {
        didSet {
            guard !isInitialLoad else { return }
            hasUnsavedChanges = true
            autoSaveManager.scheduleSave()
        }
    }
    @Published var notes: String = "" {
        didSet {
            guard !isInitialLoad else { return }
            hasUnsavedChanges = true
            autoSaveManager.scheduleSave()
        }
    }
    @Published var hasUnsavedChanges = false
    
    // Design options
    @Published var selectedDesign: DesignSpec?
    @Published var showingDesignPicker = false
    
    // Image options
    @Published var hasImage: Bool = false
    @Published var showingImageOptions = false
    
    init(
        projectID: UUID,
        slideID: UUID,
        projectManager: ProjectManager,
        appCoordinator: AppCoordinator
    ) {
        self.projectID = projectID
        self.slideID = slideID
        self.projectManager = projectManager
        self.appCoordinator = appCoordinator
        
        // Configure auto-save action
        autoSaveManager.saveAction = { [weak self] in
            await self?.saveChanges()
        }
    }
    
    // MARK: - Lifecycle
    
    func loadSlide() async {
        isLoading = true
        errorMessage = nil
        
        do {
            project = try await projectManager.loadProject(id: projectID)
            
            guard let foundSlide = project?.slides.first(where: { $0.id == slideID }) else {
                errorMessage = "Slide not found"
                isLoading = false
                return
            }
            
            slide = foundSlide
            title = foundSlide.title
            content = foundSlide.content
            notes = foundSlide.notes ?? ""
            selectedDesign = foundSlide.designSpec
            hasImage = foundSlide.imageData != nil
            
            hasUnsavedChanges = false
            isInitialLoad = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Actions
    
    func saveChanges() async {
        guard var project = project,
              var slide = slide else { return }
        
        isSaving = true
        errorMessage = nil
        successMessage = nil
        
        // Update slide with edited values
        slide.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        slide.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        slide.notes = notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let design = selectedDesign {
            slide.designSpec = design
        }
        
        // Update project with modified slide
        if let index = project.slides.firstIndex(where: { $0.id == slideID }) {
            project.slides[index] = slide
            project.modifiedDate = Date()
            
            do {
                try await projectManager.updateProject(project)
                self.slide = slide
                self.project = project
                hasUnsavedChanges = false
                successMessage = "Changes saved successfully"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        
        isSaving = false
    }
    
    func revertChanges() {
        guard let slide = slide else { return }
        
        title = slide.title
        content = slide.content
        notes = slide.notes ?? ""
        selectedDesign = slide.designSpec
        hasImage = slide.imageData != nil
        hasUnsavedChanges = false
    }
    
    func markAsChanged() {
        guard let slide = slide else { return }
        
        // Check if anything actually changed
        let titleChanged = title != slide.title
        let contentChanged = content != slide.content
        let notesChanged = notes != (slide.notes ?? "")
        let designChanged = selectedDesign?.layout != slide.designSpec.layout
        
        hasUnsavedChanges = titleChanged || contentChanged || notesChanged || designChanged
    }
    
    func deleteSlide() async {
        guard var project = project else { return }
        
        isSaving = true
        errorMessage = nil
        
        // Remove slide
        project.slides.removeAll { $0.id == slideID }
        
        // Update slide numbers
        for (index, var slide) in project.slides.enumerated() {
            slide.slideNumber = index + 1
            project.slides[index] = slide
        }
        
        project.modifiedDate = Date()
        
        do {
            try await projectManager.updateProject(project)
            close()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    func generateImage() async {
        // TODO: Implement image generation in future iteration
        errorMessage = "Image generation not yet implemented"
    }
    
    func removeImage() async {
        guard var project = project,
              var slide = slide else { return }
        
        slide.imageData = nil
        hasImage = false
        
        if let index = project.slides.firstIndex(where: { $0.id == slideID }) {
            project.slides[index] = slide
            project.modifiedDate = Date()
            
            do {
                try await projectManager.updateProject(project)
                self.slide = slide
                self.project = project
                hasUnsavedChanges = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func close() {
        appCoordinator.pop()
    }
    
    // MARK: - Navigation
    
    func navigateToPreviousSlide() {
        guard let project = project,
              let currentSlide = slide,
              currentSlide.slideNumber > 1 else { return }
        
        if let previousSlide = project.slides.first(where: { $0.slideNumber == currentSlide.slideNumber - 1 }) {
            // Save current changes if needed
            if hasUnsavedChanges {
                Task {
                    await saveChanges()
                    appCoordinator.replace(.slideEditor(projectID: projectID, slideID: previousSlide.id))
                }
            } else {
                appCoordinator.replace(.slideEditor(projectID: projectID, slideID: previousSlide.id))
            }
        }
    }
    
    func navigateToNextSlide() {
        guard let project = project,
              let currentSlide = slide,
              currentSlide.slideNumber < project.slides.count else { return }
        
        if let nextSlide = project.slides.first(where: { $0.slideNumber == currentSlide.slideNumber + 1 }) {
            // Save current changes if needed
            if hasUnsavedChanges {
                Task {
                    await saveChanges()
                    appCoordinator.replace(.slideEditor(projectID: projectID, slideID: nextSlide.id))
                }
            } else {
                appCoordinator.replace(.slideEditor(projectID: projectID, slideID: nextSlide.id))
            }
        }
    }
    
    var canNavigateToPrevious: Bool {
        guard let slide = slide else { return false }
        return slide.slideNumber > 1
    }
    
    var canNavigateToNext: Bool {
        guard let project = project, let slide = slide else { return false }
        return slide.slideNumber < project.slides.count
    }
}
