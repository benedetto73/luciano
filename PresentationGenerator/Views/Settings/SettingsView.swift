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
    @State private var selectedLanguage: LocalizationHelper.SupportedLanguage = LocalizationHelper.currentLanguage
    
    var body: some View {
        Form {
            // Language Section
            Section("settings.language".localized) {
                Picker("settings.language".localized, selection: $selectedLanguage) {
                    ForEach(LocalizationHelper.SupportedLanguage.allCases, id: \.self) { language in
                        HStack {
                            Text(language.flag)
                            Text(language.displayName)
                        }
                        .tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedLanguage) { newLanguage in
                    LocalizationHelper.currentLanguage = newLanguage
                }
                
                Text("settings.language.description".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("settings.openai.title".localized) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("settings.apiKey".localized)
                            .fontWeight(.medium)
                        Spacer()
                        if !viewModel.apiKey.isEmpty {
                            Text(viewModel.apiKey)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        } else {
                            Text("settings.apiKey.notConfigured".localized)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Button("settings.apiKey.update".localized) {
                            showingAPIKeyInput = true
                        }
                        .buttonStyle(.bordered)
                        
                        if !viewModel.apiKey.isEmpty {
                            Button("settings.apiKey.clear".localized, role: .destructive) {
                                showingClearConfirmation = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                Toggle("settings.freeModels".localized, isOn: $viewModel.isUsingFreeModels)
                    .onChange(of: viewModel.isUsingFreeModels) { newValue in
                        viewModel.toggleFreeModels(newValue)
                    }
                
                Text("settings.freeModels.description".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("settings.about".localized) {
                HStack {
                    Text("settings.version".localized)
                    Spacer()
                    Text(AppInfo.version)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("settings.build".localized)
                    Spacer()
                    Text(AppInfo.build)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("settings.bundleId".localized)
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
            
            Section("settings.support".localized) {
                Link(destination: URL(string: "https://github.com/yourusername/presentation-generator")!) {
                    HStack {
                        Label("settings.github".localized, systemImage: "link")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://platform.openai.com/docs")!) {
                    HStack {
                        Label("settings.openai".localized, systemImage: "book")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("settings.title".localized)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("done".localized) {
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
                viewModel: viewModel,
                onSave: {
                    Task {
                        viewModel.isValidating = true
                        await viewModel.updateAPIKey(newAPIKey)
                        viewModel.isValidating = false
                        if viewModel.errorMessage == nil {
                            showingAPIKeyInput = false
                            newAPIKey = ""
                        }
                    }
                },
                onCancel: {
                    showingAPIKeyInput = false
                    newAPIKey = ""
                }
            )
        }
        .alert("settings.apiKey.clearConfirm.title".localized, isPresented: $showingClearConfirmation) {
            Button("cancel".localized, role: .cancel) {}
            Button("settings.apiKey.clear".localized, role: .destructive) {
                Task {
                    await viewModel.clearAPIKey()
                }
            }
        } message: {
            Text("settings.apiKey.clearConfirm.message".localized)
        }
        .alert("success".localized, isPresented: .constant(viewModel.successMessage != nil)) {
            Button("ok".localized) {
                viewModel.successMessage = nil
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
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
}

struct APIKeyInputSheet: View {
    @Binding var apiKey: String
    @ObservedObject var viewModel: SettingsViewModel
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("settings.apiKey.input.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("settings.apiKey.input.subtitle".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            SecureField("settings.apiKey.input.placeholder".localized, text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal)
                .disabled(viewModel.isValidating)
            
            if viewModel.isValidating {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("settings.apiKey.validating".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button("cancel".localized) {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isValidating)
                
                Button("save".localized) {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty || viewModel.isValidating)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
