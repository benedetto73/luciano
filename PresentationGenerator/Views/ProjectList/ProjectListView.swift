//
//  ProjectListView.swift
//  PresentationGenerator
//
//  Main project list screen
//

import SwiftUI

struct ProjectListView: View {
    @StateObject var viewModel: ProjectListViewModel
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: Project?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    projectList
                }
                
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("projectList.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.createNewProject) {
                        Label("projectList.newProject".localized, systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: viewModel.openSettings) {
                        Label("projectList.settings".localized, systemImage: "gear")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: Text("projectList.search".localized))
            .task {
                await viewModel.loadProjects()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("projectList.deleteConfirm.title".localized, isPresented: $showingDeleteAlert, presenting: projectToDelete) { project in
                Button("cancel".localized, role: .cancel) {}
                Button("delete".localized, role: .destructive) {
                    Task {
                        await viewModel.deleteProject(project)
                    }
                }
            } message: { project in
                Text(String(format: "projectList.deleteConfirm.message".localized, project.name))
            }
            .alert("error".localized, isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("ok".localized) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("projectList.empty.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("projectList.empty.message".localized)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: viewModel.createNewProject) {
                Label("projectList.empty.button".localized, systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    private var projectList: some View {
        List {
            ForEach(viewModel.filteredProjects) { project in
                ProjectRowView(project: project)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.openProject(project)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            projectToDelete = project
                            showingDeleteAlert = true
                        } label: {
                            Label("delete".localized, systemImage: "trash")
                        }
                    }
            }
        }
    }
}

// MARK: - Project Row

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.headline)
                
                Spacer()
                
                if !project.slides.isEmpty {
                    Text("\(project.slides.count) slides")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label(project.audience.rawValue, systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(project.modifiedDate, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !project.sourceFiles.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text("\(project.sourceFiles.count) source files")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
