import Foundation

// Domain Model: DesignSpec
// Full implementation will be done in Phase 1 (Task 4)

struct DesignSpec: Codable, Hashable {
    var layout: LayoutType
    var backgroundColor: String // Hex color string
    var textColor: String // Hex color string
    var fontSize: FontSizeSpec
    var fontFamily: String
    var imagePosition: ImagePosition
    var bulletStyle: BulletStyle?
    
    init(
        layout: LayoutType = .titleAndContent,
        backgroundColor: String = "#FFFFFF",
        textColor: String = "#000000",
        fontSize: FontSizeSpec = .medium,
        fontFamily: String = "Helvetica",
        imagePosition: ImagePosition = .right,
        bulletStyle: BulletStyle? = nil
    ) {
        self.layout = layout
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.imagePosition = imagePosition
        self.bulletStyle = bulletStyle
    }
}

enum LayoutType: String, Codable, Hashable {
    case titleOnly
    case titleAndContent
    case titleContentAndImage
    case imageOnly
    case splitView
    case fullImage
}

enum FontSizeSpec: String, Codable, Hashable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    var pointSize: Double {
        switch self {
        case .small: return 14
        case .medium: return 18
        case .large: return 24
        case .extraLarge: return 32
        }
    }
}

enum ImagePosition: String, Codable, Hashable {
    case left
    case right
    case top
    case bottom
    case background
    case center
}

enum BulletStyle: String, Codable, Hashable {
    case disc
    case circle
    case square
    case dash
    case arrow
    case checkmark
}
