import Foundation

// Domain Model: Project
// Full implementation will be done in Phase 1 (Task 4)

struct Project: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var audience: Audience
    var createdDate: Date
    var modifiedDate: Date
    var sourceFiles: [SourceFile]
    var keyPoints: [KeyPoint]
    var slides: [Slide]
    var settings: ProjectSettings
    
    init(
        id: UUID = UUID(),
        name: String,
        audience: Audience,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        sourceFiles: [SourceFile] = [],
        keyPoints: [KeyPoint] = [],
        slides: [Slide] = [],
        settings: ProjectSettings = ProjectSettings()
    ) {
        self.id = id
        self.name = name
        self.audience = audience
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.sourceFiles = sourceFiles
        self.keyPoints = keyPoints
        self.slides = slides
        self.settings = settings
    }
}
