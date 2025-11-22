//
//  SlideOverviewView.swift
//  PresentationGenerator
//
//  Overview screen showing all slides in the presentation
//

import SwiftUI

struct SlideOverviewView: View {
    @StateObject var viewModel: SlideOverviewViewModel
    @State private var selectedSlideId: UUID?
    @State private var showDeleteAlert = false
    @State private var slideToDelete: Slide?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            if viewModel.slides.isEmpty {
                emptyStateView
            } else {
                slideGridView
            }
            
            Divider()
            
            // Footer
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
        .alert("Delete Slide", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                slideToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let slide = slideToDelete {
                    viewModel.deleteSlide(slide)
                }
                slideToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this slide? This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showExportProgress) {
            ExportProgressView(viewModel: viewModel)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Slide Overview")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(viewModel.slides.count) slide\(viewModel.slides.count == 1 ? "" : "s") • \(viewModel.project.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Add Slide Button
            Button(action: {
                viewModel.addSlide()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Slide")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Slide Grid View
    
    private var slideGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 220, maximum: 250), spacing: 24)
                ],
                spacing: 24
            ) {
                ForEach(viewModel.slides) { slide in
                    slideCard(slide: slide)
                }
            }
            .padding(32)
        }
    }
    
    // MARK: - Slide Card
    
    @ViewBuilder
    private func slideCard(slide: Slide) -> some View {
        VStack(spacing: 0) {
            // Thumbnail
            if let designSpec = viewModel.designSpec {
                SlideThumbnailView(
                    slide: slide,
                    designSpec: designSpec,
                    isSelected: selectedSlideId == slide.id,
                    onTap: {
                        selectedSlideId = slide.id
                    }
                )
            } else {
                ProgressView()
                    .frame(height: 150)
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                // Edit Button
                Button(action: {
                    viewModel.editSlide(slide)
                }) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Delete Button
                Button(action: {
                    slideToDelete = slide
                    showDeleteAlert = true
                }) {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
            .padding(.top, 8)
        }
        .contextMenu {
            Button("Edit Slide") {
                viewModel.editSlide(slide)
            }
            
            Button("Duplicate Slide") {
                viewModel.duplicateSlide(slide)
            }
            
            Divider()
            
            Button("Delete Slide", role: .destructive) {
                slideToDelete = slide
                showDeleteAlert = true
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Slides Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first slide to get started")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.addSlide()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Slide")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        HStack {
            // Slide count
            Text("\(viewModel.slides.count) slide\(viewModel.slides.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Export Button
            Button(action: {
                viewModel.exportToPowerPoint()
            }) {
                HStack {
                    if viewModel.isExporting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text("Export to PowerPoint")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.slides.isEmpty || viewModel.isExporting)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#if DEBUG
struct SlideOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        Text("SlideOverviewView Preview")
            .frame(width: 1000, height: 700)
    }
}
#endif
