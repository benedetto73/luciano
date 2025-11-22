//
//  CustomProgressView.swift
//  PresentationGenerator
//
//  Reusable progress view with percentage and cancellation
//

import SwiftUI

struct CustomProgressView: View {
    let title: String
    let message: String
    @Binding var progress: Double
    let estimatedTimeRemaining: TimeInterval?
    let onCancel: (() -> Void)?
    
    init(
        title: String = "Processing",
        message: String = "Please wait...",
        progress: Binding<Double>,
        estimatedTimeRemaining: TimeInterval? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self._progress = progress
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Progress Bar
            VStack(spacing: 8) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 8)
                
                // Percentage
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let timeRemaining = estimatedTimeRemaining {
                        Text(formatTimeRemaining(timeRemaining))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Cancel Button
            if let onCancel = onCancel {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Helper Methods
    
    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(secs)s remaining"
        } else {
            return "\(secs)s remaining"
        }
    }
}

// MARK: - Full Screen Variant

extension CustomProgressView {
    /// Creates a full-screen progress overlay
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
struct CustomProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomProgressView(
                title: "Generating Slides",
                message: "Creating your presentation...",
                progress: .constant(0.35),
                estimatedTimeRemaining: 45,
                onCancel: {}
            )
            
            CustomProgressView(
                title: "Exporting",
                message: "Saving to PowerPoint format...",
                progress: .constant(0.75),
                estimatedTimeRemaining: 15,
                onCancel: nil
            )
            
            CustomProgressView(
                message: "Processing...",
                progress: .constant(0.5)
            )
        }
        .frame(width: 500, height: 400)
    }
}
#endif
