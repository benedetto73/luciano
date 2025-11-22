//
//  AudienceSelectionView.swift
//  PresentationGenerator
//
//  Component for selecting target audience
//

import SwiftUI

struct AudienceSelectionView: View {
    @Binding var selectedAudience: Audience
    
    var body: some View {
        HStack(spacing: 20) {
            // Kids Option
            AudienceCard(
                audience: .kids,
                isSelected: selectedAudience == .kids,
                action: {
                    selectedAudience = .kids
                }
            )
            
            // Adults Option
            AudienceCard(
                audience: .adults,
                isSelected: selectedAudience == .adults,
                action: {
                    selectedAudience = .adults
                }
            )
        }
    }
}

struct AudienceCard: View {
    let audience: Audience
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 36))
                        .foregroundColor(iconColor)
                }
                
                // Title
                Text(audience.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Description
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Design Preferences
                VStack(alignment: .leading, spacing: 4) {
                    designPreferenceItem("Colors", value: designPreferences.colors)
                    designPreferenceItem("Style", value: designPreferences.style)
                    designPreferenceItem("Tone", value: designPreferences.tone)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(12)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch audience {
        case .kids:
            return "figure.and.child.holdinghands"
        case .adults:
            return "person.2.fill"
        }
    }
    
    private var iconColor: Color {
        switch audience {
        case .kids:
            return .orange
        case .adults:
            return .blue
        }
    }
    
    private var iconBackgroundColor: Color {
        switch audience {
        case .kids:
            return Color.orange.opacity(0.15)
        case .adults:
            return Color.blue.opacity(0.15)
        }
    }
    
    private var description: String {
        switch audience {
        case .kids:
            return "Engaging presentations for children with colorful designs and simple language"
        case .adults:
            return "Professional presentations for adult audiences with sophisticated designs"
        }
    }
    
    private var designPreferences: (colors: String, style: String, tone: String) {
        switch audience {
        case .kids:
            return ("Bright & Colorful", "Playful & Fun", "Simple & Clear")
        case .adults:
            return ("Professional", "Clean & Modern", "Formal & Clear")
        }
    }
    
    private var backgroundColor: Color {
        isSelected ? Color.accentColor.opacity(0.08) : Color(NSColor.controlBackgroundColor)
    }
    
    private var borderColor: Color {
        isSelected ? Color.accentColor : Color.gray.opacity(0.3)
    }
    
    private func designPreferenceItem(_ label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
            Text("\(label):")
                .fontWeight(.medium)
            Text(value)
        }
    }
}

#if DEBUG
struct AudienceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State private var selectedAudience: Audience = .kids
        
        var body: some View {
            AudienceSelectionView(selectedAudience: $selectedAudience)
                .padding()
                .frame(width: 700)
        }
    }
}
#endif
