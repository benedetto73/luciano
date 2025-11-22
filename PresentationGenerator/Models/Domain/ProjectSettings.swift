import Foundation

// Supporting Model: ProjectSettings
// Full implementation will be done in Phase 1 (Task 5)

struct ProjectSettings: Codable, Hashable {
    var defaultLayout: LayoutType
    var defaultFontFamily: String
    var defaultFontSize: FontSizeSpec
    var autoSaveEnabled: Bool
    var imageQuality: ImageQuality
    var slideTransitionStyle: TransitionStyle
    
    init(
        defaultLayout: LayoutType = .titleContentAndImage,
        defaultFontFamily: String = "Helvetica",
        defaultFontSize: FontSizeSpec = .medium,
        autoSaveEnabled: Bool = true,
        imageQuality: ImageQuality = .high,
        slideTransitionStyle: TransitionStyle = .fade
    ) {
        self.defaultLayout = defaultLayout
        self.defaultFontFamily = defaultFontFamily
        self.defaultFontSize = defaultFontSize
        self.autoSaveEnabled = autoSaveEnabled
        self.imageQuality = imageQuality
        self.slideTransitionStyle = slideTransitionStyle
    }
}

enum ImageQuality: String, Codable, Hashable {
    case low
    case medium
    case high
    case original
    
    var compressionQuality: Double {
        switch self {
        case .low: return 0.5
        case .medium: return 0.7
        case .high: return 0.9
        case .original: return 1.0
        }
    }
}

enum TransitionStyle: String, Codable, Hashable {
    case none
    case fade
    case push
    case reveal
    case slideOver
}
