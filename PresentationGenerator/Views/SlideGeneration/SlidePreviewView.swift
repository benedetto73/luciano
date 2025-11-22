//
//  SlidePreviewView.swift
//  PresentationGenerator
//
//  Preview component for displaying a slide
//

import SwiftUI

struct SlidePreviewView: View {
    let slide: Slide
    let designSpec: DesignSpec
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView
                
                // Content
                contentView(size: geometry.size)
            }
            .aspectRatio(16/9, contentMode: .fit)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        Color(hex: designSpec.backgroundColor)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private func contentView(size: CGSize) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Title
            Text(slide.title)
                .font(.system(size: size.width * 0.05, weight: .bold))
                .foregroundColor(Color(hex: designSpec.textColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal, size.width * 0.1)
            
            // Content
            if !slide.content.isEmpty {
                Text(slide.content)
                    .font(.system(size: size.width * 0.03))
                    .foregroundColor(Color(hex: designSpec.textColor))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, size.width * 0.1)
                    .lineLimit(10)
            }
            
            // Image if available
            if let imageData = slide.imageData,
               let imageURL = imageData.localURL,
               let nsImage = NSImage(contentsOf: imageURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: size.height * 0.4)
                    .padding(.horizontal, size.width * 0.1)
            }
            
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Preview

#if DEBUG
struct SlidePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SlidePreviewView(
            slide: Slide(
                id: UUID(),
                slideNumber: 1,
                title: "Sample Slide",
                content: "This is sample content for the slide.",
                imageData: nil,
                designSpec: DesignSpec(),
                notes: nil
            ),
            designSpec: DesignSpec()
        )
        .frame(width: 800, height: 450)
    }
}
#endif
