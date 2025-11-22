//
//  WorkspaceView.swift
//  PresentationGenerator
//
//  Modern workspace with sidebar, status bar, and central playground
//

import SwiftUI

struct WorkspaceView: View {
    @StateObject var viewModel: ProjectDetailViewModel
    @State private var sidebarCollapsed = false
    @State private var windowWidth: CGFloat = 1200
    @State private var showShortcutsOverlay = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top status bar
                StatusTileBar(viewModel: viewModel)
                    .frame(height: 60)
                
                // Main content area
                HStack(spacing: 0) {
                    // Left sidebar
                    PhaseNavigationSidebar(
                        viewModel: viewModel,
                        collapsed: geometry.size.width < 900 || sidebarCollapsed
                    )
                    .frame(width: (geometry.size.width < 900 || sidebarCollapsed) ? 72 : 200)
                    
                    Divider()
                    
                    // Central playground
                    PlaygroundContainer(viewModel: viewModel)
                }
            }
            .onChange(of: geometry.size.width) { newWidth in
                windowWidth = newWidth
            }
        }
        .overlay {
            if showShortcutsOverlay {
                KeyboardShortcutsOverlay(isPresented: $showShortcutsOverlay)
            }
        }
        .overlay {
            if viewModel.isAnalyzing {
                LoadingOverlayView(
                    title: "Analyzing Content",
                    message: viewModel.analysisProgress,
                    progress: viewModel.analysisPercentage,
                    onCancel: { viewModel.cancelAnalysis() }
                )
            }
            
            if viewModel.isGenerating {
                LoadingOverlayView(
                    title: "Generating Slides",
                    message: viewModel.generationProgress,
                    progress: Double(viewModel.generationPercentage),
                    onCancel: { viewModel.cancelGeneration() }
                )
            }
            
            if viewModel.showError {
                ErrorOverlayView(
                    title: viewModel.errorTitle,
                    message: viewModel.errorMessage ?? "An error occurred",
                    onRetry: { viewModel.retryLastOperation() },
                    onDismiss: { viewModel.dismissError() }
                )
            }
        }
        .task {
            await viewModel.loadProject()
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.contains(.command) else { return event }
            
            switch event.charactersIgnoringModifiers {
            case "1": viewModel.selectedPhase = .importPhase; return nil
            case "2": viewModel.selectedPhase = .analyze; return nil
            case "3": viewModel.selectedPhase = .generate; return nil
            case "4": viewModel.selectedPhase = .edit; return nil
            case "5": viewModel.selectedPhase = .preview; return nil
            case "6": viewModel.selectedPhase = .exportPhase; return nil
            case "i": viewModel.selectedPhase = .importPhase; return nil
            case "g": 
                if viewModel.canGenerate {
                    Task { await viewModel.generateSlides() }
                }
                return nil
            case "e": viewModel.selectedPhase = .exportPhase; return nil
            case "/": showShortcutsOverlay.toggle(); return nil
            default: return event
            }
        }
    }
}

// MARK: - Keyboard Shortcuts Overlay

struct KeyboardShortcutsOverlay: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 24) {
                HStack {
                    Text("Keyboard Shortcuts")
                        .font(.title2)
                        .bold()
                    
                    Spacer()
                    
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(spacing: 16) {
                    ShortcutRow(key: "⌘ 1-6", description: "Switch between phases")
                    ShortcutRow(key: "⌘ N", description: "New project")
                    ShortcutRow(key: "⌘ I", description: "Go to Import phase")
                    ShortcutRow(key: "⌘ G", description: "Generate slides")
                    ShortcutRow(key: "⌘ E", description: "Go to Export phase")
                    ShortcutRow(key: "⌘ ,", description: "Settings")
                    ShortcutRow(key: "⌘ /", description: "Show shortcuts")
                }
                
                Text("Press ESC or click outside to close")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .frame(width: 500)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct ShortcutRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                )
            
            Text(description)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
