//
//  ProjectDetailViewModel.swift
//  PresentationGenerator
//
//  ViewModel for project detail and workflow
//

import Foundation
import SwiftUI

@MainActor
class ProjectDetailViewModel: ObservableObject {
    let projectManager: ProjectManager
    let appCoordinator: AppCoordinator
    private let fileRepository: FileRepositoryProtocol
    let projectID: UUID
    
    @Published var project: Project?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var workflowState: WorkflowState = .needsContent
    @Published var generationProgress: String = ""
    @Published var generationPercentage: Int = 0
    
    // Workspace UI state
    @Published var selectedPhase: WorkflowPhase {
        didSet {
            UserDefaults.standard.set(selectedPhase.rawValue, forKey: "selectedPhase_\(projectID.uuidString)")
        }
    }
    
    // AI processing states
    @Published var isAnalyzing = false
    @Published var isGenerating = false
    @Published var analysisProgress: String = ""
    @Published var analysisPercentage: Double = 0.0
    @Published var showError = false
    @Published var errorTitle: String = ""
    
    // File picker state
    @Published var showingFilePicker = false
    
    // Key point editing state
    @Published var editingKeyPointId: UUID?
    @Published var editingKeyPointText: String = ""
    
    // Task management for cancellation
    private var analysisTask: Task<Void, Never>?
    private var generationTask: Task<Void, Never>?
    
    enum WorkflowState: Equatable {
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
        
        // Restore last selected phase
        if let savedPhaseRaw = UserDefaults.standard.string(forKey: "selectedPhase_\(projectID.uuidString)"),
           let savedPhase = WorkflowPhase(rawValue: savedPhaseRaw) {
            self.selectedPhase = savedPhase
        } else {
            self.selectedPhase = .importPhase
        }
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
        // Show file picker directly instead of navigating to ContentImportView
        showingFilePicker = true
    }
    
    func importFiles(_ urls: [URL]) async {
        guard let project = project else { return }
        
        isLoading = true
        errorMessage = nil
        
        var importedCount = 0
        var errors: [String] = []
        
        for url in urls {
            do {
                // Security-scoped resource access
                guard url.startAccessingSecurityScopedResource() else {
                    errors.append("Could not access \(url.lastPathComponent)")
                    continue
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                // File size validation (max 50MB)
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = attributes[.size] as? Int64, fileSize > 50 * 1024 * 1024 {
                    errors.append("\(url.lastPathComponent) exceeds 50MB limit")
                    continue
                }
                
                // Import the file
                try await projectManager.addSourceFile(to: project, from: url)
                importedCount += 1
                
            } catch {
                errors.append("Failed to import \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        // Reload project to get updated source files
        await loadProject()
        
        isLoading = false
        
        // Show result feedback
        if !errors.isEmpty {
            let errorMessages = errors.joined(separator: "\n")
            errorTitle = "Import Issues"
            errorMessage = "Imported \(importedCount) of \(urls.count) files.\n\n" + errorMessages
            showError = true
        } else if importedCount > 0 {
            // Success - optionally auto-advance to analyze phase
            // For now, just stay in import phase to allow more files
        }
    }
    
    func analyzeContent() async {
        guard let project = project, canAnalyze else { return }
        
        isAnalyzing = true
        analysisProgress = "Preparing content..."
        analysisPercentage = 0
        workflowState = .analyzing
        errorMessage = nil
        
        // Create cancellable task with timeout
        analysisTask = Task {
            do {
                // Timeout after 60 seconds
                let analysisResult = try await withThrowingTaskGroup(of: ContentAnalysisResult.self) { group in
                    group.addTask {
                        try await self.projectManager.analyzeContent(
                            project: project,
                            progressCallback: { progress in
                                Task { @MainActor in
                                    self.analysisPercentage = Double(progress)
                                    if progress < 30 {
                                        self.analysisProgress = "Sending content to OpenAI..."
                                    } else if progress < 60 {
                                        self.analysisProgress = "AI is analyzing content..."
                                    } else if progress < 90 {
                                        self.analysisProgress = "Extracting key points..."
                                    } else {
                                        self.analysisProgress = "Finalizing analysis..."
                                    }
                                }
                            }
                        )
                    }
                    
                    // Timeout task
                    group.addTask {
                        try await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                        throw NSError(domain: "Timeout", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "The analysis request timed out after 60 seconds. Please try again."
                        ])
                    }
                    
                    // Return first result (either completion or timeout)
                    guard let result = try await group.next() else {
                        throw NSError(domain: "TaskError", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Analysis failed"
                        ])
                    }
                    
                    group.cancelAll()
                    return result
                }
                
                // Update project with key points
                var updatedProject = project
                updatedProject.keyPoints = analysisResult.keyPoints
                try await projectManager.updateProject(updatedProject)
                
                await loadProject()
                analysisPercentage = 100
                analysisProgress = "Complete!"
                
                // Auto-advance to next phase
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        self.selectedPhase = .generate
                    }
                }
                
            } catch is CancellationError {
                Logger.shared.info("Analysis cancelled by user", category: .business)
                errorMessage = nil
            } catch {
                Logger.shared.error("Analysis failed", error: error, category: .business)
                errorTitle = "Analysis Failed"
                errorMessage = error.localizedDescription
                showError = true
                workflowState = .error(error.localizedDescription)
            }
            
            isAnalyzing = false
        }
        
        await analysisTask?.value
    }
    
