//
//  ContentImportViewModel.swift
//  PresentationGenerator
//
//  ViewModel for importing content files
//

import Foundation
import UniformTypeIdentifiers

@MainActor
class ContentImportViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let fileRepository: FileRepositoryProtocol
    private let appCoordinator: AppCoordinator
    let projectID: UUID
    
    @Published var project: Project?
    @Published var sourceFiles: [SourceFile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFileURLs: [URL] = []
    
    init(
        projectID: UUID,
        projectManager: ProjectManager,
        fileRepository: FileRepositoryProtocol,
        appCoordinator: AppCoordinator
    ) {
        self.projectID = projectID
        self.projectManager = projectManager
        self.fileRepository = fileRepository
        self.appCoordinator = appCoordinator
    }
    
    // MARK: - Lifecycle
    
    func loadProject() async {
        isLoading = true
        errorMessage = nil
        
        do {
            project = try await projectManager.loadProject(id: projectID)
            sourceFiles = project?.sourceFiles ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - File Import
    
    func importFiles(urls: [URL]) async {
        guard let project = project else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var updatedProject = project
            
            for url in urls {
                // Determine file type
                let fileType: DocumentType
                let ext = url.pathExtension.lowercased()
                
                switch ext {
                case "doc":
                    fileType = .doc
                case "docx":
                    fileType = .docx
                case "txt", "md":
                    fileType = .txt
                case "rtf":
                    fileType = .rtf
                default:
                    fileType = .txt
                }
                
                // Read file content
                let content: String
                if let fileContent = try? String(contentsOf: url, encoding: .utf8) {
                    content = fileContent
                } else {
                    content = ""
                }
                
                // Get file size
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                // Create source file entry
                let sourceFile = SourceFile(
                    id: UUID(),
                    filename: url.lastPathComponent,
                    content: content,
                    fileSize: fileSize,
                    importedDate: Date(),
                    fileType: fileType
                )
                
                updatedProject.sourceFiles.append(sourceFile)
            }
            
            // Update project
            try await projectManager.updateProject(updatedProject)
            
            // Reload
            await loadProject()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func removeFile(at offsets: IndexSet) async {
        guard var project = project else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Remove from project
            project.sourceFiles.remove(atOffsets: offsets)
            
            // Update project
            try await projectManager.updateProject(project)
            
            // Reload
            await loadProject()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func close() {
        appCoordinator.pop()
    }
}
