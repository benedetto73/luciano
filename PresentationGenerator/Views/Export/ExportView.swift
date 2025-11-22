//
//  ExportView.swift
//  PresentationGenerator
//
//  View for exporting presentations to PowerPoint
//

import SwiftUI

struct ExportView: View {
    @StateObject var viewModel: ExportViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if let project = viewModel.project {
                exportContent(project)
            } else {
                Text("Project not found")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle("Export Presentation")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    viewModel.close()
                }
            }
        }
        .task {
            await viewModel.loadProject()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Components
    
    private func exportContent(_ project: Project) -> some View {
        VStack(spacing: 24) {
            // Project info
            VStack(spacing: 8) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text(project.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(project.slides.count) slides")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Export status
            if viewModel.isExporting {
                VStack(spacing: 12) {
                    ProgressView(value: Double(viewModel.exportPercentage), total: 100)
                    
                    Text(viewModel.exportProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if viewModel.exportedFileURL != nil {
                // Export complete
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Export Complete!")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Button(action: viewModel.revealInFinder) {
                            Label("Show in Finder", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: viewModel.shareFile) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            } else {
                // Ready to export
                VStack(spacing: 16) {
                    Text("Export Options")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.accentColor)
                            Text("Format:")
                            Spacer()
                            Text("PowerPoint (.pptx)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.accentColor)
                            Text("Resolution:")
                            Spacer()
                            Text("1920 × 1080")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.accentColor)
                            Text("Theme:")
                            Spacer()
                            Text("Default")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button(action: {
                        Task {
                            await viewModel.exportPresentation()
                        }
                    }) {
                        Label("Export to PowerPoint", systemImage: "arrow.down.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(project.slides.isEmpty)
                    
                    if project.slides.isEmpty {
                        Text("Generate slides before exporting")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
}
