//
//  ExportViewModel.swift
//  PresentationGenerator
//
//  ViewModel for exporting presentations
//

import Foundation
import AppKit

@MainActor
class ExportViewModel: ObservableObject {
    private let projectManager: ProjectManager
    private let appCoordinator: AppCoordinator
    let projectID: UUID
    
    @Published var project: Project?
    @Published var isLoading = false
    @Published var isExporting = false
    @Published var errorMessage: String?
    @Published var exportProgress: String = ""
    @Published var exportPercentage: Int = 0
    @Published var exportedFileURL: URL?
    
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
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Export
    
    func exportPresentation() async {
        guard let project = project else { return }
        
        isExporting = true
        errorMessage = nil
        exportProgress = "Preparing export..."
        exportPercentage = 0
        
        do {
            // Create export URL in downloads folder
            let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let fileName = "\(project.name).pptx"
            let fileURL = downloads.appendingPathComponent(fileName)
            
            try await projectManager.exportToPowerPoint(
                project: project,
                to: fileURL,
                progressCallback: { current, total in
                    if total > 0 {
                        self.exportPercentage = Int((Double(current) / Double(total)) * 100)
                        self.exportProgress = "Exporting slide \(current) of \(total)..."
                    }
                }
            )
            
            exportedFileURL = fileURL
            exportProgress = "Export complete!"
            exportPercentage = 100
            
        } catch {
            errorMessage = error.localizedDescription
            exportProgress = ""
            exportPercentage = 0
        }
        
        isExporting = false
    }
    
    func revealInFinder() {
        guard let url = exportedFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    func shareFile() {
        guard let url = exportedFileURL else { return }
        let picker = NSSharingServicePicker(items: [url])
        
        // Show share menu (macOS)
        if let window = NSApplication.shared.keyWindow {
            picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
    
    func close() {
        appCoordinator.pop()
    }
}
