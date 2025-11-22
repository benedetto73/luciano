//
//  ExportProgressView.swift
//  PresentationGenerator
//
//  View for displaying export progress
//

import SwiftUI

struct ExportProgressView: View {
    @ObservedObject var viewModel: SlideOverviewViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Exporting Presentation")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Progress Indicator
            VStack(spacing: 12) {
                ProgressView(value: viewModel.exportProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 300)
                
                Text(viewModel.exportMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("\(Int(viewModel.exportProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Animation
            if viewModel.isExporting {
                LottieAnimation()
            }
            
            // Cancel button (only show if still exporting)
            if viewModel.isExporting {
                Button("Cancel") {
                    // Note: Actual cancellation logic would need to be implemented in the ViewModel
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(width: 450, height: 300)
        .onChange(of: viewModel.isExporting) { isExporting in
            if !isExporting {
                // Auto-dismiss when export completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
    }
}

// Simple animation placeholder
struct LottieAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#if DEBUG
struct ExportProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Text("ExportProgressView Preview")
            .frame(width: 450, height: 300)
    }
}
#endif
