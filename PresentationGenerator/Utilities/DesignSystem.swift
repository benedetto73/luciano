import SwiftUI

/// Design system constants for consistent UI throughout the app
enum DesignSystem {
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 1000 // For fully rounded elements
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 15, weight: .regular)
        static let callout = Font.system(size: 14, weight: .regular)
        static let subheadline = Font.system(size: 13, weight: .regular)
        static let footnote = Font.system(size: 12, weight: .regular)
        static let caption = Font.system(size: 11, weight: .regular)
        
        static let monoBody = Font.system(size: 15, weight: .regular, design: .monospaced)
        static let monoCaption = Font.system(size: 11, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Colors
    
    enum Colors {
        // Primary colors
        static let primary = Color.accentColor
        static let secondary = Color.gray
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Background colors
        static let background = Color(nsColor: .windowBackgroundColor)
        static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
        static let tertiaryBackground = Color(nsColor: .textBackgroundColor)
        
        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
        
        // Border colors
        static let border = Color.gray.opacity(0.2)
        static let separator = Color.gray.opacity(0.1)
        
        /// Returns audience-specific color palette
        static func audienceColor(for audience: Audience) -> Color {
            switch audience {
            case .kids:
                return Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
            case .adults:
                return Color(red: 0.3, green: 0.4, blue: 0.5) // Gray-blue
            }
        }
    }
    
    // MARK: - Shadows
    
    enum Shadows {
        static let sm = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let md = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let lg = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        static let xl = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Transitions
    
    enum Transitions {
        static let fade = AnyTransition.opacity
        static let slide = AnyTransition.slide
        static let scale = AnyTransition.scale
        static let combined = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
    }
}

// MARK: - View Extensions

extension View {
    /// Applies standard card styling
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(
                color: DesignSystem.Shadows.sm.color,
                radius: DesignSystem.Shadows.sm.radius,
                x: DesignSystem.Shadows.sm.x,
                y: DesignSystem.Shadows.sm.y
            )
    }
    
    /// Applies elevated card styling for hover effects
    func elevatedCardStyle() -> some View {
        self
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(
                color: DesignSystem.Shadows.md.color,
                radius: DesignSystem.Shadows.md.radius,
                x: DesignSystem.Shadows.md.x,
                y: DesignSystem.Shadows.md.y
            )
    }
    
    /// Applies section header styling
    func sectionHeaderStyle() -> some View {
        self
            .font(DesignSystem.Typography.headline)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    /// Applies consistent button styling
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    /// Applies secondary button styling
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.secondaryBackground)
            .foregroundColor(DesignSystem.Colors.primaryText)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
    }
    
    /// Applies fade in animation on appear
    func fadeInOnAppear(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .onAppear {
                withAnimation(DesignSystem.Animation.standard.delay(delay)) {
                    // Animation handled by opacity state
                }
            }
    }
    
    /// Applies scale effect for interactive elements
    func interactiveScale(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.spring, value: isPressed)
    }
}
