import Foundation

// Domain Model: Audience
// Full implementation will be done in Phase 1 (Task 4)

enum Audience: String, Codable, CaseIterable, Hashable {
    case kids = "Kids"
    case adults = "Adults"
    
    var designPreferences: DesignPreferences {
        switch self {
        case .kids:
            return DesignPreferences(
                colorScheme: .bright,
                fontSize: .large,
                imageStyle: .cartoon,
                layoutComplexity: .simple
            )
        case .adults:
            return DesignPreferences(
                colorScheme: .professional,
                fontSize: .medium,
                imageStyle: .realistic,
                layoutComplexity: .detailed
            )
        }
    }
    
    var displayName: String {
        rawValue
    }
    
    var description: String {
        switch self {
        case .kids:
            return "Bright colors, large text, playful designs for younger audiences"
        case .adults:
            return "Professional layouts, sophisticated designs for mature audiences"
        }
    }
}

// Supporting types for design preferences
struct DesignPreferences: Codable, Hashable {
    let colorScheme: ColorScheme
    let fontSize: FontSize
    let imageStyle: ImageStyleType
    let layoutComplexity: LayoutComplexity
}

enum ColorScheme: String, Codable, Hashable {
    case bright
    case professional
    case neutral
}

enum FontSize: String, Codable, Hashable {
    case small
    case medium
    case large
    case extraLarge
}

enum ImageStyleType: String, Codable, Hashable {
    case cartoon
    case realistic
    case abstract
}

enum LayoutComplexity: String, Codable, Hashable {
    case simple
    case moderate
    case detailed
}
