//
//  SlideRenderer.swift
//  PresentationGenerator
//
//  Renders slides to NSImage for preview and export
//

import AppKit
import SwiftUI

/// Service for rendering slides to images
@MainActor
class SlideRenderer: ObservableObject {
    private let imageService: ImageService
    
    @Published var isRendering = false
    @Published var lastError: Error?
    
    // MARK: - Initialization
    
    init(imageService: ImageService) {
        self.imageService = imageService
    }
    
    // MARK: - Rendering
    
    /// Renders a slide to an NSImage
    /// - Parameters:
    ///   - slide: Slide to render
    ///   - size: Output image size (default: 1920x1080 for 16:9)
    /// - Returns: Rendered NSImage
    func render(slide: Slide, size: CGSize = CGSize(width: 1920, height: 1080)) async throws -> NSImage {
        isRendering = true
        defer { isRendering = false }
        
        Logger.shared.info("Rendering slide: \(slide.title)", category: .business)
        
        do {
            // Create SwiftUI view for the slide
            let slideView = SlidePreviewView(slide: slide, imageService: imageService)
            
            // Render to image
            let image = renderView(slideView, size: size)
            
            guard let renderedImage = image else {
                throw AppError.imageProcessingError("Failed to render slide view")
            }
            
            Logger.shared.info("Slide rendered successfully", category: .business)
            return renderedImage
            
        } catch {
            let appError = error as? AppError ?? AppError.imageProcessingError(error.localizedDescription)
            lastError = appError
            Logger.shared.error("Slide rendering failed", error: error, category: .business)
            throw appError
        }
    }
    
    /// Renders multiple slides to images
    /// - Parameters:
    ///   - slides: Slides to render
    ///   - size: Output image size
    ///   - progressCallback: Progress callback
    /// - Returns: Array of rendered images
    func renderSlides(
        _ slides: [Slide],
        size: CGSize = CGSize(width: 1920, height: 1080),
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws -> [NSImage] {
        isRendering = true
        defer { isRendering = false }
        
        Logger.shared.info("Rendering \(slides.count) slides", category: .business)
        
        var images: [NSImage] = []
        
        for (index, slide) in slides.enumerated() {
            let image = try await render(slide: slide, size: size)
            images.append(image)
            
            progressCallback?(index + 1, slides.count)
        }
        
        Logger.shared.info("All slides rendered successfully", category: .business)
        return images
    }
    
    /// Renders a slide thumbnail
    /// - Parameters:
    ///   - slide: Slide to render
    ///   - size: Thumbnail size (default: 320x180)
    /// - Returns: Thumbnail image
    func renderThumbnail(slide: Slide, size: CGSize = CGSize(width: 320, height: 180)) async throws -> NSImage {
        return try await render(slide: slide, size: size)
    }
    
    // MARK: - Private Rendering
    
    private func renderView<V: View>(_ view: V, size: CGSize) -> NSImage? {
        let hostingController = NSHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        
        guard let bitmapRep = hostingController.view.bitmapImageRepForCachingDisplay(in: hostingController.view.bounds) else {
            return nil
        }
        
        bitmapRep.size = size
        hostingController.view.cacheDisplay(in: hostingController.view.bounds, to: bitmapRep)
        
        let image = NSImage(size: size)
        image.addRepresentation(bitmapRep)
        
        return image
    }
}

// MARK: - Slide Preview View

private struct SlidePreviewView: View {
    let slide: Slide
    let imageService: ImageService
    
    @State private var slideImage: NSImage?
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: slide.designSpec.backgroundColor)
            
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(slide.title)
                    .font(titleFont)
                    .foregroundColor(Color(hex: slide.designSpec.textColor))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 60)
                    .padding(.top, 40)
                
                HStack(alignment: .top, spacing: 40) {
                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(contentLines, id: \.self) { line in
                            HStack(alignment: .top, spacing: 12) {
                                bulletPoint
                                Text(line)
                                    .font(contentFont)
                                    .foregroundColor(Color(hex: slide.designSpec.textColor))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 60)
                    
                    // Image
                    if let image = slideImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 500, height: 500)
                            .cornerRadius(12)
                            .padding(.trailing, 60)
                    }
                }
                
                Spacer()
                
                // Slide number
                Text("\(slide.slideNumber)")
                    .font(.caption)
                    .foregroundColor(Color(hex: slide.designSpec.textColor).opacity(0.6))
                    .padding(.horizontal, 60)
                    .padding(.bottom, 20)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private var contentLines: [String] {
        slide.content.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    private var titleFont: Font {
        switch slide.designSpec.fontSize {
        case .small:
            return .system(size: 48, weight: .bold)
        case .medium:
            return .system(size: 56, weight: .bold)
        case .large:
            return .system(size: 64, weight: .bold)
        case .extraLarge:
            return .system(size: 72, weight: .bold)
        }
    }
    
    private var contentFont: Font {
        switch slide.designSpec.fontSize {
        case .small:
            return .system(size: 24)
        case .medium:
            return .system(size: 28)
        case .large:
            return .system(size: 32)
        case .extraLarge:
            return .system(size: 36)
        }
    }
    
    @ViewBuilder
    private var bulletPoint: some View {
        switch slide.designSpec.bulletStyle {
        case .disc:
            Circle()
                .fill(Color(hex: slide.designSpec.textColor))
                .frame(width: 8, height: 8)
                .padding(.top, 10)
        case .circle:
            Circle()
                .strokeBorder(Color(hex: slide.designSpec.textColor), lineWidth: 2)
                .frame(width: 8, height: 8)
                .padding(.top, 10)
        case .square:
            Rectangle()
                .fill(Color(hex: slide.designSpec.textColor))
                .frame(width: 8, height: 8)
                .padding(.top, 10)
        case .dash:
            Rectangle()
                .fill(Color(hex: slide.designSpec.textColor))
                .frame(width: 12, height: 2)
                .padding(.top, 12)
        case .arrow:
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: slide.designSpec.textColor))
        case .checkmark:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: slide.designSpec.textColor))
        case .none:
            EmptyView()
        }
    }
    
    private func loadImage() async {
        guard slide.imageData != nil else { return }
        
        do {
            let image = try await imageService.loadImage(for: slide.id)
            self.slideImage = image
        } catch {
            Logger.shared.warning("Failed to load slide image: \(error)", category: .business)
        }
    }
}

