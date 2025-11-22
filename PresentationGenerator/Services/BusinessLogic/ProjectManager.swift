//
//  ProjectManager.swift
//  PresentationGenerator
//
//  Manages project lifecycle and business operations
//

import Foundation

/// High-level project management service
@MainActor
class ProjectManager: ObservableObject {
    private let projectRepository: ProjectRepositoryProtocol
    private let contentAnalyzer: ContentAnalyzer
    private let slideDesigner: SlideDesigner
    private let slideGenerator: SlideGenerator
    private let powerPointExporter: PowerPointExporter
    
    @Published var currentProject: Project?
    @Published var allProjects: [Project] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    
    // MARK: - Initialization
    
    init(
        projectRepository: ProjectRepositoryProtocol,
        contentAnalyzer: ContentAnalyzer,
        slideDesigner: SlideDesigner,
        slideGenerator: SlideGenerator,
        powerPointExporter: PowerPointExporter
    ) {
        self.projectRepository = projectRepository
        self.contentAnalyzer = contentAnalyzer
        self.slideDesigner = slideDesigner
        self.slideGenerator = slideGenerator
        self.powerPointExporter = powerPointExporter
    }
    
    // MARK: - Project CRUD
    
    /// Creates a new project
    func createProject(name: String, audience: Audience) async throws -> Project {
        isLoading = true
        defer { isLoading = false }
        
        Logger.shared.info("Creating new project: \(name)", category: .business)
        
        do {
            let project = Project(
                id: UUID(),
                name: name,
                audience: audience,
                createdDate: Date(),
                modifiedDate: Date()
            )
            
            try await projectRepository.save(project)
            currentProject = project
            await loadAllProjects()
            
            Logger.shared.info("Project created successfully", category: .business)
            return project
            
        } catch {
            let appError = error as? AppError ?? AppError.projectSaveError(error)
            lastError = appError
            Logger.shared.error("Failed to create project", error: error, category: .business)
            throw appError
        }
    }
    
