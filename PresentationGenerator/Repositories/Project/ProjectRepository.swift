import Foundation

/// Repository for managing projects
class ProjectRepository: ProjectRepositoryProtocol {
    private let storageManager: ProjectStorageManager
    private let fileManager: FileManager
    
    init(
        storageManager: ProjectStorageManager = ProjectStorageManager(),
        fileManager: FileManager = .default
    ) {
        self.storageManager = storageManager
        self.fileManager = fileManager
    }
    
    // MARK: - ProjectRepositoryProtocol
    
    func save(_ project: Project) async throws {
        var updatedProject = project
        updatedProject.modifiedDate = Date()
        
        try storageManager.save(updatedProject)
        Logger.shared.info("Project saved: \(project.name)", category: .storage)
    }
    
    func load(id: UUID) async throws -> Project {
        let project = try storageManager.load(projectID: id)
        Logger.shared.debug("Project loaded: \(project.name)", category: .storage)
        return project
    }
    
    func loadAll() async throws -> [Project] {
        let projects = try storageManager.loadAll()
        Logger.shared.info("Loaded \(projects.count) projects", category: .storage)
        return projects
    }
    
    func delete(id: UUID) async throws {
        // First load the project to get associated files
        let project = try storageManager.load(projectID: id)
        
        // Delete associated images
        for slide in project.slides {
            if let imageData = slide.imageData,
               let localURL = imageData.localURL {
                try? fileManager.removeItem(at: localURL)
            }
        }
        
        // Delete the project file
        try storageManager.delete(projectID: id)
        Logger.shared.info("Project and associated files deleted: \(id)", category: .storage)
    }
    
    func update(_ project: Project) async throws {
        try await save(project)
    }
    
    // MARK: - Additional Methods
    
    func create(name: String, audience: Audience) async throws -> Project {
        let project = Project(
            id: UUID(),
            name: name,
            audience: audience,
            createdDate: Date(),
            modifiedDate: Date()
        )
        
        try storageManager.save(project)
        Logger.shared.info("New project created: \(name)", category: .storage)
        return project
    }
    
    func exists(id: UUID) -> Bool {
        return storageManager.exists(projectID: id)
    }
    
    func export(project: Project, to url: URL) async throws {
        try storageManager.export(project: project, to: url)
    }
    
    func `import`(from url: URL) async throws -> Project {
        let project = try storageManager.import(from: url)
        return project
    }
    
    func duplicate(projectID: UUID, newName: String? = nil) async throws -> Project {
        let original = try storageManager.load(projectID: projectID)
        
        var duplicate = original
        duplicate.id = UUID()
        duplicate.name = newName ?? "\(original.name) (Copy)"
        duplicate.createdDate = Date()
        duplicate.modifiedDate = Date()
        
        // Duplicate images
        var updatedSlides: [Slide] = []
        for slide in duplicate.slides {
            var updatedSlide = slide
            updatedSlide.id = UUID()
            
            if let imageData = slide.imageData,
               let originalURL = imageData.localURL {
                // Copy image to new location
                let newImageURL = AppConstants.imagesDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("png")
                
                try? fileManager.copyItem(at: originalURL, to: newImageURL)
                
                var newImageData = imageData
                newImageData.id = UUID()
                newImageData.localURL = newImageURL
                updatedSlide.imageData = newImageData
            }
            
            updatedSlides.append(updatedSlide)
        }
        duplicate.slides = updatedSlides
        
        try storageManager.save(duplicate)
        Logger.shared.info("Project duplicated: \(duplicate.name)", category: .storage)
        return duplicate
    }
}
