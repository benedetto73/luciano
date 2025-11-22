//
//  SlideDesigner.swift
//  PresentationGenerator
//
//  Generates design specifications for presentations
//

import Foundation

/// Service for creating design specifications based on audience preferences
@MainActor
class SlideDesigner: ObservableObject {
    
    @Published var isDesigning = false
    @Published var lastError: Error?
    
    // MARK: - Design Generation
    
    /// Creates a design specification for a presentation
    /// - Parameters:
    ///   - audience: Target audience
    /// - Returns: Complete design specification
    func createDesignSpec(
        for audience: Audience
    ) async throws -> DesignSpec {
        isDesigning = true
        defer { isDesigning = false }
        
        Logger.shared.info("Creating design spec for \(audience.rawValue)", category: .business)
        
        // Get preferences from audience
        let prefs = audience.designPreferences
        
        // Map to DesignSpec
        let spec = DesignSpec(
            layout: mapLayout(from: prefs.layoutComplexity),
            backgroundColor: mapBackgroundColor(from: prefs.colorScheme),
            textColor: mapTextColor(from: prefs.colorScheme),
            fontSize: mapFontSize(from: prefs.fontSize),
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        
        Logger.shared.info("Design spec created: \(spec.backgroundColor) background, \(spec.fontSize) font", category: .business)
        
        return spec
    }
    
    /// Creates a design spec from project and audience
    /// - Parameters:
    ///   - project: Project context
    ///   - audience: Target audience
    /// - Returns: Design specification
    func createDesignSpec(from project: Project, audience: Audience) async throws -> DesignSpec {
        return try await createDesignSpec(for: audience)
    }
    
    /// Updates design spec for audience change
    /// - Parameters:
    ///   - newAudience: New target audience
    /// - Returns: Updated design specification
    func updateDesignSpec(
        for newAudience: Audience
    ) async throws -> DesignSpec {
        Logger.shared.info("Updating design spec for \(newAudience.rawValue)", category: .business)
        return try await createDesignSpec(for: newAudience)
    }
    
    // MARK: - Private Mapping Helpers
    
    private func mapLayout(from complexity: LayoutComplexity) -> LayoutType {
        switch complexity {
        case .simple:
            return .titleAndContent
        case .moderate:
            return .titleContentAndImage
        case .detailed:
            return .splitView
        }
    }
    
    private func mapBackgroundColor(from scheme: ColorScheme) -> String {
        switch scheme {
        case .bright:
            return "#FFEB3B" // Bright yellow
        case .professional:
            return "#FFFFFF" // White
        case .neutral:
            return "#F5F5F5" // Light gray
        }
    }
    
    private func mapTextColor(from scheme: ColorScheme) -> String {
        switch scheme {
        case .bright, .professional, .neutral:
            return "#000000" // Black
        }
    }
    
    private func mapFontSize(from size: FontSize) -> FontSizeSpec {
        switch size {
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .extraLarge:
            return .extraLarge
        }
    }
}

// MARK: - Design Validation

extension SlideDesigner {
    /// Validates a design specification
    /// - Parameter spec: Design spec to validate
    /// - Returns: Validation result with any issues
    func validate(_ spec: DesignSpec) -> DesignValidationResult {
        var issues: [String] = []
        
        // Font size warnings for kids
        if spec.fontSize == .small {
            issues.append("Small font size may not be suitable for all audiences")
        }
        
        // Validate colors are valid hex
        if !isValidHexColor(spec.backgroundColor) {
            issues.append("Invalid background color format")
        }
        
        if !isValidHexColor(spec.textColor) {
            issues.append("Invalid text color format")
        }
        
        return DesignValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    private func isValidHexColor(_ color: String) -> Bool {
        let pattern = "^#[0-9A-Fa-f]{6}$"
        return color.range(of: pattern, options: .regularExpression) != nil
    }
    
    struct DesignValidationResult {
        let isValid: Bool
        let issues: [String]
    }
}

