//
//  SlideThumbnailView.swift
//  PresentationGenerator
//
//  Thumbnail component for slide overview
//

import SwiftUI

struct SlideThumbnailView: View {
    let slide: Slide
    let designSpec: DesignSpec
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Slide Number Badge
                slideNumberBadge
                
                // Thumbnail Preview
                thumbnailPreview
                
                // Slide Title
                slideTitle
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Slide Number Badge
    
    private var slideNumberBadge: some View {
        HStack {
            Text("Slide \(slide.slideNumber)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.gray)
                )
            
            Spacer()
        }
    }
    
    // MARK: - Thumbnail Preview
    
    private var thumbnailPreview: some View {
        ZStack {
            // Mini slide preview
            SlidePreviewView(slide: slide, designSpec: designSpec)
                .frame(width: 200, height: 112.5) // 16:9 aspect ratio
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .cornerRadius(6)
            
            // Hover overlay
            if isHovered && !isSelected {
                Color.black.opacity(0.1)
                    .cornerRadius(6)
            }
            
            // Selection overlay
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.1))
            }
        }
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1),
            radius: isSelected ? 8 : 4,
            x: 0,
            y: 2
        )
    }
    
    // MARK: - Slide Title
    
    private var slideTitle: some View {
        Text(slide.title)
            .font(.caption)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(.primary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(height: 32)
    }
    
    // MARK: - Computed Properties
    
    private var borderColor: Color {
        isSelected ? Color.accentColor : Color.gray.opacity(0.3)
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2 : 1
    }
}

#if DEBUG
struct SlideThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        Text("SlideThumbnailView Preview")
            .frame(width: 220, height: 200)
    }
}
#endif
