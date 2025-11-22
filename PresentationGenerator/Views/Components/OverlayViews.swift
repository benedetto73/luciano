//
//  OverlayViews.swift
//  PresentationGenerator
//
//  Loading and error overlay components
//

import SwiftUI

// MARK: - Loading Overlay

struct LoadingOverlayView: View {
    let title: String
    let message: String
    var progress: Double? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            // Blocking background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Content card
            VStack(spacing: 24) {
                // Animated spinner
                ProgressView()
                    .scaleEffect(1.5)
                    .pulse()
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Progress bar if percentage available
                if let progress = progress {
                    VStack(spacing: 8) {
                        ProgressView(value: progress, total: 100)
                            .progressViewStyle(.linear)
                            .frame(width: 300)
                        
                        Text("\(Int(progress))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Cancel button
                if let onCancel = onCancel {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(40)
            .frame(minWidth: 400)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Error Overlay

struct ErrorOverlayView: View {
    let title: String
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Blocking background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Content card
            VStack(spacing: 24) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: onRetry) {
                        Text("Retry")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(40)
            .frame(minWidth: 400, maxWidth: 500)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}
