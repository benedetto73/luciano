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
            .navigationTitle("My Presentations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.createNewProject) {
                        Label("New Project", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: viewModel.openSettings) {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search projects")
            .task {
                await viewModel.loadProjects()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Delete Project", isPresented: $showingDeleteAlert, presenting: projectToDelete) { project in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteProject(project)
                    }
                }
            } message: { project in
                Text("Are you sure you want to delete '\(project.name)'? This action cannot be undone.")
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
    }
    
    // MARK: - Components
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Presentations Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first presentation to get started")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: viewModel.createNewProject) {
                Label("Create Presentation", systemImage: "plus.circle.fill")
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
                            Label("Delete", systemImage: "trash")
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
