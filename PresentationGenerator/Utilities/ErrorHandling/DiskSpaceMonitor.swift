import Foundation

/// Monitors and manages disk space for safe file operations
@MainActor
class DiskSpaceMonitor {
    
    // MARK: - Properties
    
    private let fileManager: FileManager
    private let minimumFreeSpace: Int64 // bytes
    private let warningThreshold: Int64 // bytes
    
    @Published private(set) var availableSpace: Int64 = 0
    @Published private(set) var totalSpace: Int64 = 0
    @Published private(set) var status: DiskSpaceStatus = .sufficient
    
    // MARK: - Types
    
    enum DiskSpaceStatus {
        case sufficient
        case warning(available: Int64, needed: Int64)
        case critical(available: Int64, needed: Int64)
    }
    
    // MARK: - Initialization
    
    init(
        fileManager: FileManager = .default,
        minimumFreeSpace: Int64 = 100_000_000, // 100 MB
        warningThreshold: Int64 = 500_000_000  // 500 MB
    ) {
        self.fileManager = fileManager
        self.minimumFreeSpace = minimumFreeSpace
        self.warningThreshold = warningThreshold
        
        updateDiskSpace()
    }
    
    // MARK: - Monitoring
    
    /// Updates current disk space information
    func updateDiskSpace() {
        do {
            let homeDirectory = fileManager.homeDirectoryForCurrentUser
            let values = try homeDirectory.resourceValues(forKeys: [
                .volumeAvailableCapacityKey,
                .volumeTotalCapacityKey
            ])
            
            availableSpace = Int64(values.volumeAvailableCapacity ?? 0)
            totalSpace = Int64(values.volumeTotalCapacity ?? 0)
            
            updateStatus()
        } catch {
            print("Failed to get disk space: \(error)")
        }
    }
    
    private func updateStatus() {
        if availableSpace < minimumFreeSpace {
            status = .critical(available: availableSpace, needed: minimumFreeSpace)
        } else if availableSpace < warningThreshold {
            status = .warning(available: availableSpace, needed: warningThreshold)
        } else {
            status = .sufficient
        }
    }
    
    // MARK: - Space Validation
    
    /// Checks if there's enough space for an operation
    func hasEnoughSpace(needed: Int64) -> Bool {
        updateDiskSpace()
        return availableSpace >= (needed + minimumFreeSpace)
    }
    
    /// Ensures sufficient disk space or throws error
    func ensureSpace(needed: Int64) throws {
        updateDiskSpace()
        
        guard hasEnoughSpace(needed: needed) else {
            throw AppError.insufficientDiskSpace(
                available: availableSpace,
                needed: needed
            )
        }
    }
    
    /// Estimates space needed for export
    func estimateExportSize(slideCount: Int, includeImages: Bool) -> Int64 {
        // Base size per slide (text, layout)
        var estimatedSize = Int64(slideCount) * 50_000 // 50 KB per slide
        
        // Add image overhead if included
        if includeImages {
            estimatedSize += Int64(slideCount) * 500_000 // 500 KB per slide with images
        }
        
        // Add 20% buffer
        return Int64(Double(estimatedSize) * 1.2)
    }
    
    // MARK: - Cleanup Suggestions
    
    /// Suggests cleanup actions based on disk usage
    func getCleanupSuggestions() -> [CleanupSuggestion] {
        var suggestions: [CleanupSuggestion] = []
        
        // Old backups
        if let backupSize = calculateBackupSize(), backupSize > 10_000_000 {
            suggestions.append(.removeOldBackups(size: backupSize))
        }
        
        // Temporary files
        if let tempSize = calculateTempFileSize(), tempSize > 5_000_000 {
            suggestions.append(.clearTempFiles(size: tempSize))
        }
        
        // Old projects
        if let oldProjectsSize = calculateOldProjectsSize(), oldProjectsSize > 50_000_000 {
            suggestions.append(.archiveOldProjects(size: oldProjectsSize))
        }
        
        return suggestions
    }
    
    enum CleanupSuggestion {
        case removeOldBackups(size: Int64)
        case clearTempFiles(size: Int64)
        case archiveOldProjects(size: Int64)
        
        var description: String {
            switch self {
            case .removeOldBackups(let size):
                return "Remove old backups (\(formatBytes(size)))"
            case .clearTempFiles(let size):
                return "Clear temporary files (\(formatBytes(size)))"
            case .archiveOldProjects(let size):
                return "Archive old projects (\(formatBytes(size)))"
            }
        }
        
        var estimatedRecovery: Int64 {
            switch self {
            case .removeOldBackups(let size),
                 .clearTempFiles(let size),
                 .archiveOldProjects(let size):
                return size
            }
        }
    }
    
    // MARK: - Cleanup Actions
    
    /// Executes cleanup based on suggestion
    func executeCleanup(_ suggestion: CleanupSuggestion) throws {
        switch suggestion {
        case .removeOldBackups:
            try removeOldBackups()
        case .clearTempFiles:
            try clearTempFiles()
        case .archiveOldProjects:
            // Would require project repository
            break
        }
        
        updateDiskSpace()
    }
    
    private func removeOldBackups() throws {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let backupDir = appSupport.appendingPathComponent("Backups")
        
        guard fileManager.fileExists(atPath: backupDir.path) else { return }
        
        let backups = try fileManager.contentsOfDirectory(
            at: backupDir,
            includingPropertiesForKeys: [.creationDateKey]
        )
        
        // Keep only last 3 backups per file
        let grouped = Dictionary(grouping: backups) { url in
            url.deletingPathExtension().deletingPathExtension().lastPathComponent
        }
        
        for (_, files) in grouped {
            let sorted = files.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return date1 > date2
            }
            
            for file in sorted.dropFirst(3) {
                try fileManager.removeItem(at: file)
            }
        }
    }
    
    private func clearTempFiles() throws {
        let tempDir = fileManager.temporaryDirectory
        let contents = try fileManager.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: [.creationDateKey]
        )
        
        let twoDaysAgo = Date().addingTimeInterval(-2 * 24 * 60 * 60)
        
        for file in contents {
            let resources = try file.resourceValues(forKeys: [.creationDateKey])
            if let created = resources.creationDate, created < twoDaysAgo {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Size Calculations
    
    private func calculateBackupSize() -> Int64? {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let backupDir = appSupport.appendingPathComponent("Backups")
        return directorySize(at: backupDir)
    }
    
    private func calculateTempFileSize() -> Int64? {
        directorySize(at: fileManager.temporaryDirectory)
    }
    
    private func calculateOldProjectsSize() -> Int64? {
        // Would require project repository to determine "old" projects
        return nil
    }
    
    private func directorySize(at url: URL) -> Int64? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        var size: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                let resources = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
                size += Int64(resources?.fileSize ?? 0)
            }
        }
        
        return size
    }
    
    // MARK: - Formatting
    
    var availableSpaceFormatted: String {
        formatBytes(availableSpace)
    }
    
    var totalSpaceFormatted: String {
        formatBytes(totalSpace)
    }
}

// MARK: - Helper Functions

private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
}

// MARK: - AppError Extension

extension AppError {
    static func insufficientDiskSpace(available: Int64, needed: Int64) -> AppError {
        .fileSystemError(
            "Insufficient disk space. Available: \(formatBytes(available)), needed: \(formatBytes(needed))"
        )
    }
}
