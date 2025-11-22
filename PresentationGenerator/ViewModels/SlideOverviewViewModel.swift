//
//  SlideOverviewViewModel.swift
//  PresentationGenerator
//
//  ViewModel for slide overview and management
//

import Foundation
import SwiftUI

@MainActor
class SlideOverviewViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var slides: [Slide] = []
    @Published var designSpec: DesignSpec?
    @Published var isExporting: Bool = false
    @Published var exportProgress: Double = 0.0
    @Published var exportMessage: String = ""
    @Published var showExportProgress: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isLoadingDesign: Bool = false
    
    // MARK: - Dependencies
    let project: Project
    private let projectManager: ProjectManager
    private let slideDesigner: SlideDesigner
    private let powerPointExporter: PowerPointExporterProtocol
    private let coordinator: AppCoordinator
    
    // MARK: - Initialization
    init(
        project: Project,
        projectManager: ProjectManager,
        slideDesigner: SlideDesigner,
        powerPointExporter: PowerPointExporterProtocol,
        coordinator: AppCoordinator
    ) {
        self.project = project
        self.projectManager = projectManager
        self.slideDesigner = slideDesigner
        self.powerPointExporter = powerPointExporter
        self.coordinator = coordinator
        
        // Initialize with project data
        self.slides = project.slides.sorted { $0.slideNumber < $1.slideNumber }
        
        // Load design spec asynchronously
        Task {
            await loadDesignSpec()
        }
    }
    
    /// Load design spec for the project
    func loadDesignSpec() async {
        isLoadingDesign = true
        do {
            designSpec = try await slideDesigner.createDesignSpec(for: project.audience)
        } catch {
            Logger.shared.error("Failed to load design spec", error: error)
            errorMessage = "Failed to load design spec: \(error.localizedDescription)"
            showError = true
        }
        isLoadingDesign = false
    }
    
    // MARK: - Public Methods
    
    /// Reorder slides
    func reorderSlides(from source: IndexSet, to destination: Int) {
        slides.move(fromOffsets: source, toOffset: destination)
        
        // Update slideNumber property
        for (index, _) in slides.enumerated() {
            slides[index].slideNumber = index + 1
        }
        
        Task {
            await saveProject()
        }
    }
    
    /// Add a new slide
    func addSlide() {
        guard let design = designSpec else {
            errorMessage = "Design spec not loaded"
            showError = true
            return
        }
        
        let newSlide = Slide(
            id: UUID(),
            slideNumber: slides.count + 1,
            title: "New Slide",
            content: "Add your content here",
            imageData: nil,
            designSpec: design,
            notes: nil
        )
        
        slides.append(newSlide)
        
        Task {
            await saveProject()
        }
    }
    
    /// Delete a slide
    func deleteSlide(_ slide: Slide) {
        slides.removeAll { $0.id == slide.id }
        
        // Reorder remaining slides
        for (index, _) in slides.enumerated() {
            slides[index].slideNumber = index + 1
        }
        
        Task {
            await saveProject()
        }
    }
    
    /// Duplicate a slide
    func duplicateSlide(_ slide: Slide) {
        let duplicatedSlide = Slide(
            id: UUID(),
            slideNumber: slides.count + 1,
            title: slide.title + " (Copy)",
            content: slide.content,
            imageData: slide.imageData,
            designSpec: slide.designSpec,
            notes: slide.notes
        )
        
        slides.append(duplicatedSlide)
        
        Task {
            await saveProject()
        }
    }
    
    /// Edit a slide
    func editSlide(_ slide: Slide) {
        coordinator.navigate(to: .slideEditor(projectID: project.id, slideID: slide.id))
    }
    
    /// Export to PowerPoint
    func exportToPowerPoint() {
        guard !slides.isEmpty else {
            errorMessage = "No slides to export"
            showError = true
            return
        }
        
        isExporting = true
        exportProgress = 0.0
        showExportProgress = true
        
        Task {
            do {
                exportMessage = "Preparing slides..."
                exportProgress = 0.1
                
                // Update project with current slides
                var updatedProject = project
                updatedProject.slides = slides
                
                exportMessage = "Rendering slides..."
                exportProgress = 0.3
                
                // Create export URL
                let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                let fileName = "\(project.name.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).pptx"
                let exportURL = downloadsURL.appendingPathComponent(fileName)
                
                // Export to PowerPoint
                try await powerPointExporter.export(project: updatedProject, to: exportURL)
                
                exportMessage = "Finalizing export..."
                exportProgress = 1.0
                
                // Small delay to show completion
                try await Task.sleep(nanoseconds: 500_000_000)
                
                isExporting = false
                showExportProgress = false
                
                // Open the exported file
                NSWorkspace.shared.open(exportURL)
                
                Logger.shared.info("Successfully exported presentation to: \(exportURL.path)")
                
            } catch {
                isExporting = false
                showExportProgress = false
                errorMessage = "Export failed: \(error.localizedDescription)"
                showError = true
                Logger.shared.error("Failed to export presentation", error: error)
            }
        }
    }
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Private Methods
    
    /// Save project with updated slides
    private func saveProject() async {
        do {
            var updatedProject = project
            updatedProject.slides = slides
            updatedProject.modifiedDate = Date()
            
            try await projectManager.updateProject(updatedProject)
            
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showError = true
            Logger.shared.error("Failed to save project", error: error)
        }
    }
}
