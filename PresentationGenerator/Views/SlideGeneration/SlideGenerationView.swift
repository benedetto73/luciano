//
//  SlideGenerationView.swift
//  PresentationGenerator
//
//  View for slide generation progress
//

import SwiftUI

struct SlideGenerationView: View {
    @StateObject var viewModel: SlideGenerationViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isComplete {
                completionView
            } else if viewModel.isGenerating {
                progressView
            } else {
                readyView
            }
        }
        .padding()
        .navigationTitle("Generate Slides")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    viewModel.close()
                }
                .disabled(viewModel.isGenerating)
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
    
    private var readyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Ready to Generate Slides")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let project = viewModel.project {
                VStack(spacing: 12) {
                    infoRow(
                        label: "Key Points",
                        value: "\(project.keyPoints.count)",
                        icon: "list.bullet"
                    )
                    
                    infoRow(
                        label: "Target Audience",
                        value: project.audience.rawValue,
                        icon: "person.2"
                    )
                    
                    infoRow(
                        label: "Estimated Slides",
                        value: "\(min(max(project.keyPoints.count, 3), 20))",
                        icon: "rectangle.stack"
                    )
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button(action: {
                Task {
                    await viewModel.startGeneration()
                }
            }) {
                Label("Start Generation", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Text("This process uses AI to create slides with titles, content, and designs optimized for your audience.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var progressView: some View {
        VStack(spacing: 24) {
            // Animated icon
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Generating Slides")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: viewModel.progressPercentage) {
                    HStack {
                        Text(viewModel.progressText)
                            .font(.subheadline)
                        Spacer()
                        if viewModel.totalSlides > 0 {
                            Text("\(viewModel.currentSlide)/\(viewModel.totalSlides)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .progressViewStyle(.linear)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            
            // Status messages
            VStack(alignment: .leading, spacing: 8) {
                statusItem(
                    icon: "checkmark.circle.fill",
                    text: "Analyzing content structure",
                    isActive: true
                )
                statusItem(
                    icon: viewModel.currentSlide > 0 ? "checkmark.circle.fill" : "circle",
                    text: "Creating slide designs",
                    isActive: viewModel.currentSlide > 0
                )
                statusItem(
                    icon: viewModel.isComplete ? "checkmark.circle.fill" : "circle",
                    text: "Finalizing presentation",
                    isActive: viewModel.isComplete
                )
            }
            .padding()
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Generation Complete!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Successfully created \(viewModel.totalSlides) slides")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button(action: viewModel.viewSlides) {
                    HStack {
                        Image(systemName: "eye")
                        Text("View Slides")
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: viewModel.exportPresentation) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Export to PowerPoint")
                        Spacer()
                        Image(systemName: "arrow.right")
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
    
    private func infoRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func statusItem(icon: String, text: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isActive ? .green : .secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(isActive ? .primary : .secondary)
            Spacer()
        }
    }
}
