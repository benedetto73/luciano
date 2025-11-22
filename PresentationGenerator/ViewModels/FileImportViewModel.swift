//
//  FileImportViewModel.swift
//  PresentationGenerator
//
//  ViewModel for file import functionality
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FileImportViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var importedFiles: [SourceFile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    private let project: Project
    private let projectManager: ProjectManager
    private let fileRepository: FileRepositoryProtocol
    private let documentParser: DocumentParser
    private let coordinator: AppCoordinator
    
    // MARK: - Initialization
    init(
        project: Project,
        projectManager: ProjectManager,
        fileRepository: FileRepositoryProtocol,
        documentParser: DocumentParser,
        coordinator: AppCoordinator
    ) {
        self.project = project
        self.projectManager = projectManager
        self.fileRepository = fileRepository
        self.documentParser = documentParser
        self.coordinator = coordinator
        
        // Load existing files from project
        self.importedFiles = project.sourceFiles
    }
    
    // MARK: - Public Methods
    
    /// Handle file selection via file picker
    func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .plainText,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "docx") ?? .data
        ]
        
        panel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK {
                Task {
                    await self.importFiles(urls: panel.urls)
                }
            }
        }
    }
    
    /// Handle drag and drop
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        isLoading = true
        
        Task {
            var urls: [URL] = []
            
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    do {
                        if let url = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? URL {
                            urls.append(url)
                        }
                    } catch {
                        Logger.shared.error("Failed to load dropped item", error: error)
                    }
                }
            }
            
            if !urls.isEmpty {
                await importFiles(urls: urls)
            } else {
                isLoading = false
            }
        }
        
        return true
    }
    
    /// Import files from URLs
    private func importFiles(urls: [URL]) async {
        isLoading = true
        errorMessage = nil
        
        var successCount = 0
        var failedFiles: [String] = []
        
        for url in urls {
            do {
                // Validate file type
                guard isValidFileType(url) else {
                    failedFiles.append("\(url.lastPathComponent) (unsupported format)")
                    continue
                }
                
                // Parse document
                let content = try await documentParser.parse(url)
                
                // Get file attributes
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                // Create SourceFile
                let sourceFile = SourceFile(
                    id: UUID(),
                    filename: url.lastPathComponent,
                    content: content,
                    fileSize: fileSize,
                    importedDate: Date(),
                    fileType: getFileType(from: url)
                )
                
                // Add to imported files
                importedFiles.append(sourceFile)
                successCount += 1
                
                Logger.shared.info("Successfully imported file: \(url.lastPathComponent)")
                
            } catch {
                failedFiles.append(url.lastPathComponent)
                Logger.shared.error("Failed to import file: \(url.lastPathComponent)", error: error)
            }
        }
        
        // Update project with imported files
        if successCount > 0 {
            await updateProjectFiles()
        }
        
        // Show error if any files failed
        if !failedFiles.isEmpty {
            errorMessage = "Failed to import \(failedFiles.count) file(s):\n" + failedFiles.joined(separator: "\n")
            showError = true
        }
        
        isLoading = false
    }
    
    /// Remove a file from the import list
    func removeFile(_ file: SourceFile) {
        importedFiles.removeAll { $0.id == file.id }
        
        Task {
            await updateProjectFiles()
        }
    }
    
    /// Proceed to content analysis
    func proceedToAnalysis() {
        guard !importedFiles.isEmpty else {
            errorMessage = "Please import at least one file before proceeding."
            showError = true
            return
        }
        
        coordinator.navigate(to: .contentAnalysis(project.id))
    }
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Private Methods
    
    /// Update project with current imported files
    private func updateProjectFiles() async {
        do {
            var updatedProject = project
            updatedProject.sourceFiles = importedFiles
            updatedProject.modifiedDate = Date()
            
            try await projectManager.updateProject(updatedProject)
            
        } catch {
            errorMessage = "Failed to update project: \(error.localizedDescription)"
            showError = true
            Logger.shared.error("Failed to update project files", error: error)
        }
    }
    
    /// Validate if file type is supported
    private func isValidFileType(_ url: URL) -> Bool {
        let validExtensions = ["txt", "doc", "docx"]
        let fileExtension = url.pathExtension.lowercased()
        return validExtensions.contains(fileExtension)
    }
    
    /// Get file type from URL
    private func getFileType(from url: URL) -> DocumentType {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "doc":
            return .doc
        case "docx":
            return .docx
        case "rtf":
            return .rtf
        case "txt":
            return .txt
        default:
            return .txt
        }
    }
}
