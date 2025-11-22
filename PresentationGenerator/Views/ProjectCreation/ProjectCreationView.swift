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
            Section("projectCreation.projectName".localized) {
                TextField("projectCreation.projectName".localized, text: $viewModel.projectName)
                    .focused($isNameFieldFocused)
                    .textFieldStyle(.roundedBorder)
            }
            
            Section("projectCreation.targetAudience".localized) {
                Picker("projectCreation.audience".localized, selection: $viewModel.selectedAudience) {
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
                            Text("projectCreation.create".localized)
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.canCreate || viewModel.isCreating)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("projectCreation.title".localized)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel".localized, action: viewModel.cancel)
            }
        }
        .onAppear {
            isNameFieldFocused = true
        }
        .alert("error".localized, isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("ok".localized) {
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
            Label("projectCreation.kids.description".localized, systemImage: "sparkles")
                .font(.caption)
                .foregroundColor(.secondary)
        case .adults:
            Label("projectCreation.adults.description".localized, systemImage: "briefcase")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
