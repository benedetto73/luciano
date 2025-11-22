//
//  FileImportView.swift
//  PresentationGenerator
//
//  View for importing source files into a project
//

import SwiftUI
import UniformTypeIdentifiers

struct FileImportView: View {
    @StateObject var viewModel: FileImportViewModel
    @State private var isTargeted = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Drop Zone
                    dropZoneView
                    
                    // Imported Files List
                    if !viewModel.importedFiles.isEmpty {
                        importedFilesSection
                    }
                }
                .padding(40)
            }
            
            Divider()
            
            // Footer with action buttons
            footerView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Import Content")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add source documents to generate slides from")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Drop Zone View
    
    private var dropZoneView: some View {
        VStack(spacing: 16) {
            Image(systemName: isTargeted ? "arrow.down.doc.fill" : "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundColor(isTargeted ? .accentColor : .secondary)
            
            Text("Drag and drop files here")
                .font(.headline)
            
            Text("or")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.selectFiles()
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Browse Files")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
            
            Text("Supported formats: .txt, .doc, .docx")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.gray.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            _ = viewModel.handleDrop(providers: providers)
            return true
        }
    }
    
    // MARK: - Imported Files Section
    
    private var importedFilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Imported Files")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.importedFiles.count) file\(viewModel.importedFiles.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.importedFiles) { file in
                    FilePreviewView(
                        file: file,
                        onRemove: {
                            viewModel.removeFile(file)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        HStack {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("Processing files...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Proceed to Analysis") {
                viewModel.proceedToAnalysis()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.importedFiles.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#if DEBUG
struct FileImportView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DependencyContainer()
        let coordinator = container.appCoordinator
        
        // Create a mock project
        let project = Project(
            id: UUID(),
            name: "Test Project",
            audience: .kids,
            createdDate: Date(),
            modifiedDate: Date(),
            sourceFiles: [],
            keyPoints: [],
            slides: [],
            settings: ProjectSettings()
        )
        
        let viewModel = FileImportViewModel(
            project: project,
            projectManager: container.projectManager,
            fileRepository: container.fileRepository,
            documentParser: DocumentParser(),
            coordinator: coordinator
        )
        
        FileImportView(viewModel: viewModel)
            .frame(width: 800, height: 600)
    }
}
#endif
