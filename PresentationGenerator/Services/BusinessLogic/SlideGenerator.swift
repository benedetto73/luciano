//
//  SlideGenerator.swift
//  PresentationGenerator
//
//  Generates complete slides combining content, design, and images
//

import Foundation

/// Service for generating complete presentation slides
@MainActor
class SlideGenerator: ObservableObject {
    private let openAIService: any OpenAIServiceProtocol
    private let imageService: ImageService
    
    @Published var isGenerating = false
    @Published var generationProgress: (current: Int, total: Int) = (0, 0)
    @Published var lastError: Error?
    
    // MARK: - Initialization
    
    init(openAIService: any OpenAIServiceProtocol, imageService: ImageService) {
        self.openAIService = openAIService
        self.imageService = imageService
    }
    
    // MARK: - Slide Generation
    
    /// Generates all slides for a project
    /// - Parameters:
    ///   - analysis: Content analysis result
    ///   - designSpec: Design specification
    ///   - audience: Target audience
    ///   - progressCallback: Optional progress callback
    /// - Returns: Array of generated slides
    func generateSlides(
        from analysis: ContentAnalysisResult,
        designSpec: DesignSpec,
        audience: Audience,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws -> [Slide] {
        isGenerating = true
        generationProgress = (0, analysis.keyPoints.count)
        defer { isGenerating = false }
        
        Logger.shared.info("Generating \(analysis.keyPoints.count) slides", category: .business)
        
        var generatedSlides: [Slide] = []
        
        do {
            // Generate slide content from OpenAI
            let slideContents = try await openAIService.generateSlides(
                for: analysis,
                progressCallback: { [weak self] current, total in
                    self?.generationProgress = (current, total)
                    progressCallback?(current, total)
                }
            )
            
            Logger.shared.info("Content generation complete, generating images...", category: .business)
            
            // Generate images and create Slide objects
            for (index, content) in slideContents.enumerated() {
                let slideNumber = index + 1
                let slideId = UUID()
                
                // Generate image
                let imageData = try await openAIService.generateImage(
                    prompt: content.imagePrompt,
                    audience: audience
                )
                
                // Save image to storage
                _ = try await imageService.saveImage(imageData, for: slideId)
                
                // Create ImageData model
                let storedImageData = ImageData(
                    id: UUID(),
                    generationPrompt: content.imagePrompt,
                    fileSize: Int64(imageData.count)
                )
                
                // Create slide
                let slide = Slide(
                    id: slideId,
                    slideNumber: slideNumber,
                    title: content.title,
                    content: content.content,
                    imageData: storedImageData,
                    designSpec: designSpec
                )
                
                generatedSlides.append(slide)
                
                Logger.shared.info("Slide \(slideNumber)/\(slideContents.count) complete", category: .business)
            }
            
            Logger.shared.info("All \(generatedSlides.count) slides generated successfully", category: .business)
            
            return generatedSlides
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Slide generation failed", error: error, category: .business)
            throw error
        } catch {
            let appError = AppError.unknownError(error.localizedDescription)
            lastError = appError
            Logger.shared.error("Slide generation failed", error: error, category: .business)
            throw appError
        }
    }
    
    /// Generates a single slide
    /// - Parameters:
    ///   - keyPoint: Key point for the slide
    ///   - slideNumber: Slide number
    ///   - totalSlides: Total slides in presentation
    ///   - designSpec: Design specification
    ///   - audience: Target audience
    /// - Returns: Generated slide
    func generateSingleSlide(
        keyPoint: KeyPoint,
        slideNumber: Int,
        totalSlides: Int,
        designSpec: DesignSpec,
        audience: Audience
    ) async throws -> Slide {
        isGenerating = true
        defer { isGenerating = false }
        
        Logger.shared.info("Generating single slide \(slideNumber)/\(totalSlides)", category: .business)
        
        do {
            let slideId = UUID()
            
            // Generate content
            let content = try await openAIService.generateSlideContent(
                slideNumber: slideNumber,
                totalSlides: totalSlides,
                mainTheme: "Catholic Teaching",
                keyPoint: keyPoint.content,
                audience: audience
            )
            
            // Generate image
            let imageData = try await openAIService.generateImage(
                prompt: content.imagePrompt,
                audience: audience
            )
            
            // Save image
            _ = try await imageService.saveImage(imageData, for: slideId)
            
            // Create ImageData
            let storedImageData = ImageData(
                id: UUID(),
                generationPrompt: content.imagePrompt,
                fileSize: Int64(imageData.count)
            )
            
            // Create slide
            let slide = Slide(
                id: slideId,
                slideNumber: slideNumber,
                title: content.title,
                content: content.content,
                imageData: storedImageData,
                designSpec: designSpec
            )
            
            Logger.shared.info("Single slide generated successfully", category: .business)
            
            return slide
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Single slide generation failed", error: error, category: .business)
            throw error
        } catch {
            let appError = AppError.unknownError(error.localizedDescription)
            lastError = appError
            throw appError
        }
    }
    
    /// Regenerates a specific slide with new image
    /// - Parameters:
    ///   - slide: Slide to regenerate
    ///   - newPrompt: New image prompt (optional)
    ///   - audience: Target audience
    /// - Returns: Updated slide
    func regenerateSlide(
        _ slide: Slide,
        newPrompt: String? = nil,
        audience: Audience
    ) async throws -> Slide {
        isGenerating = true
        defer { isGenerating = false }
        
        Logger.shared.info("Regenerating slide: \(slide.title)", category: .business)
        
        let promptToUse = newPrompt ?? slide.imageData?.generationPrompt ?? "Catholic teaching illustration"
        
        do {
            // Generate new image
            let imageData = try await openAIService.generateImage(
                prompt: promptToUse,
                audience: audience
            )
            
            // Save new image
            _ = try await imageService.saveImage(imageData, for: slide.id)
            
            // Create updated ImageData
            let updatedImageData = ImageData(
                id: slide.imageData?.id ?? UUID(),
                generationPrompt: promptToUse,
                fileSize: Int64(imageData.count)
            )
            
            // Create updated slide
            let updatedSlide = Slide(
                id: slide.id,
                slideNumber: slide.slideNumber,
                title: slide.title,
                content: slide.content,
                imageData: updatedImageData,
                designSpec: slide.designSpec,
                notes: slide.notes
            )
            
            Logger.shared.info("Slide regenerated successfully", category: .business)
            
            return updatedSlide
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Slide regeneration failed", error: error, category: .business)
            throw error
        } catch {
            let appError = AppError.unknownError(error.localizedDescription)
            lastError = appError
            throw appError
        }
    }
    
    /// Generates image variations for a slide
    /// - Parameters:
    ///   - slide: Slide to generate variations for
    ///   - count: Number of variations (1-4)
    ///   - audience: Target audience
    /// - Returns: Array of image data
    func generateImageVariations(
        for slide: Slide,
        count: Int = 3,
        audience: Audience
    ) async throws -> [Data] {
        isGenerating = true
        defer { isGenerating = false }
        
        let prompt = slide.imageData?.generationPrompt ?? "Catholic teaching illustration"
        
        Logger.shared.info("Generating \(count) image variations for slide: \(slide.title)", category: .business)
        
        do {
            let variations = try await openAIService.generateImageVariations(
                prompt: prompt,
                audience: audience,
                count: min(count, 4) // Max 4 variations
            )
            
            Logger.shared.info("Generated \(variations.count) variations", category: .business)
            
            return variations
            
        } catch let error as OpenAIError {
            lastError = error
            Logger.shared.error("Image variation generation failed", error: error, category: .business)
            throw error
        } catch {
            let appError = AppError.unknownError(error.localizedDescription)
            lastError = appError
            throw appError
        }
    }
}

// MARK: - Batch Operations

extension SlideGenerator {
    /// Regenerates multiple slides in batch
    /// - Parameters:
    ///   - slides: Slides to regenerate
    ///   - audience: Target audience
    ///   - progressCallback: Progress callback
    /// - Returns: Updated slides
    func regenerateSlides(
        _ slides: [Slide],
        audience: Audience,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws -> [Slide] {
        isGenerating = true
        generationProgress = (0, slides.count)
        defer { isGenerating = false }
        
        Logger.shared.info("Regenerating \(slides.count) slides", category: .business)
        
        var regenerated: [Slide] = []
        
        for (index, slide) in slides.enumerated() {
            let updated = try await regenerateSlide(slide, audience: audience)
            regenerated.append(updated)
            
            generationProgress = (index + 1, slides.count)
            progressCallback?(index + 1, slides.count)
            
            // Rate limiting
            if index < slides.count - 1 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
        }
        
        Logger.shared.info("Batch regeneration complete", category: .business)
        
        return regenerated
    }
}
