import SwiftUI

extension Color {
    /// Creates a Color from a hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Converts Color to hex string
    var hexString: String {
        guard let components = NSColor(self).cgColor.components else {
            return "#000000"
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
    
    /// Returns a lighter version of the color
    func lighter(by percentage: CGFloat = 0.2) -> Color {
        return self.adjust(by: abs(percentage))
    }
    
    /// Returns a darker version of the color
    func darker(by percentage: CGFloat = 0.2) -> Color {
        return self.adjust(by: -abs(percentage))
    }
    
    /// Adjusts color brightness
    private func adjust(by percentage: CGFloat) -> Color {
        let nsColor = NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = max(min(brightness + percentage, 1.0), 0.0)
        
        return Color(
            hue: Double(hue),
            saturation: Double(saturation),
            brightness: Double(newBrightness),
            opacity: Double(alpha)
        )
    }
    
    /// Returns the color with modified opacity
    func withOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }
    
    /// Returns a random color
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
    
    /// Returns contrasting text color (black or white)
    var contrastingTextColor: Color {
        let nsColor = NSColor(self)
        guard let components = nsColor.cgColor.components else {
            return .white
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        // Calculate relative luminance
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        
        return luminance > 0.5 ? .black : .white
    }
    
    /// Creates a gradient from this color to another
    func gradient(to color: Color) -> LinearGradient {
        LinearGradient(
            colors: [self, color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Predefined Color Palettes
extension Color {
    /// Kids color palette
    enum Kids {
        static let background = Color(hex: DesignConstants.HexColors.kidsBackground)
        static let primary = Color(hex: DesignConstants.HexColors.kidsPrimary)
        static let text = Color(hex: DesignConstants.HexColors.kidsText)
        static let secondary = Color(hex: "#4ECDC4")
        static let accent = Color(hex: "#FFE66D")
    }
    
    /// Adults color palette
    enum Adults {
        static let background = Color(hex: DesignConstants.HexColors.adultsBackground)
        static let primary = Color(hex: DesignConstants.HexColors.adultsPrimary)
        static let text = Color(hex: DesignConstants.HexColors.adultsText)
        static let secondary = Color(hex: "#3498DB")
        static let accent = Color(hex: "#E74C3C")
    }
}
