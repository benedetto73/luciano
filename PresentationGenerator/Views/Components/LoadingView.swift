//
//  LoadingView.swift
//  PresentationGenerator
//
//  Reusable loading view with spinner and message
//

import SwiftUI

struct LoadingView: View {
    let message: String
    let showBackground: Bool
    
    init(
        message: String = "Loading...",
        showBackground: Bool = true
    ) {
        self.message = message
        self.showBackground = showBackground
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())
                .accessibilityLabel("Loading")
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            Group {
                if showBackground {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Full Screen Variant

extension LoadingView {
    /// Creates a full-screen loading overlay
    static func fullScreen(message: String = "Loading...") -> some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            LoadingView(message: message, showBackground: true)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()
            
            LoadingView(message: "Generating slides...")
            
            LoadingView.fullScreen(message: "Please wait...")
        }
        .frame(width: 400, height: 300)
    }
}
#endif
