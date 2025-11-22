//
//  ProjectDetailView.swift
//  PresentationGenerator
//
//  Project detail screen with workflow steps
//

import SwiftUI

struct ProjectDetailView: View {
    @StateObject var viewModel: ProjectDetailViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let project = viewModel.project {
                    projectHeader(project)
                    workflowSection
                    statsSection(project)
                    actionsSection
                } else {
                    Text("Project not found")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.project?.name ?? "Project")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { Task { await viewModel.refresh() } }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadProject()
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProject()
                }
            }
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
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
    
    private func projectHeader(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(project.audience.rawValue, systemImage: "person.2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Modified \(project.modifiedDate, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workflow")
                .font(.headline)
            
            VStack(spacing: 12) {
                workflowStep(
                    number: 1,
                    title: "Import Content",
                    description: "\(viewModel.sourceFileCount) source files",
                    isComplete: viewModel.sourceFileCount > 0,
                    action: viewModel.importContent
                )
                
                workflowStep(
                    number: 2,
                    title: "Analyze Content",
                    description: "Extract key teaching points",
                    isComplete: viewModel.canGenerate,
                    isEnabled: viewModel.canAnalyze,
                    action: {
                        Task {
                            await viewModel.analyzeContent()
                        }
                    }
                )
                
                workflowStep(
                    number: 3,
                    title: "Generate Slides",
                    description: "\(viewModel.slideCount) slides created",
                    isComplete: viewModel.slideCount > 0,
                    isEnabled: viewModel.canGenerate,
                    action: {
                        Task {
                            await viewModel.generateSlides()
                        }
                    }
                )
                
                workflowStep(
                    number: 4,
                    title: "Export",
                    description: "Download PowerPoint file",
                    isComplete: false,
                    isEnabled: viewModel.canExport,
                    action: viewModel.exportPresentation
                )
            }
            
            if case .analyzing = viewModel.workflowState {
                ProgressView(value: Double(viewModel.generationPercentage), total: 100) {
                    Text(viewModel.generationProgress)
                        .font(.caption)
                }
                .padding(.top, 8)
            }
            
            if case .generating = viewModel.workflowState {
                ProgressView(value: Double(viewModel.generationPercentage), total: 100) {
                    Text(viewModel.generationProgress)
                        .font(.caption)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func workflowStep(
        number: Int,
        title: String,
        description: String,
        isComplete: Bool,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : Color.secondary.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                } else {
                    Text("\(number)")
                        .foregroundColor(isEnabled ? .primary : .secondary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(isEnabled ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.vertical, 4)
    }
    
    private func statsSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            HStack(spacing: 20) {
                statCard(
                    title: "Source Files",
                    value: "\(project.sourceFiles.count)",
                    icon: "doc.text"
                )
                
                statCard(
                    title: "Key Points",
                    value: "\(project.keyPoints.count)",
                    icon: "list.bullet"
                )
                
                statCard(
                    title: "Slides",
                    value: "\(project.slides.count)",
                    icon: "rectangle.stack"
                )
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if viewModel.slideCount > 0 {
                Button(action: viewModel.viewSlides) {
                    HStack {
                        Image(systemName: "eye")
                        Text("View & Edit Slides")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
