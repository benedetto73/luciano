//
//  ContentAnalysisView.swift
//  PresentationGenerator
//
//  View for displaying and editing content analysis results
//

import SwiftUI

struct ContentAnalysisView: View {
    @StateObject var viewModel: ContentAnalysisViewModel
    @State private var showingDeleteAlert = false
    @State private var indexToDelete: IndexSet?
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Analyzing content...")
                    .padding()
            } else if viewModel.keyPoints.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("Content Analysis")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Task {
                        await viewModel.addKeyPoint()
                    }
                }) {
                    Label("Add Point", systemImage: "plus")
                }
                .disabled(viewModel.isLoading)
            }
            
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
        .alert("Delete Key Point", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                indexToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let offsets = indexToDelete {
                    Task {
                        await viewModel.deleteKeyPoint(at: offsets)
                    }
                }
                indexToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this key point?")
        }
    }
    
    // MARK: - Components
    
    private var contentView: some View {
        VStack(spacing: 16) {
            // Key points list
            List {
                Section {
                    ForEach(Array(viewModel.keyPoints.enumerated()), id: \.offset) { index, point in
                        if viewModel.editingIndex == index {
                            editingRow(index: index)
                        } else {
                            keyPointRow(point: point, index: index)
                        }
                    }
                    .onMove { source, destination in
                        Task {
                            await viewModel.moveKeyPoints(from: source, to: destination)
                        }
                    }
                    .onDelete { offsets in
                        indexToDelete = offsets
                        showingDeleteAlert = true
                    }
                } header: {
                    HStack {
                        Text("Key Teaching Points")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.keyPoints.count) points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        viewModel.proceedToGeneration()
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Generate Slides from These Points")
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                } footer: {
                    Text("This will create approximately \(viewModel.suggestedSlideCount) slides based on your key points.")
                        .font(.caption)
                }
            }
        }
    }
    
    private func keyPointRow(point: KeyPoint, index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(point.content)
                .font(.body)
            
            Spacer()
            
            Button(action: {
                viewModel.startEditing(at: index)
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func editingRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $viewModel.editingText)
                .frame(minHeight: 60)
                .padding(4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            
            HStack {
                Button("Cancel") {
                    viewModel.cancelEdit()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Save") {
                    Task {
                        await viewModel.saveEdit()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Analysis Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Import content files and run analysis to extract key teaching points")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: viewModel.close) {
                Label("Go Back", systemImage: "arrow.left")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
