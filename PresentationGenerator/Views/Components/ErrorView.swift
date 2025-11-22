//
//  ErrorView.swift
//  PresentationGenerator
//
//  Reusable error display component
//

import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let icon: String
    let retryAction: (() -> Void)?
    let dismissAction: (() -> Void)?
    
    init(
        title: String = "Error",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Action Buttons
            HStack(spacing: 12) {
                if let dismissAction = dismissAction {
                    Button("Dismiss") {
                        dismissAction()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                
                if let retryAction = retryAction {
                    Button("Retry") {
                        retryAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Convenience Initializers

extension ErrorView {
    /// Creates an error view from an Error object
    init(
        error: Error,
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.init(
            title: "Error",
            message: error.localizedDescription,
            retryAction: retryAction,
            dismissAction: dismissAction
        )
    }
    
    /// Creates an error view for network errors
    static func networkError(
        retryAction: @escaping () -> Void,
        dismissAction: (() -> Void)? = nil
    ) -> ErrorView {
        ErrorView(
            title: "Network Error",
            message: "Unable to connect to the server. Please check your internet connection and try again.",
            icon: "wifi.exclamationmark",
            retryAction: retryAction,
            dismissAction: dismissAction
        )
    }
    
    /// Creates an error view for API key issues
    static func apiKeyError(
        retryAction: @escaping () -> Void,
        dismissAction: (() -> Void)? = nil
    ) -> ErrorView {
        ErrorView(
            title: "API Key Required",
            message: "Please configure your OpenAI API key in Settings to continue.",
            icon: "key.fill",
            retryAction: retryAction,
            dismissAction: dismissAction
        )
    }
}

// MARK: - Full Screen Variant

extension ErrorView {
    /// Creates a full-screen error overlay
    func fullScreen() -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            self
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(
                message: "Something went wrong. Please try again.",
                retryAction: {},
                dismissAction: {}
            )
            
            ErrorView.networkError(
                retryAction: {},
                dismissAction: {}
            )
            
            ErrorView.apiKeyError(
                retryAction: {},
                dismissAction: {}
            )
        }
        .frame(width: 500, height: 400)
    }
}
#endif
