//
//  ProjectCreationView.swift
//  PresentationGenerator
//
//  Screen for creating new projects
//

import SwiftUI

struct ProjectCreationView: View {
    @StateObject var viewModel: ProjectCreationViewModel
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        Form {
            Section("Project Details") {
                TextField("Project Name", text: $viewModel.projectName)
                    .focused($isNameFieldFocused)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section("Target Audience") {
                Picker("Audience", selection: $viewModel.selectedAudience) {
                    ForEach(Audience.allCases, id: \.self) { audience in
                        Text(audience.rawValue).tag(audience)
                    }
                }
                .pickerStyle(.segmented)
                
                audienceDescription
            }
            
            Section {
                Button(action: {
                    Task {
                        await viewModel.createProject()
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isCreating {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Create Project")
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.canCreate || viewModel.isCreating)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("New Presentation")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: viewModel.cancel)
            }
        }
        .onAppear {
            isNameFieldFocused = true
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
    
    @ViewBuilder
    private var audienceDescription: some View {
        switch viewModel.selectedAudience {
        case .kids:
            Label("Simple language, bright colors, large fonts", systemImage: "sparkles")
                .font(.caption)
                .foregroundColor(.secondary)
        case .adults:
            Label("Professional style, detailed content", systemImage: "briefcase")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
