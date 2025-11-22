//
//  PlaygroundContainer.swift
//  PresentationGenerator
//
//  Central content area that switches based on selected phase
//

import SwiftUI

struct PlaygroundContainer: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        Group {
            if viewModel.project == nil {
                // Welcome/empty state
                WelcomePlayground(viewModel: viewModel)
            } else {
                // Phase-specific content
                phaseContent
                    .id(viewModel.selectedPhase) // Force recreation on phase change
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedPhase)
    }
    
    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.selectedPhase {
        case .importPhase:
            ImportPlayground(viewModel: viewModel)
        case .analyze:
            AnalyzePlayground(viewModel: viewModel)
        case .generate:
            GeneratePlayground(viewModel: viewModel)
        case .edit:
            EditPlayground(viewModel: viewModel)
        case .preview:
            PreviewPlayground(viewModel: viewModel)
        case .exportPhase:
            ExportPlayground(viewModel: viewModel)
        }
    }
}

// MARK: - Welcome Playground

struct WelcomePlayground: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Illustration
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 12) {
                Text("workspace.welcome.title".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("workspace.welcome.subtitle".localized)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Button {
                viewModel.selectedPhase = .importPhase
            } label: {
                Label("workspace.welcome.button".localized, systemImage: "doc.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Import Playground

struct ImportPlayground: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    @State private var isDragging = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                PlaygroundHeader(
                    title: "import.title".localized,
                    subtitle: "import.subtitle".localized,
                    icon: "doc.badge.plus"
                )
                
                // File drop zone or file list
                if viewModel.sourceFileCount == 0 {
                    // Drop zone
                    VStack(spacing: 20) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(isDragging ? .accentColor : .secondary)
                        
                        VStack(spacing: 8) {
                            Text("import.dropZone.title".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("import.dropZone.subtitle".localized)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("import.dropZone.formats".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .playgroundCard()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                            )
                            .foregroundColor(isDragging ? .accentColor : .secondary.opacity(0.3))
                    )
                    .onTapGesture {
                        viewModel.importContent()
                    }
                    .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                        handleFileDrop(providers: providers)
                        return true
                    }
                } else {
                    // File list
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(viewModel.sourceFileCount) Files")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                viewModel.showingFilePicker = true
                            } label: {
                                Label("Add More", systemImage: "plus")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Placeholder for file list
                        ForEach(0..<viewModel.sourceFileCount, id: \.self) { index in
                            HStack(spacing: 12) {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.blue)
                                
                                Text("Document \(index + 1)")
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding()
                            .playgroundCard()
                        }
                    }
                }
                
                // Next step
                if viewModel.canAnalyze {
                    HStack {
                        Spacer()
                        
                        Button {
                            withAnimation(.spring()) {
                                viewModel.selectedPhase = .analyze
                            }
                        } label: {
                            Label("Next: Analyze Content", systemImage: "arrow.right")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .padding(32)
        }
        .fileImporter(
            isPresented: $viewModel.showingFilePicker,
            allowedContentTypes: [
                .pdf,
                .plainText,
                .text,
                .png,
                .jpeg,
                .rtf,
                .commaSeparatedText
            ],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await viewModel.importFiles(urls)
                }
            case .failure(let error):
                viewModel.errorTitle = "Import Error"
                viewModel.errorMessage = error.localizedDescription
                viewModel.showError = true
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            handleFileDrop(providers: providers)
            return true
        }
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                Task { @MainActor in
                    if let urlData = urlData as? Data,
                       let path = String(data: urlData, encoding: .utf8),
                       let url = URL(string: path) {
                        await viewModel.importFiles([url])
                    }
                }
            }
        }
    }
}

// MARK: - Analyze Playground

