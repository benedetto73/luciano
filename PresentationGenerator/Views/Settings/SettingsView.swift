//
//  SettingsView.swift
//  PresentationGenerator
//
//  Settings screen for app configuration
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @State private var showingAPIKeyInput = false
    @State private var newAPIKey = ""
    @State private var showingClearConfirmation = false
    
    var body: some View {
        Form {
            Section("OpenAI Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("API Key")
                            .fontWeight(.medium)
                        Spacer()
                        if !viewModel.apiKey.isEmpty {
                            Text(viewModel.apiKey)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Not configured")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Button("Update API Key") {
                            showingAPIKeyInput = true
                        }
                        .buttonStyle(.bordered)
                        
                        if !viewModel.apiKey.isEmpty {
                            Button("Clear", role: .destructive) {
                                showingClearConfirmation = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                Toggle("Use Free Models", isOn: $viewModel.isUsingFreeModels)
                    .onChange(of: viewModel.isUsingFreeModels) { newValue in
                        viewModel.toggleFreeModels(newValue)
                    }
                
                Text("When enabled, uses free GPT-3.5 models. When disabled, uses premium GPT-4 models (requires API key).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppInfo.version)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(AppInfo.build)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(AppInfo.bundleIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppInfo.copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Support") {
                Link(destination: URL(string: "https://github.com/yourusername/presentation-generator")!) {
                    HStack {
                        Label("GitHub Repository", systemImage: "link")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://platform.openai.com/docs")!) {
                    HStack {
                        Label("OpenAI Documentation", systemImage: "book")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    viewModel.close()
                }
            }
        }
        .onAppear {
            viewModel.loadSettings()
        }
        .sheet(isPresented: $showingAPIKeyInput) {
            APIKeyInputSheet(
                apiKey: $newAPIKey,
                onSave: {
                    Task {
                        await viewModel.updateAPIKey(newAPIKey)
                        showingAPIKeyInput = false
                        newAPIKey = ""
                    }
                },
                onCancel: {
                    showingAPIKeyInput = false
                    newAPIKey = ""
                }
            )
        }
        .alert("Clear API Key", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                Task {
                    await viewModel.clearAPIKey()
                }
            }
        } message: {
            Text("Are you sure you want to remove your API key? You'll need to enter it again to use premium models.")
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") {
                viewModel.successMessage = nil
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
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
}

struct APIKeyInputSheet: View {
    @Binding var apiKey: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter OpenAI API Key")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your API key is stored securely in the system keychain")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            SecureField("sk-...", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
