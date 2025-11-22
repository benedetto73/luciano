//
//  SlideEditorView.swift
//  PresentationGenerator
//
//  View for editing individual slide content and design
//

import SwiftUI

struct SlideEditorView: View {
    @StateObject var viewModel: SlideEditorViewModel
    @State private var showingDeleteAlert = false
    @State private var showingDiscardAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Loading slide...")
                    .padding()
            } else if viewModel.slide == nil {
                errorStateView
            } else {
                editorContent
            }
        }
        .navigationTitle("Edit Slide")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                HStack(spacing: 8) {
                    Button {
                        viewModel.navigateToPreviousSlide()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!viewModel.canNavigateToPrevious)
                    
                    if let slideNumber = viewModel.slide?.slideNumber,
                       let totalSlides = viewModel.project?.slides.count {
                        Text("\(slideNumber) / \(totalSlides)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        viewModel.navigateToNextSlide()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!viewModel.canNavigateToNext)
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button(viewModel.hasUnsavedChanges ? "Cancel" : "Done") {
                    if viewModel.hasUnsavedChanges {
                        showingDiscardAlert = true
                    } else {
                        viewModel.close()
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    Task {
                        await viewModel.saveChanges()
                    }
                }
                .disabled(!viewModel.hasUnsavedChanges || viewModel.isSaving)
            }
        }
        .task {
            await viewModel.loadSlide()
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
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Discard", role: .destructive) {
                viewModel.close()
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .alert("Delete Slide?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteSlide()
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Components
    
    private var editorContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Slide info header
                slideInfoSection
                
                // Title editor
                titleSection
                
                // Content editor
                contentSection
                
                // Design options
                designSection
                
                // Image section
                imageSection
                
                // Speaker notes
                notesSection
                
                // Actions
                actionsSection
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
    
    private var slideInfoSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Slide Number")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.slide?.slideNumber ?? 0)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.hasUnsavedChanges ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(viewModel.hasUnsavedChanges ? "Modified" : "Saved")
                        .font(.subheadline)
                }
            }
            
            Spacer()
            
            if let successMessage = viewModel.successMessage {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)
            
            TextField("Slide title", text: $viewModel.title)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .onChange(of: viewModel.title) { _ in
                    viewModel.markAsChanged()
                }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Content")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.content.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextEditor(text: $viewModel.content)
                .font(.body)
                .frame(minHeight: 200)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: viewModel.content) { _ in
                    viewModel.markAsChanged()
                }
            
            Text("Use bullet points (•) or numbered lists for better readability")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var designSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Design")
                .font(.headline)
            
            if let design = viewModel.selectedDesign {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Layout: \(design.layout.rawValue)")
                            .font(.subheadline)
                        Text("Font: \(design.fontFamily) (\(design.fontSize.rawValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        viewModel.showingDesignPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            } else {
                Button("Select Design Theme") {
                    viewModel.showingDesignPicker = true
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image")
                .font(.headline)
            
            if viewModel.hasImage {
                HStack {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Image included")
                            .font(.subheadline)
                        Text("Generated from AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.removeImage()
                        }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            } else {
                Button {
                    Task {
                        await viewModel.generateImage()
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate AI Image for This Slide")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Speaker Notes")
                    .font(.headline)
                Spacer()
                if !viewModel.notes.isEmpty {
                    Text("\(viewModel.notes.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            TextEditor(text: $viewModel.notes)
                .font(.body)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: viewModel.notes) { _ in
                    viewModel.markAsChanged()
                }
            
            Text("Private notes for the presenter (not shown on slides)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Slide", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if viewModel.hasUnsavedChanges {
                    Button("Revert") {
                        viewModel.revertChanges()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private var errorStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Slide Not Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The slide you're trying to edit could not be found")
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