struct AnalyzePlayground: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaygroundHeader(
                    title: "Analyze Content",
                    subtitle: "Extract and edit key teaching points",
                    icon: "sparkles"
                )
                
                // Analysis state
                if viewModel.project?.keyPoints.isEmpty ?? true {
                    // Not analyzed yet
                    VStack(spacing: 24) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        VStack(spacing: 8) {
                            Text("Ready to analyze")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("AI will extract key teaching points from your files")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button {
                            Task {
                                await viewModel.analyzeContent()
                            }
                        } label: {
                            Label("Analyze Content", systemImage: "sparkles")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!viewModel.canAnalyze)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .playgroundCard()
                } else {
                    // Key points list
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("\(viewModel.project?.keyPoints.count ?? 0) Key Points")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await viewModel.analyzeContent()
                                }
                            } label: {
                                Label("Re-analyze", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if let keyPoints = viewModel.project?.keyPoints {
                            ForEach(Array(keyPoints.enumerated()), id: \.element.id) { index, keyPoint in
                                EditableKeyPointCard(
                                    keyPoint: keyPoint,
                                    index: index,
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                    
                    // Next step
                    HStack {
                        Spacer()
                        
                        Button {
                            withAnimation(.spring()) {
                                viewModel.selectedPhase = .generate
                            }
                        } label: {
                            Label("Next: Generate Slides", systemImage: "arrow.right")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Generate Playground

struct GeneratePlayground: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaygroundHeader(
                    title: "Generate Slides",
                    subtitle: "AI creates presentation slides from key points",
                    icon: "wand.and.stars"
                )
                
                if viewModel.slideCount == 0 {
                    // Ready to generate
                    VStack(spacing: 24) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 8) {
                            Text("Ready to generate slides")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Estimated: \(viewModel.project?.keyPoints.count ?? 0) slides")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            Task {
                                await viewModel.generateSlides()
                            }
                        } label: {
                            Label("Generate Slides", systemImage: "wand.and.stars")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!viewModel.canGenerate)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .playgroundCard()
                } else {
                    // Generation complete
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("Generation Complete!")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(viewModel.slideCount) slides created")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 16) {
                            Button {
                                withAnimation(.spring()) {
                                    viewModel.selectedPhase = .edit
                                }
                            } label: {
                                Label("Edit Slides", systemImage: "pencil")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            Button {
                                withAnimation(.spring()) {
                                    viewModel.selectedPhase = .preview
                                }
                            } label: {
                                Label("Preview", systemImage: "play.rectangle")
                                    .font(.headline)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .playgroundCard()
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Edit Playground

struct EditPlayground: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaygroundHeader(
                    title: "Edit Slides",
                    subtitle: "Customize your presentation slides",
                    icon: "pencil.and.list.clipboard"
                )
                
                if viewModel.slideCount > 0 {
                    // Slide grid
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 20)
                    ], spacing: 20) {
                        if let slides = viewModel.project?.slides {
                            ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                                SlideGridCard(slide: slide) {
                                    viewModel.appCoordinator.push(.slideEditor(projectID: viewModel.projectID, slideID: slide.id))
                                }
                            }
                        }
                    }
                    
                    // Next step
                    HStack {
                        Spacer()
                        
                        Button {
                            withAnimation(.spring()) {
                                viewModel.selectedPhase = .exportPhase
                            }
                        } label: {
                            Label("Next: Export", systemImage: "arrow.right")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else {
                    EmptyPhaseState(
                        icon: "rectangle.stack",
                        title: "No slides yet",
                        message: "Generate slides first",
                        actionTitle: "Go to Generate",
                        action: {
                            viewModel.selectedPhase = .generate
                        }
                    )
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Preview Playground

struct PreviewPlayground: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    @State private var currentSlideIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            HStack {
                PlaygroundHeader(
                    title: "Preview",
                    subtitle: "Review your presentation",
                    icon: "play.rectangle"
                )
                
                Spacer()
                
                // Slide counter
                if viewModel.slideCount > 0 {
                    Text("\(currentSlideIndex + 1) / \(viewModel.slideCount)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(32)
            
            if viewModel.slideCount > 0 {
                // Slide preview area
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    if let slide = viewModel.project?.slides[safe: currentSlideIndex] {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(slide.title)
                                .font(.system(size: 36, weight: .bold))
                            
                            Text(slide.content)
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(40)
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)
                .padding(.horizontal, 60)
                
                // Navigation controls
                HStack(spacing: 20) {
                    Button {
                        if currentSlideIndex > 0 {
                            withAnimation(.spring()) {
                                currentSlideIndex -= 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 40))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentSlideIndex == 0)
                    
                    Button {
                        if currentSlideIndex < viewModel.slideCount - 1 {
                            withAnimation(.spring()) {
                                currentSlideIndex += 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 40))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentSlideIndex >= viewModel.slideCount - 1)
                }
                .padding(.vertical, 32)
            } else {
                Spacer()
                
                EmptyPhaseState(
                    icon: "play.rectangle",
                    title: "No slides to preview",
                    message: "Generate slides first",
                    actionTitle: "Go to Generate",
                    action: {
                        viewModel.selectedPhase = .generate
                    }
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - Export Playground

struct ExportPlayground: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlaygroundHeader(
                    title: "Export",
                    subtitle: "Export your presentation to PowerPoint",
                    icon: "square.and.arrow.down"
                )
                
                if viewModel.canExport {
                    VStack(spacing: 24) {
                        Image(systemName: "doc.richtext")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("Ready to export")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Export as PowerPoint (.pptx)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "rectangle.ratio.16.to.9")
                                Text("Format: 16:9 (1920 × 1080)")
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "rectangle.stack")
                                Text("Slides: \(viewModel.slideCount)")
                                Spacer()
                            }
                        }
                        .padding()
                        .playgroundCard()
                        
                        Button {
                            viewModel.exportPresentation()
                        } label: {
                            Label("Export to PowerPoint", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .playgroundCard()
                } else {
                    EmptyPhaseState(
                        icon: "square.and.arrow.down",
                        title: "Not ready to export",
                        message: "Generate slides first",
                        actionTitle: "Go to Generate",
                        action: {
                            viewModel.selectedPhase = .generate
                        }
                    )
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Helper Components

struct PlaygroundHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.linearGradient(
                    colors: [.accentColor, .accentColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyPhaseState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .playgroundCard()
    }
}

// MARK: - Editable Key Point Card

struct EditableKeyPointCard: View {
    let keyPoint: KeyPoint
    let index: Int
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    @State private var isHovered = false
    @FocusState private var isFocused: Bool
    
    private var isEditing: Bool {
        viewModel.editingKeyPointId == keyPoint.id
    }
    
    private var characterCount: Int {
        viewModel.editingKeyPointText.count
    }
    
    private var isValid: Bool {
        let count = viewModel.editingKeyPointText.trimmingCharacters(in: .whitespacesAndNewlines).count
        return count >= 10 && count <= 500
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Key Point \(index + 1)")
                    .font(.headline)
                
                Spacer()
                
                if isEditing {
                    HStack(spacing: 8) {
                        Button("Cancel") {
                            viewModel.cancelKeyPointEdit()
                        }
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.escape, modifiers: [])
                        
                        Button("Save") {
                            Task {
                                await viewModel.saveKeyPointEdit()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValid)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    .controlSize(.small)
                } else if isHovered {
                    Button {
                        viewModel.startEditingKeyPoint(id: keyPoint.id)
                        isFocused = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Edit key point")
                }
            }
            
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $viewModel.editingKeyPointText)
                        .font(.body)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    isValid ? Color.accentColor : Color.red,
                                    lineWidth: 2
                                )
                        )
                        .focused($isFocused)
                        .onChange(of: viewModel.editingKeyPointText) { _ in
                            // Auto-save after 1 second of no typing
                            Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                await viewModel.autoSaveKeyPointEdit()
                            }
                        }
                    
                    HStack {
                        if !isValid {
                            Text(characterCount < 10 ? "Minimum 10 characters" : "Maximum 500 characters")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text("Auto-saving...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(characterCount) / 500")
                            .font(.caption)
                            .foregroundColor(isValid ? .secondary : .red)
                    }
                }
            } else {
                Text(keyPoint.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .playgroundCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isEditing ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .scaleEffect(isHovered && !isEditing ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditing)
        .onHover { hovering in
            if !isEditing {
                isHovered = hovering
            }
        }
    }
}

struct SlideGridCard: View {
    let slide: Slide
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Slide preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(slide.title)
                            .font(.caption)
                            .fontWeight(.bold)
                            .lineLimit(2)
                        
                        Text(slide.content)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(8)
                }
                .aspectRatio(16/9, contentMode: .fit)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Slide info
                Text(slide.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            .padding(12)
            .playgroundCard()
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
