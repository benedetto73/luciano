//
//  PhaseNavigationSidebar.swift
//  PresentationGenerator
//
//  Vertical sidebar for phase navigation
//

import SwiftUI

struct PhaseNavigationSidebar: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    let collapsed: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            if !collapsed {
                HStack {
                    Text("Workflow")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            
            // Phase buttons
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(WorkflowPhase.allCases, id: \.self) { phase in
                        PhaseButton(
                            phase: phase,
                            isSelected: viewModel.selectedPhase == phase,
                            isCompleted: isPhaseCompleted(phase),
                            isLocked: isPhaseLocked(phase),
                            collapsed: collapsed
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedPhase = phase
                            }
                        }
                    }
                }
                .padding(.horizontal, collapsed ? 8 : 12)
                .padding(.vertical, 12)
            }
            
            Spacer()
            
            // Progress indicator
            if !collapsed {
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        Text("\(completedPhasesCount)/\(WorkflowPhase.allCases.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(progressPercentage)%")
                            .font(.caption)
                            .bold()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func isPhaseCompleted(_ phase: WorkflowPhase) -> Bool {
        guard let project = viewModel.project else { return false }
        
        switch phase {
        case .importPhase: return !project.sourceFiles.isEmpty
        case .analyze: return !project.keyPoints.isEmpty
        case .generate: return !project.slides.isEmpty
        case .edit: return !project.slides.isEmpty
        case .preview: return !project.slides.isEmpty
        case .exportPhase: return !project.slides.isEmpty
        }
    }
    
    private func isPhaseLocked(_ phase: WorkflowPhase) -> Bool {
        guard let project = viewModel.project else { return phase != .importPhase }
        
        switch phase {
        case .importPhase: return false
        case .analyze: return project.sourceFiles.isEmpty
        case .generate: return project.keyPoints.isEmpty
        case .edit: return project.slides.isEmpty
        case .preview: return project.slides.isEmpty
        case .exportPhase: return project.slides.isEmpty
        }
    }
    
    private var completedPhasesCount: Int {
        WorkflowPhase.allCases.filter { isPhaseCompleted($0) }.count
    }
    
    private var progressPercentage: Int {
        Int((Double(completedPhasesCount) / Double(WorkflowPhase.allCases.count)) * 100)
    }
}

// MARK: - Phase Button

struct PhaseButton: View {
    let phase: WorkflowPhase
    let isSelected: Bool
    let isCompleted: Bool
    let isLocked: Bool
    let collapsed: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if !isLocked {
                action()
            }
        }) {
            HStack(spacing: 12) {
                // Icon with badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: phase.icon)
                        .font(.system(size: collapsed ? 24 : 20))
                        .frame(width: collapsed ? 40 : 32, height: collapsed ? 40 : 32)
                        .foregroundColor(iconColor)
                    
                    if isCompleted && !collapsed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .background(
                                Circle()
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .frame(width: 16, height: 16)
                            )
                            .offset(x: 4, y: -4)
                    }
                }
                
                if !collapsed {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.title)
                            .font(.system(.body, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(textColor)
                        
                        Text(phase.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, collapsed ? 12 : 10)
            .padding(.horizontal, collapsed ? 8 : 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
            .shadow(color: shadowColor, radius: isSelected ? 8 : 0, x: 0, y: 2)
            .scaleEffect(isHovered && !isLocked ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.5 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(collapsed ? "\(phase.title) - ⌘\(phase.keyboardShortcut)" : "")
    }
    
    private var iconColor: Color {
        if isLocked { return .secondary }
        if isSelected { return .accentColor }
        if isCompleted { return .green }
        return .primary
    }
    
    private var textColor: Color {
        if isLocked { return .secondary }
        if isSelected { return .primary }
        return .primary
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        }
        if isHovered && !isLocked {
            return Color.secondary.opacity(0.1)
        }
        return Color.clear
    }
    
    private var borderColor: Color {
        isSelected ? .accentColor : .clear
    }
    
    private var shadowColor: Color {
        Color.accentColor.opacity(0.3)
    }
}
