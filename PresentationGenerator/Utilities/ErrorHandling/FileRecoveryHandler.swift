import Foundation

/// Handles corrupted file detection, backup restoration, and data recovery
@MainActor
class FileRecoveryHandler {
    
    // MARK: - Properties
    
    private let fileManager: FileManager
    private let backupDirectory: URL
    private let maxBackups: Int
    
    // MARK: - Initialization
    
    init(fileManager: FileManager = .default, maxBackups: Int = 5) {
        self.fileManager = fileManager
        self.maxBackups = maxBackups
        
        // Setup backup directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.backupDirectory = appSupport.appendingPathComponent("Backups", isDirectory: true)
        
        createBackupDirectoryIfNeeded()
    }
    
    // MARK: - Corruption Detection
    
    /// Validates project file integrity
    func validateProjectFile(at url: URL) throws {
        // Check file exists
        guard fileManager.fileExists(atPath: url.path) else {
            throw AppError.fileNotFound(url.path)
        }
        
        // Check file size (empty or too small likely corrupted)
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int64, fileSize > 0 else {
            throw AppError.corruptedFile("File is empty or has invalid size")
        }
        
        // Try to read and parse JSON
        let data = try Data(contentsOf: url)
        
        guard !data.isEmpty else {
            throw AppError.corruptedFile("File contains no data")
        }
        
        // Validate JSON structure
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            
            // Check for required fields
            guard let dict = json as? [String: Any],
                  dict["id"] != nil,
                  dict["name"] != nil else {
                throw AppError.corruptedFile("Missing required fields")
            }
            
        } catch {
            throw AppError.corruptedFile("Invalid JSON format: \(error.localizedDescription)")
        }
    }
    
    /// Attempts to repair corrupted file
    func repairFile(at url: URL) throws {
        let data = try Data(contentsOf: url)
        
        // Try to fix common JSON corruption issues
        var jsonString = String(data: data, encoding: .utf8) ?? ""
        
        // Remove null bytes
        jsonString = jsonString.replacingOccurrences(of: "\0", with: "")
        
        // Try to fix truncated JSON
        if !jsonString.hasSuffix("}") {
            // Attempt to close unclosed braces
            let openBraces = jsonString.filter { $0 == "{" }.count
            let closeBraces = jsonString.filter { $0 == "}" }.count
            
            if openBraces > closeBraces {
                jsonString += String(repeating: "}", count: openBraces - closeBraces)
            }
        }
        
        // Validate repaired JSON
        guard let repairedData = jsonString.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: repairedData) else {
            throw AppError.corruptedFile("Unable to repair file")
        }
        
        // Save repaired file
        try repairedData.write(to: url, options: .atomic)
    }
    
    // MARK: - Backup Management
    
    /// Creates a backup of a project file
    func createBackup(of url: URL) throws {
        let fileName = url.lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupFileName = "\(fileName).\(timestamp).backup"
        let backupURL = backupDirectory.appendingPathComponent(backupFileName)
        
        try fileManager.copyItem(at: url, to: backupURL)
        
        // Clean up old backups
        try cleanupOldBackups(for: fileName)
    }
    
    /// Restores from most recent backup
    func restoreFromBackup(for fileName: String) throws -> URL {
        let backups = try listBackups(for: fileName)
        
        guard let mostRecent = backups.first else {
            throw AppError.fileNotFound("No backups found for \(fileName)")
        }
        
        return mostRecent
    }
    
    /// Lists available backups for a file
    func listBackups(for fileName: String) throws -> [URL] {
        let backupPattern = fileName.replacingOccurrences(of: ".json", with: "")
        
        let contents = try fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )
        
        let backups = contents
            .filter { $0.lastPathComponent.hasPrefix(backupPattern) }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
        
        return backups
    }
    
    /// Cleans up old backups, keeping only the most recent maxBackups
    private func cleanupOldBackups(for fileName: String) throws {
        let backups = try listBackups(for: fileName)
        
        if backups.count > maxBackups {
            let toDelete = backups.dropFirst(maxBackups)
            for backup in toDelete {
                try fileManager.removeItem(at: backup)
            }
        }
    }
    
    /// Removes all backups
    func clearAllBackups() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: backupDirectory,
            includingPropertiesForKeys: nil
        )
        
        for file in contents {
            try fileManager.removeItem(at: file)
        }
    }
    
    // MARK: - Recovery
    
    /// Attempts to recover a corrupted project file
    func recoverProject(at url: URL) throws -> URL {
        // First, try to repair in place
        do {
            try repairFile(at: url)
            return url
        } catch {
            print("Direct repair failed: \(error)")
        }
        
        // If repair fails, try to restore from backup
        let fileName = url.lastPathComponent
        let backupURL = try restoreFromBackup(for: fileName)
        
        // Validate backup
        try validateProjectFile(at: backupURL)
        
        // Copy backup to original location
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.copyItem(at: backupURL, to: url)
        
        return url
    }
    
    // MARK: - Helper Methods
    
    private func createBackupDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: backupDirectory.path) {
            try? fileManager.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
        }
    }
}

// MARK: - AppError Extension

extension AppError {
    static func corruptedFile(_ message: String) -> AppError {
        .fileSystemError("Corrupted file: \(message)")
    }
}
