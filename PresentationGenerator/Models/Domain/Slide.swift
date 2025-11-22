import Foundation

// Domain Model: Slide
// Full implementation will be done in Phase 1 (Task 4)

struct Slide: Codable, Identifiable, Hashable {
    let id: UUID
    var slideNumber: Int
    var title: String
    var content: String
    var imageData: ImageData?
    var designSpec: DesignSpec
    var notes: String?
    
    init(
        id: UUID = UUID(),
        slideNumber: Int,
        title: String,
        content: String,
        imageData: ImageData? = nil,
        designSpec: DesignSpec,
        notes: String? = nil
    ) {
        self.id = id
        self.slideNumber = slideNumber
        self.title = title
        self.content = content
        self.imageData = imageData
        self.designSpec = designSpec
        self.notes = notes
    }
}
