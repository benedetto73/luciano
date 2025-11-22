import SwiftUI

/// Design system constants for the application
enum DesignConstants {
    // MARK: - Colors
    enum Colors {
        // Brand Colors
        static let primaryBlue = Color(hex: "#0066CC")
        static let secondaryBlue = Color(hex: "#4D94FF")
        static let accentGold = Color(hex: "#FFD700")
        
        // Audience-Specific Colors
        enum Kids {
            static let background = Color(hex: "#FFF9E6")
            static let primary = Color(hex: "#FF6B6B")
            static let secondary = Color(hex: "#4ECDC4")
            static let accent = Color(hex: "#FFE66D")
            static let text = Color(hex: "#2D3436")
        }
        
        enum Adults {
            static let background = Color(hex: "#F8F9FA")
            static let primary = Color(hex: "#2C3E50")
            static let secondary = Color(hex: "#3498DB")
            static let accent = Color(hex: "#E74C3C")
            static let text = Color(hex: "#2C3E50")
        }
        
        // UI Colors
        static let background = Color(NSColor.windowBackgroundColor)
        static let secondaryBackground = Color(NSColor.controlBackgroundColor)
        static let text = Color(NSColor.labelColor)
        static let secondaryText = Color(NSColor.secondaryLabelColor)
        static let separator = Color(NSColor.separatorColor)
        
        // Status Colors
        static let success = Color(hex: "#27AE60")
        static let warning = Color(hex: "#F39C12")
        static let error = Color(hex: "#E74C3C")
        static let info = Color(hex: "#3498DB")
    }
    
    // MARK: - Fonts
    enum Fonts {
        // Font Families
        static let primaryFontFamily = "Helvetica Neue"
        static let secondaryFontFamily = "Arial"
        static let monospaceFontFamily = "Menlo"
        
        // Kids Fonts
        static let kidsTitleFont = "Comic Sans MS"
        static let kidsBodyFont = "Comic Sans MS"
        
        // Adults Fonts
        static let adultsTitleFont = "Helvetica Neue"
        static let adultsBodyFont = "Georgia"
        
        // Font Sizes
        enum Size {
            static let extraSmall: CGFloat = 10
            static let small: CGFloat = 12
            static let body: CGFloat = 14
            static let title3: CGFloat = 16
            static let title2: CGFloat = 20
            static let title: CGFloat = 24
            static let largeTitle: CGFloat = 34
            static let extraLarge: CGFloat = 48
        }
        
        // Slide Font Sizes
        enum SlideSize {
            static let kidsTitle: CGFloat = 44
            static let kidsBody: CGFloat = 28
            
            static let adultsTitle: CGFloat = 36
            static let adultsBody: CGFloat = 20
        }
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let extraSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
        static let circle: CGFloat = 1000
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let small = (radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    }
    
    // MARK: - Layout
    enum Layout {
        static let slideAspectRatio: CGFloat = 16.0 / 9.0
        static let thumbnailWidth: CGFloat = 200
        static let thumbnailHeight: CGFloat = 112.5
        static let sidebarWidth: CGFloat = 250
        static let toolbarHeight: CGFloat = 44
    }
    
    // MARK: - Animation
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
    
    // MARK: - Slide Dimensions
    enum SlideDimensions {
        static let width: CGFloat = 1920
        static let height: CGFloat = 1080
        static let dpi: CGFloat = 72
    }
    
    // MARK: - Default Hex Colors
    enum HexColors {
        // Kids
        static let kidsBackground = "#FFF9E6"
        static let kidsPrimary = "#FF6B6B"
        static let kidsText = "#2D3436"
        
        // Adults
        static let adultsBackground = "#FFFFFF"
        static let adultsPrimary = "#2C3E50"
        static let adultsText = "#2C3E50"
        
        // Generic
        static let white = "#FFFFFF"
        static let black = "#000000"
        static let lightGray = "#F5F5F5"
        static let darkGray = "#333333"
    }
}
