//
//  ToastView.swift
//  PresentationGenerator
//
//  Temporary notification toast component
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    let position: ToastPosition
    
    enum ToastType {
        case success
        case error
        case warning
        case info
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .warning:
                return .orange
            case .info:
                return .blue
            }
        }
    }
    
    enum ToastPosition {
        case top
        case bottom
    }
    
    init(
        message: String,
        type: ToastType = .info,
        position: ToastPosition = .top
    ) {
        self.message = message
        self.type = type
        self.position = position
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastView.ToastType
    let position: ToastView.ToastPosition
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack(alignment: position == .top ? .top : .bottom) {
            content
            
            if isShowing {
                ToastView(message: message, type: type, position: position)
                    .padding(.top, position == .top ? 20 : 0)
                    .padding(.bottom, position == .bottom ? 20 : 0)
                    .transition(.move(edge: position == .top ? .top : .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isShowing = false
                            }
                        }
                    }
            }
        }
        .animation(.spring(), value: isShowing)
    }
}

// MARK: - View Extension

extension View {
    /// Shows a toast notification
    /// - Parameters:
    ///   - isShowing: Binding to control visibility
    ///   - message: Message to display
    ///   - type: Toast type (success, error, warning, info)
    ///   - position: Position on screen (top or bottom)
    ///   - duration: How long to show the toast (default: 3 seconds)
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        type: ToastView.ToastType = .info,
        position: ToastView.ToastPosition = .top,
        duration: TimeInterval = 3.0
    ) -> some View {
        modifier(ToastModifier(
            isShowing: isShowing,
            message: message,
            type: type,
            position: position,
            duration: duration
        ))
    }
}

// MARK: - Preview

#if DEBUG
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToastView(
                message: "Project saved successfully!",
                type: .success
            )
            
            ToastView(
                message: "Failed to connect to server",
                type: .error
            )
            
            ToastView(
                message: "API rate limit approaching",
                type: .warning
            )
            
            ToastView(
                message: "Processing your request...",
                type: .info
            )
        }
        .frame(width: 400)
        .padding()
    }
}
#endif
