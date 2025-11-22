//
//  KeyPointsListView.swift
//  PresentationGenerator
//
//  List view for displaying and managing key points
//

import SwiftUI

struct KeyPointsListView: View {
    @Binding var keyPoints: [KeyPoint]
    let onReorder: (IndexSet, Int) -> Void
    let onToggle: (KeyPoint) -> Void
    let onEdit: (KeyPoint) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Key Points")
                    .font(.headline)
                
                Spacer()
                
                Text("\(includedCount) of \(keyPoints.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // List
            if keyPoints.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(keyPoints) { keyPoint in
                        KeyPointRow(
                            keyPoint: keyPoint,
                            onToggle: { onToggle(keyPoint) },
                            onEdit: { onEdit(keyPoint) }
                        )
                    }
                    .onMove { indices, newOffset in
                        onReorder(indices, newOffset)
                    }
                }
                .listStyle(.inset)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No key points yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Analyze your content to extract key points")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    // MARK: - Computed Properties
    
    private var includedCount: Int {
        keyPoints.filter { $0.isIncluded }.count
    }
}

struct KeyPointRow: View {
    let keyPoint: KeyPoint
    let onToggle: () -> Void
    let onEdit: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .opacity(isHovered ? 1.0 : 0.4)
            
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: keyPoint.isIncluded ? "checkmark.square.fill" : "square")
                    .foregroundColor(keyPoint.isIncluded ? .accentColor : .secondary)
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(keyPoint.content)
                    .font(.body)
                    .foregroundColor(keyPoint.isIncluded ? .primary : .secondary)
                    .strikethrough(!keyPoint.isIncluded)
                
                // Order indicator
                Text("Position \(keyPoint.order + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit Button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
                    .opacity(isHovered ? 1.0 : 0.6)
            }
            .buttonStyle(.plain)
            .help("Edit key point")
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#if DEBUG
struct KeyPointsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreviewWrapper1()
                .previewDisplayName("With Key Points")
            PreviewWrapper2()
                .previewDisplayName("Empty State")
        }
    }
    
    struct PreviewWrapper1: View {
        @State private var keyPoints = [
            KeyPoint(id: UUID(), content: "Introduction to the topic and its significance", order: 0, isIncluded: true),
            KeyPoint(id: UUID(), content: "Historical background and context", order: 1, isIncluded: true),
            KeyPoint(id: UUID(), content: "Main concepts and definitions", order: 2, isIncluded: true),
            KeyPoint(id: UUID(), content: "Practical applications and examples", order: 3, isIncluded: false),
            KeyPoint(id: UUID(), content: "Conclusion and key takeaways", order: 4, isIncluded: true)
        ]
        
        var body: some View {
            KeyPointsListView(
                keyPoints: $keyPoints,
                onReorder: { indices, offset in
                    keyPoints.move(fromOffsets: indices, toOffset: offset)
                },
                onToggle: { keyPoint in
                    if let index = keyPoints.firstIndex(where: { $0.id == keyPoint.id }) {
                        keyPoints[index].isIncluded.toggle()
                    }
                },
                onEdit: { _ in }
            )
            .padding()
            .frame(width: 600, height: 500)
        }
    }
    
    struct PreviewWrapper2: View {
        @State private var keyPoints: [KeyPoint] = []
        
        var body: some View {
            KeyPointsListView(
                keyPoints: $keyPoints,
                onReorder: { _, _ in },
                onToggle: { _ in },
                onEdit: { _ in }
            )
            .padding()
            .frame(width: 600, height: 400)
        }
    }
}
#endif
