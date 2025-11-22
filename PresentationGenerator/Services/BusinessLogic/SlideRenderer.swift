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
            let slideView = SlidePreviewView(slide: slide, designSpec: slide.designSpec)
            
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

