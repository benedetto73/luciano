//
//  ImageEditorView.swift
//  PresentationGenerator
//
//  Component for editing slide images
//

import SwiftUI

struct ImageEditorView: View {
    let slide: Slide
    let onRegenerate: () async -> Void
    let onUploadCustom: () -> Void
    
    @State private var isRegenerating = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Image Display
            imageDisplayView
            
            // Action Buttons
            actionButtons
        }
    }
    
    // MARK: - Image Display
    
    private var imageDisplayView: some View {
        Group {
            if isRegenerating {
                regeneratingView
            } else if let imageData = slide.imageData,
                      let imageURL = imageData.localURL,
                      let nsImage = NSImage(contentsOf: imageURL) {
                existingImageView(nsImage: nsImage)
            } else {
                placeholderView
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Regenerating View
    
    private var regeneratingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating image...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("This may take a few moments")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Existing Image View
    
    private func existingImageView(nsImage: NSImage) -> some View {
        GeometryReader { geometry in
            ZStack {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Hover overlay
                if isHovered {
                    Color.black.opacity(0.3)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                Text("Click to regenerate")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                regenerateImage()
            }
        }
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No image generated yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Click 'Generate Image' to create one")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Regenerate Button
            Button(action: {
                regenerateImage()
            }) {
                HStack {
                    if isRegenerating {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(slide.imageData == nil ? "Generate Image" : "Regenerate Image")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRegenerating)
            
            // Upload Custom Button
            Button(action: onUploadCustom) {
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text("Upload Custom")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isRegenerating)
        }
    }
    
    // MARK: - Methods
    
    private func regenerateImage() {
        guard !isRegenerating else { return }
        
        isRegenerating = true
        
        Task {
            await onRegenerate()
            isRegenerating = false
        }
    }
}

#if DEBUG
struct ImageEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("ImageEditorView - With Image")
                .frame(width: 600, height: 400)
                .previewDisplayName("With Image")
            
            Text("ImageEditorView - No Image")
                .frame(width: 600, height: 400)
                .previewDisplayName("No Image")
        }
    }
}
#endif
