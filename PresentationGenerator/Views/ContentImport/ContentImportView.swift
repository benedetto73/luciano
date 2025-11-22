//
//  ContentImportView.swift
//  PresentationGenerator
//
//  View for importing source content files
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentImportView: View {
    @StateObject var viewModel: ContentImportViewModel
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else {
                fileListSection
            }
        }
        .navigationTitle("Import Content")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingFilePicker = true }) {
                    Label("Add Files", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    viewModel.close()
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .plainText, .image, .text],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await viewModel.importFiles(urls: urls)
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
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
    
    private var fileListSection: some View {
        Group {
            if viewModel.sourceFiles.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(viewModel.sourceFiles) { file in
                        FileRowView(file: file)
                    }
                    .onDelete { offsets in
                        Task {
                            await viewModel.removeFile(at: offsets)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Source Files")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add PDFs, text files, or images to use as source material for your presentation")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingFilePicker = true }) {
                Label("Add Files", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FileRowView: View {
    let file: SourceFile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: fileIcon)
                .font(.title3)
                .foregroundColor(fileColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.filename)
                    .font(.body)
                
                HStack(spacing: 8) {
                    Text(file.fileType.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(file.importedDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var fileIcon: String {
        switch file.fileType {
        case .doc, .docx:
            return "doc.fill"
        case .txt:
            return "doc.text.fill"
        case .rtf:
            return "doc.richtext.fill"
        }
    }
    
    private var fileColor: Color {
        switch file.fileType {
        case .doc, .docx:
            return .blue
        case .txt:
            return .green
        case .rtf:
            return .orange
        }
    }
}
