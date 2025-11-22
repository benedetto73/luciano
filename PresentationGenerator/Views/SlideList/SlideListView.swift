//
//  SlideListView.swift
//  PresentationGenerator
//
//  View for browsing and managing slides
//

import SwiftUI

struct SlideListView: View {
    @StateObject var viewModel: SlideListViewModel
    @State private var showingDeleteAlert = false
    @State private var slideToDelete: IndexSet?
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if viewModel.slides.isEmpty {
                emptyStateView
            } else {
                slidesList
            }
        }
        .navigationTitle("Slides")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { Task { await viewModel.loadProject() } }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
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
        .alert("Delete Slide", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                slideToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let offsets = slideToDelete {
                    Task {
                        await viewModel.deleteSlides(at: offsets)
                    }
                }
                slideToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this slide?")
        }
    }
    
    // MARK: - Components
    
    private var slidesList: some View {
        List {
            ForEach(viewModel.slides) { slide in
                SlideRowView(slide: slide)
                    .onTapGesture {
                        viewModel.selectSlide(slide)
                    }
            }
            .onMove { source, destination in
                Task {
                    await viewModel.moveSlides(from: source, to: destination)
                }
            }
            .onDelete { offsets in
                slideToDelete = offsets
                showingDeleteAlert = true
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Slides")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Generate slides from your content to see them here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SlideRowView: View {
    let slide: Slide
    
    var body: some View {
        HStack(spacing: 12) {
            // Slide thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 60)
                
                Text("\(slide.slideNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(slide.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(layoutDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(slide.content.prefix(50) + "...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var layoutDescription: String {
        if slide.imageData != nil {
            return "With Image"
        } else {
            return "Text Only"
        }
    }
}