    func cancelAnalysis() {
        analysisTask?.cancel()
        isAnalyzing = false
        workflowState = .readyToAnalyze
        Logger.shared.info("User cancelled analysis", category: .business)
    }
    
    func generateSlides() async {
        guard let project = project, canGenerate else { return }
        
        isGenerating = true
        generationProgress = "Preparing slides..."
        generationPercentage = 0
        workflowState = .generating
        errorMessage = nil
        
        // Create cancellable task with timeout
        generationTask = Task {
            do {
                // Timeout after 60 seconds per slide batch
                _ = try await withThrowingTaskGroup(of: Project.self) { group in
                    group.addTask {
                        try await self.projectManager.generatePresentation(
                            project: project,
                            progressCallback: { message, current, total in
                                Task { @MainActor in
                                    self.generationProgress = message
                                    self.generationPercentage = current
                                }
                            }
                        )
                    }
                    
                    // Timeout task (60 seconds * estimated slides)
                    let timeout = UInt64(max(60, project.keyPoints.count * 10)) * 1_000_000_000
                    group.addTask {
                        try await Task.sleep(nanoseconds: timeout)
                        throw NSError(domain: "Timeout", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "The slide generation timed out. Please try again with fewer slides."
                        ])
                    }
                    
                    // Return first result
                    guard let result = try await group.next() else {
                        throw NSError(domain: "TaskError", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Generation failed"
                        ])
                    }
                    
                    group.cancelAll()
                    return result
                }
                
                await loadProject()
                generationPercentage = 100
                generationProgress = "Complete!"
                
                // Auto-advance to edit phase
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) {
                        self.selectedPhase = .edit
                    }
                }
                
            } catch is CancellationError {
                Logger.shared.info("Generation cancelled by user", category: .business)
                errorMessage = nil
            } catch {
                Logger.shared.error("Generation failed", error: error, category: .business)
                errorTitle = "Generation Failed"
                errorMessage = error.localizedDescription
                showError = true
                workflowState = .error(error.localizedDescription)
            }
            
            isGenerating = false
        }
        
        await generationTask?.value
    }
    
    func cancelGeneration() {
        generationTask?.cancel()
        isGenerating = false
        workflowState = .readyToGenerate
        Logger.shared.info("User cancelled generation", category: .business)
    }
    
    func retryLastOperation() {
        showError = false
        errorMessage = nil
        errorTitle = ""
        
        // Retry based on current state
        Task {
            if !canGenerate {
                await analyzeContent()
            } else if canGenerate {
                await generateSlides()
            }
        }
    }
    
    func dismissError() {
        showError = false
        errorMessage = nil
        errorTitle = ""
        updateWorkflowState()
    }
    
    // MARK: - Key Point Editing
    
    func startEditingKeyPoint(id: UUID) {
        guard let project = project,
              let keyPoint = project.keyPoints.first(where: { $0.id == id }) else { return }
        editingKeyPointId = id
        editingKeyPointText = keyPoint.content
    }
    
    func cancelKeyPointEdit() {
        editingKeyPointId = nil
        editingKeyPointText = ""
    }
    
    func saveKeyPointEdit() async {
        guard let keyPointId = editingKeyPointId,
              let project = project else { return }
        
        // Validate
        let trimmed = editingKeyPointText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 && trimmed.count <= 500 else {
            errorTitle = "Invalid Key Point"
            errorMessage = "Key point must be between 10 and 500 characters."
            showError = true
            return
        }
        
        // Update key point
        do {
            try await projectManager.updateKeyPoint(
                in: project,
                keyPointId: keyPointId,
                newContent: trimmed
            )
            
            // Reload project to get updates
            await loadProject()
            
            // Clear editing state
            editingKeyPointId = nil
            editingKeyPointText = ""
            
        } catch {
            errorTitle = "Save Failed"
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func autoSaveKeyPointEdit() async {
        guard let keyPointId = editingKeyPointId,
              let project = project else { return }
        
        // Validate
        let trimmed = editingKeyPointText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 && trimmed.count <= 500 else { return }
        
        // Auto-save without clearing editing state
        do {
            try await projectManager.updateKeyPoint(
                in: project,
                keyPointId: keyPointId,
                newContent: trimmed
            )
            await loadProject()
        } catch {
            // Silently fail for auto-save
        }
    }
    
    // MARK: - Workflow Actions (continued)
    
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
