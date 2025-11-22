import Foundation

// Domain Model: KeyPoint
// Full implementation will be done in Phase 1 (Task 4)

struct KeyPoint: Codable, Identifiable, Hashable {
    let id: UUID
    var content: String
    var order: Int
    var isIncluded: Bool
    
    init(
        id: UUID = UUID(),
        content: String,
        order: Int,
        isIncluded: Bool = true
    ) {
        self.id = id
        self.content = content
        self.order = order
        self.isIncluded = isIncluded
    }
}