    /// Loads all projects
    func loadAllProjects() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            allProjects = try await projectRepository.loadAll()
                .sorted { $0.modifiedDate > $1.modifiedDate }
            Logger.shared.info("Loaded \(allProjects.count) projects", category: .business)
            
        } catch {
            lastError = error
            Logger.shared.error("Failed to load projects", error: error, category: .business)
        }
    }
    
    /// Loads a specific project
    func loadProject(id: UUID) async throws -> Project {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let project = try await projectRepository.load(id: id)
            currentProject = project
            Logger.shared.info("Loaded project: \(project.name)", category: .business)
            return project
            
        } catch {
            let appError = error as? AppError ?? AppError.projectLoadError(error)
            lastError = appError
            Logger.shared.error("Failed to load project", error: error, category: .business)
            throw appError
        }
    }
    
    /// Updates a project
    func updateProject(_ project: Project) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var updatedProject = project
            updatedProject.modifiedDate = Date()
            
            try await projectRepository.update(updatedProject)
            
            if currentProject?.id == project.id {
                currentProject = updatedProject
            }
            
            await loadAllProjects()
            Logger.shared.info("Project updated: \(project.name)", category: .business)
            
        } catch {
            let appError = error as? AppError ?? AppError.projectSaveError(error)
            lastError = appError
            Logger.shared.error("Failed to update project", error: error, category: .business)
            throw appError
        }
    }
    
    /// Deletes a project
    func deleteProject(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await projectRepository.delete(id: id)
            
            if currentProject?.id == id {
                currentProject = nil
            }
            
            await loadAllProjects()
            Logger.shared.info("Project deleted", category: .business)
            
        } catch {
            let appError = error as? AppError ?? AppError.projectLoadError(error)
            lastError = appError
            Logger.shared.error("Failed to delete project", error: error, category: .business)
            throw appError
        }
    }
    
    // MARK: - Content Operations
    
    /// Adds source file to project
    func addSourceFile(_ sourceFile: SourceFile, to project: Project) async throws {
        var updatedProject = project
        updatedProject.sourceFiles.append(sourceFile)
        try await updateProject(updatedProject)
    }
    
    /// Adds source file to project from URL
    func addSourceFile(to project: Project, from url: URL) async throws {
        // Read file content
        let content: String
        let fileExtension = url.pathExtension.lowercased()
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes[.size] as? Int64) ?? 0
        
        // Determine file type
        let fileType: DocumentType
        
        switch fileExtension {
        case "txt", "text":
            content = try String(contentsOf: url, encoding: .utf8)
            fileType = .txt
        case "pdf":
            // For now, basic PDF text extraction (could be enhanced)
            if let pdfData = try? Data(contentsOf: url),
               let pdfText = extractTextFromPDF(data: pdfData) {
                content = pdfText
            } else {
                throw AppError.invalidFileFormat("Could not extract text from PDF")
            }
            fileType = .txt  // Treat as text for now
        case "rtf":
            if let rtfData = try? Data(contentsOf: url),
               let attributedString = try? NSAttributedString(data: rtfData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                content = attributedString.string
            } else {
                throw AppError.invalidFileFormat("Could not read RTF file")
            }
            fileType = .rtf
        case "doc":
            content = "[DOC file: \\(url.lastPathComponent) - conversion not yet implemented]"
            fileType = .doc
        case "docx":
            content = "[DOCX file: \\(url.lastPathComponent) - conversion not yet implemented]"
            fileType = .docx
        case "jpg", "jpeg", "png":
            // For images, just note the filename (could add OCR later)
            content = "[Image: \\(url.lastPathComponent)]"
            fileType = .txt  // Treat as text for now
        default:
            // Try as plain text
            content = try String(contentsOf: url, encoding: .utf8)
            fileType = .txt
        }
        
        let sourceFile = SourceFile(
            id: UUID(),
            filename: url.lastPathComponent,
            content: content,
            fileSize: fileSize,
            importedDate: Date(),
            fileType: fileType
        )
        
        try await addSourceFile(sourceFile, to: project)
    }
    
    private func extractTextFromPDF(data: Data) -> String? {
        // Basic PDF text extraction - in a real app, use PDFKit
        // For now, return a placeholder
        return "[PDF content - text extraction not yet implemented]"
    }
    
    /// Removes source file from project
    func removeSourceFile(_ sourceFile: SourceFile, from project: Project) async throws {
        var updatedProject = project
        updatedProject.sourceFiles.removeAll { $0.id == sourceFile.id }
        try await updateProject(updatedProject)
    }
    
    /// Updates a key point's content
    func updateKeyPoint(in project: Project, keyPointId: UUID, newContent: String) async throws {
        var updatedProject = project
        
        // Find and update the key point
        guard let index = updatedProject.keyPoints.firstIndex(where: { $0.id == keyPointId }) else {
            throw AppError.unknown("Key point not found")
        }
        
        updatedProject.keyPoints[index].content = newContent
        
        // Save the updated project
        try await updateProject(updatedProject)
        
        Logger.shared.info("Key point updated: \(keyPointId)", category: .business)
    }
    
    /// Analyzes content and generates key points
    func analyzeContent(project: Project, progressCallback: ((Int) -> Void)? = nil) async throws -> ContentAnalysisResult {
        guard !project.sourceFiles.isEmpty else {
            throw AppError.insufficientContent
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Combine all source file content
            let combinedContent = project.sourceFiles
                .map { $0.content }
                .joined(separator: "\n\n")
            
            let result = try await contentAnalyzer.analyzeText(combinedContent)
            
            Logger.shared.info("Content analyzed: \(result.keyPoints.count) key points", category: .business)
            return result
            
        } catch {
            let appError = error as? AppError ?? AppError.unknown(error.localizedDescription)
            lastError = appError
            Logger.shared.error("Content analysis failed", error: error, category: .business)
            throw appError
        }
    }
    
    /// Generates slides from analysis
    func generateSlides(
        project: Project,
        analysisResult: ContentAnalysisResult,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws -> [Slide] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create design spec
            let designSpec = try await slideDesigner.createDesignSpec(for: project.audience)
            
            // Generate slides
            let slides = try await slideGenerator.generateSlides(
                from: analysisResult,
                designSpec: designSpec,
                audience: project.audience,
                progressCallback: progressCallback
            )
            
            Logger.shared.info("Generated \(slides.count) slides", category: .business)
            return slides
            
        } catch {
            let appError = error as? AppError ?? AppError.unknown(error.localizedDescription)
            lastError = appError
            Logger.shared.error("Slide generation failed", error: error, category: .business)
            throw appError
        }
    }
    
    /// Complete workflow: analyze + generate
    func generatePresentation(
        project: Project,
        progressCallback: ((String, Int, Int) -> Void)? = nil
    ) async throws -> Project {
        isLoading = true
        defer { isLoading = false }
        
        Logger.shared.info("Starting presentation generation workflow", category: .business)
        
        do {
            // Step 1: Analyze content
            progressCallback?("Analyzing content...", 0, 100)
            let analysisResult = try await analyzeContent(project: project)
            progressCallback?("Content analyzed", 25, 100)
            
            // Step 2: Generate slides
            progressCallback?("Generating slides...", 25, 100)
            let slides = try await generateSlides(
                project: project,
                analysisResult: analysisResult,
                progressCallback: { current, total in
                    let progress = 25 + (50 * current / total)
                    progressCallback?("Generating slides", progress, 100)
                }
            )
            progressCallback?("Slides generated", 75, 100)
            
            // Step 3: Update project
            var updatedProject = project
            updatedProject.slides = slides
            try await updateProject(updatedProject)
            
            progressCallback?("Presentation ready", 100, 100)
            Logger.shared.info("Presentation generation completed", category: .business)
            
            return updatedProject
            
        } catch {
            let appError = error as? AppError ?? AppError.unknown(error.localizedDescription)
            lastError = appError
            Logger.shared.error("Presentation generation failed", error: error, category: .business)
            throw appError
        }
    }
    
    // MARK: - Export
    
    /// Exports project to PowerPoint
    func exportToPowerPoint(
        project: Project,
        to url: URL,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws {
        guard !project.slides.isEmpty else {
            throw AppError.insufficientContent
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await powerPointExporter.exportPresentation(
                slides: project.slides,
                title: project.name,
                to: url,
                progressCallback: progressCallback
            )
            
            Logger.shared.info("Exported to PowerPoint: \(url.path)", category: .business)
            
        } catch {
            let appError = error as? AppError ?? AppError.exportError(error)
            lastError = appError
            Logger.shared.error("PowerPoint export failed", error: error, category: .business)
            throw appError
        }
    }
}
