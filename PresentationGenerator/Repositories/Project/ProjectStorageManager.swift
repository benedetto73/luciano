import Foundation

/// Manages storage and retrieval of Project data
class ProjectStorageManager {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        
        // Configure JSON encoder
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        
        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        // Ensure projects directory exists
        try? createProjectsDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createProjectsDirectoryIfNeeded() throws {
        let projectsDir = AppConstants.projectsDirectory
        
        if !fileManager.fileExists(atPath: projectsDir.path) {
            try fileManager.createDirectory(
                at: projectsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            Logger.shared.info("Created projects directory at \(projectsDir.path)", category: .storage)
        }
        
        // Also create images directory
        let imagesDir = AppConstants.imagesDirectory
        if !fileManager.fileExists(atPath: imagesDir.path) {
            try fileManager.createDirectory(
                at: imagesDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            Logger.shared.info("Created images directory at \(imagesDir.path)", category: .storage)
        }
    }
    
    func projectFileURL(for projectID: UUID) -> URL {
        AppConstants.projectsDirectory
            .appendingPathComponent(projectID.uuidString)
            .appendingPathExtension(AppConstants.projectFileExtension)
    }
    
    // MARK: - Save
    
    func save(_ project: Project) throws {
        let fileURL = projectFileURL(for: project.id)
        
        do {
            let data = try encoder.encode(project)
            try data.write(to: fileURL, options: [.atomic])
            
            Logger.shared.info("Project saved: \(project.name) (\(project.id))", category: .storage)
        } catch {
            Logger.shared.error("Failed to save project", error: error, category: .storage)
            throw AppError.projectSaveError(error)
        }
    }
    
    // MARK: - Load
    
    func load(projectID: UUID) throws -> Project {
        let fileURL = projectFileURL(for: projectID)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            Logger.shared.warning("Project file not found: \(projectID)", category: .storage)
            throw AppError.projectNotFound(projectID)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let project = try decoder.decode(Project.self, from: data)
            
            Logger.shared.debug("Project loaded: \(project.name) (\(project.id))", category: .storage)
            return project
        } catch {
            Logger.shared.error("Failed to load project", error: error, category: .storage)
            throw AppError.projectLoadError(error)
        }
    }
    
    func loadAll() throws -> [Project] {
        let projectsDir = AppConstants.projectsDirectory
        
        guard fileManager.fileExists(atPath: projectsDir.path) else {
            Logger.shared.debug("Projects directory does not exist yet", category: .storage)
            return []
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: projectsDir,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            let projectFiles = contents.filter { $0.pathExtension == AppConstants.projectFileExtension }
            
            var projects: [Project] = []
            for fileURL in projectFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let project = try decoder.decode(Project.self, from: data)
                    projects.append(project)
                } catch {
                    Logger.shared.warning("Failed to load project from \(fileURL.lastPathComponent)", category: .storage)
                    // Continue loading other projects
                }
            }
            
            Logger.shared.info("Loaded \(projects.count) projects", category: .storage)
            return projects.sorted { $0.modifiedDate > $1.modifiedDate }
        } catch {
            Logger.shared.error("Failed to load projects", error: error, category: .storage)
            throw AppError.projectLoadError(error)
        }
    }
    
    // MARK: - Delete
    
    func delete(projectID: UUID) throws {
        let fileURL = projectFileURL(for: projectID)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            Logger.shared.warning("Cannot delete non-existent project: \(projectID)", category: .storage)
            throw AppError.projectNotFound(projectID)
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            Logger.shared.info("Project deleted: \(projectID)", category: .storage)
        } catch {
            Logger.shared.error("Failed to delete project", error: error, category: .storage)
            throw AppError.projectSaveError(error)
        }
    }
    
    // MARK: - Exists Check
    
    func exists(projectID: UUID) -> Bool {
        let fileURL = projectFileURL(for: projectID)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - Metadata
    
    func getProjectMetadata(projectID: UUID) throws -> [FileAttributeKey: Any] {
        let fileURL = projectFileURL(for: projectID)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw AppError.projectNotFound(projectID)
        }
        
        return try fileManager.attributesOfItem(atPath: fileURL.path)
    }
    
    // MARK: - Export/Import
    
    func export(project: Project, to destinationURL: URL) throws {
        let data = try encoder.encode(project)
        try data.write(to: destinationURL, options: [.atomic])
        Logger.shared.info("Project exported to \(destinationURL.path)", category: .storage)
    }
    
    func `import`(from sourceURL: URL) throws -> Project {
        let data = try Data(contentsOf: sourceURL)
        let project = try decoder.decode(Project.self, from: data)
        
        // Save imported project
        try save(project)
        
        Logger.shared.info("Project imported: \(project.name)", category: .storage)
        return project
    }
}
