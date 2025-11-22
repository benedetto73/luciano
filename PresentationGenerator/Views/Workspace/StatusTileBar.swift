//
//  StatusTileBar.swift
//  PresentationGenerator
//
//  Top status bar with project statistics tiles
//

import SwiftUI

struct StatusTileBar: View {
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Source Files Tile
            StatusTile(
                icon: "doc.text.fill",
                iconColor: .blue,
                count: viewModel.sourceFileCount,
                label: "Source Files",
                onClick: {
                    viewModel.selectedPhase = .importPhase
                }
            )
            
            // Key Points Tile
            StatusTile(
                icon: "key.fill",
                iconColor: .purple,
                count: viewModel.project?.keyPoints.count ?? 0,
                label: "Key Points",
                onClick: {
                    if viewModel.canAnalyze {
                        viewModel.selectedPhase = .analyze
                    }
                }
            )
            .opacity(viewModel.canAnalyze ? 1.0 : 0.5)
            
            // Slides Tile
            StatusTile(
                icon: "rectangle.stack.fill",
                iconColor: .orange,
                count: viewModel.slideCount,
                label: "Slides",
                onClick: {
                    if viewModel.canGenerate {
                        viewModel.selectedPhase = .edit
                    }
                }
            )
            .opacity(viewModel.slideCount > 0 ? 1.0 : 0.5)
            
            // Export Status Tile
            StatusTile(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                count: viewModel.canExport ? 1 : 0,
                label: viewModel.canExport ? "Ready to Export" : "Not Ready",
                showCount: false,
                onClick: {
                    if viewModel.canExport {
                        viewModel.selectedPhase = .exportPhase
                    }
                }
            )
            .opacity(viewModel.canExport ? 1.0 : 0.5)
            
            Spacer()
            
            // Project info
            if let project = viewModel.project {
                HStack(spacing: 12) {
                    // Audience badge
                    HStack(spacing: 6) {
                        Image(systemName: project.audience == .kids ? "figure.child" : "figure.wave")
                            .font(.caption)
                        Text(project.audience.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.audienceColor(for: project.audience).opacity(0.2))
                    )
                    .foregroundColor(DesignSystem.Colors.audienceColor(for: project.audience))
                    
                    // Last modified
                    Text("Modified \(project.modifiedDate.timeAgoDisplay())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
}

// MARK: - Status Tile

struct StatusTile: View {
    let icon: String
    let iconColor: Color
    let count: Int
    let label: String
    var showCount: Bool = true
    let onClick: () -> Void
    
    @State private var isHovered = false
    @State private var previousCount: Int = 0
    @State private var animateCount = false
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                
                // Count and label
                VStack(alignment: .leading, spacing: 2) {
                    if showCount {
                        Text("\(count)")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .scaleEffect(animateCount ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateCount)
                    }
                    
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minWidth: showCount ? 140 : 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .onChange(of: count) { newCount in
            if newCount != previousCount {
                animateCount = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animateCount = false
                }
                previousCount = newCount
            }
        }
        .onAppear {
            previousCount = count
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: self, to: now)
        
        if let week = components.weekOfYear, week > 0 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        }
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        }
        
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }
        
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }
        
        return "Just now"
    }
}
