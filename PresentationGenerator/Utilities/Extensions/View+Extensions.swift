import SwiftUI

extension View {
    /// Applies a card style with shadow and corner radius
    func cardStyle(
        backgroundColor: Color = DesignConstants.Colors.secondaryBackground,
        cornerRadius: CGFloat = DesignConstants.CornerRadius.medium,
        shadow: Bool = true
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .if(shadow) { view in
                view.shadow(
                    color: Color.black.opacity(0.1),
                    radius: DesignConstants.Shadow.medium.radius,
                    x: DesignConstants.Shadow.medium.x,
                    y: DesignConstants.Shadow.medium.y
                )
            }
    }
    
    /// Applies conditional modifiers
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies conditional modifiers with else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Adds a loading overlay
    func loading(_ isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: DesignConstants.Spacing.medium) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(message)
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(DesignConstants.Spacing.extraLarge)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(DesignConstants.CornerRadius.large)
                }
            }
        }
    }
    
    /// Adds error alert modifier
    func errorAlert(error: Binding<Error?>) -> some View {
        self.alert(
            "Error",
            isPresented: .constant(error.wrappedValue != nil),
            presenting: error.wrappedValue
        ) { _ in
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    /// Adds a toast notification
    func toast(
        message: Binding<String?>,
        duration: TimeInterval = 3.0
    ) -> some View {
        self.overlay(alignment: .top) {
            if let msg = message.wrappedValue {
                Text(msg)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(DesignConstants.CornerRadius.medium)
                    .padding(.top, DesignConstants.Spacing.large)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                message.wrappedValue = nil
                            }
                        }
                    }
            }
        }
    }
    
    /// Adds empty state view when condition is met
    @ViewBuilder
    func emptyState<EmptyContent: View>(
        _ isEmpty: Bool,
        @ViewBuilder emptyContent: () -> EmptyContent
    ) -> some View {
        if isEmpty {
            emptyContent()
        } else {
            self
        }
    }
    
    /// Adds standard padding
    func standardPadding() -> some View {
        self.padding(DesignConstants.Spacing.medium)
    }
    
    /// Adds large padding
    func largePadding() -> some View {
        self.padding(DesignConstants.Spacing.large)
    }
    
    /// Makes view tappable with feedback
    func tappable(action: @escaping () -> Void) -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }
    
    /// Adds hover effect (scale on hover)
    func hoverEffect(scale: CGFloat = 1.05) -> some View {
        self.scaleEffect(1.0)
            .onHover { hovering in
                withAnimation(DesignConstants.Animation.fast) {
                    // Note: This is a simplified version
                    // Full implementation would use @State
                }
            }
    }
    
    /// Adds frame with aspect ratio
    func aspectFrame(
        _ aspectRatio: CGFloat,
        contentMode: ContentMode = .fit
    ) -> some View {
        self.aspectRatio(aspectRatio, contentMode: contentMode)
    }
    
    /// Adds slide aspect ratio frame
    func slideAspectFrame(contentMode: ContentMode = .fit) -> some View {
        self.aspectRatio(DesignConstants.Layout.slideAspectRatio, contentMode: contentMode)
    }
    
    /// Hides view when condition is true
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    /// Adds navigation link styling
    func navigationLinkStyle() -> some View {
        self
            .foregroundColor(DesignConstants.Colors.text)
            .contentShape(Rectangle())
    }
    
    /// Adds disabled state with opacity
    func disabledWithOpacity(_ disabled: Bool) -> some View {
        self
            .disabled(disabled)
            .opacity(disabled ? 0.5 : 1.0)
    }
}

// MARK: - Conditional View Modifier Helper
extension View {
    @ViewBuilder
    func applyIf<T: View>(
        _ condition: Bool,
        @ViewBuilder transform: (Self) -> T
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
