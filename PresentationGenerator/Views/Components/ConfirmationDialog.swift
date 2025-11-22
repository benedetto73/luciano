//
//  ConfirmationDialog.swift
//  PresentationGenerator
//
//  Reusable confirmation dialog for destructive actions
//

import SwiftUI

struct ConfirmationDialogConfig {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmStyle: ButtonRole
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?
    
    init(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        confirmStyle: ButtonRole = .destructive,
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.confirmStyle = confirmStyle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    // MARK: - Preset Configurations
    
    /// Confirmation dialog for deleting a project
    static func deleteProject(
        projectName: String,
        onConfirm: @escaping () -> Void
    ) -> ConfirmationDialogConfig {
        ConfirmationDialogConfig(
            title: "Delete Project",
            message: "Are you sure you want to delete '\(projectName)'? This action cannot be undone.",
            confirmTitle: "Delete",
            confirmStyle: .destructive,
            onConfirm: onConfirm
        )
    }
    
    /// Confirmation dialog for deleting a slide
    static func deleteSlide(
        onConfirm: @escaping () -> Void
    ) -> ConfirmationDialogConfig {
        ConfirmationDialogConfig(
            title: "Delete Slide",
            message: "Are you sure you want to delete this slide? This action cannot be undone.",
            confirmTitle: "Delete",
            confirmStyle: .destructive,
            onConfirm: onConfirm
        )
    }
    
    /// Confirmation dialog for discarding changes
    static func discardChanges(
        onConfirm: @escaping () -> Void
    ) -> ConfirmationDialogConfig {
        ConfirmationDialogConfig(
            title: "Discard Changes",
            message: "You have unsaved changes. Are you sure you want to discard them?",
            confirmTitle: "Discard",
            confirmStyle: .destructive,
            onConfirm: onConfirm
        )
    }
    
    /// Confirmation dialog for clearing cache
    static func clearCache(
        onConfirm: @escaping () -> Void
    ) -> ConfirmationDialogConfig {
        ConfirmationDialogConfig(
            title: "Clear Cache",
            message: "This will delete all cached images and temporary files. Continue?",
            confirmTitle: "Clear",
            confirmStyle: .destructive,
            onConfirm: onConfirm
        )
    }
    
    /// Confirmation dialog for regenerating all slides
    static func regenerateSlides(
        onConfirm: @escaping () -> Void
    ) -> ConfirmationDialogConfig {
        ConfirmationDialogConfig(
            title: "Regenerate All Slides",
            message: "This will recreate all slides and may take several minutes. Existing slides will be replaced. Continue?",
            confirmTitle: "Regenerate",
            onConfirm: onConfirm
        )
    }
}

// MARK: - View Modifier

struct ConfirmationDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let config: ConfirmationDialogConfig
    
    func body(content: Content) -> some View {
        content
            .alert(config.title, isPresented: $isPresented) {
                Button(config.cancelTitle, role: .cancel) {
                    config.onCancel?()
                }
                
                Button(config.confirmTitle, role: config.confirmStyle) {
                    config.onConfirm()
                }
            } message: {
                Text(config.message)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Shows a confirmation dialog
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    ///   - config: Dialog configuration
    func confirmationDialog(
        isPresented: Binding<Bool>,
        config: ConfirmationDialogConfig
    ) -> some View {
        modifier(ConfirmationDialogModifier(
            isPresented: isPresented,
            config: config
        ))
    }
}

// MARK: - Usage Example View

#if DEBUG
struct ConfirmationDialogExample: View {
    @State private var showDeleteProject = false
    @State private var showDeleteSlide = false
    @State private var showDiscardChanges = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Delete Project") {
                showDeleteProject = true
            }
            .confirmationDialog(
                isPresented: $showDeleteProject,
                config: .deleteProject(
                    projectName: "My Presentation",
                    onConfirm: {
                        print("Project deleted")
                    }
                )
            )
            
            Button("Delete Slide") {
                showDeleteSlide = true
            }
            .confirmationDialog(
                isPresented: $showDeleteSlide,
                config: .deleteSlide {
                    print("Slide deleted")
                }
            )
            
            Button("Discard Changes") {
                showDiscardChanges = true
            }
            .confirmationDialog(
                isPresented: $showDiscardChanges,
                config: .discardChanges {
                    print("Changes discarded")
                }
            )
        }
        .padding()
    }
}

struct ConfirmationDialog_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationDialogExample()
            .frame(width: 400, height: 300)
    }
}
#endif
