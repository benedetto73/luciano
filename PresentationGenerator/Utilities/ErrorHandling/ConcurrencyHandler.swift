import Foundation

/// Handles concurrent project modifications with file locking and conflict detection
@MainActor
class ConcurrencyHandler {
    
    // MARK: - Properties
    
    private let fileManager: FileManager
    private var fileLocks: [URL: FileLock] = [:]
    private let lockQueue = DispatchQueue(label: "com.presentationgenerator.locks", attributes: .concurrent)
    
    // MARK: - Types
    
    struct FileLock {
        let url: URL
        let acquiredAt: Date
        let owner: String
        var isLocked: Bool
    }
    
    struct ConflictResolution {
        enum Strategy {
            case useLocal
            case useRemote
            case merge
            case createCopy
        }
        
        let strategy: Strategy
        let localVersion: ProjectVersion
        let remoteVersion: ProjectVersion
    }
    
    struct ProjectVersion {
        let data: Data
        let modifiedAt: Date
        let checksum: String
    }
    
    // MARK: - Initialization
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    // MARK: - File Locking
    
    /// Acquires a lock on a file
    func acquireLock(for url: URL, timeout: TimeInterval = 5.0) async throws {
        let startTime = Date()
        
        while true {
            // Check if already locked
            if let lock = fileLocks[url], lock.isLocked {
                // Check timeout
                if Date().timeIntervalSince(startTime) > timeout {
                    throw AppError.fileLocked(url.path)
                }
                
                // Wait and retry
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                continue
            }
            
            // Acquire lock
            let lock = FileLock(
                url: url,
                acquiredAt: Date(),
                owner: ProcessInfo.processInfo.processIdentifier.description,
                isLocked: true
            )
            
            fileLocks[url] = lock
            return
        }
    }
    
    /// Releases a lock on a file
    func releaseLock(for url: URL) {
        fileLocks[url]?.isLocked = false
        fileLocks.removeValue(forKey: url)
    }
    
    /// Executes an operation with file lock
    func withLock<T>(for url: URL, operation: () async throws -> T) async throws -> T {
        try await acquireLock(for: url)
        
        defer {
            releaseLock(for: url)
        }
        
        return try await operation()
    }
    
    // MARK: - Conflict Detection
    
    /// Detects if file has been modified externally
    func detectConflict(for url: URL, expectedChecksum: String) throws -> Bool {
        guard fileManager.fileExists(atPath: url.path) else {
            return false
        }
        
        let data = try Data(contentsOf: url)
        let currentChecksum = calculateChecksum(data)
        
        return currentChecksum != expectedChecksum
    }
    
    /// Gets current file version
    func getCurrentVersion(of url: URL) throws -> ProjectVersion {
        let data = try Data(contentsOf: url)
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let modifiedAt = attributes[.modificationDate] as? Date ?? Date()
        let checksum = calculateChecksum(data)
        
        return ProjectVersion(data: data, modifiedAt: modifiedAt, checksum: checksum)
    }
    
    /// Calculates checksum for data
    private func calculateChecksum(_ data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolves conflicts between versions
    func resolveConflict(
        localVersion: ProjectVersion,
        remoteVersion: ProjectVersion,
        strategy: ConflictResolution.Strategy
    ) throws -> Data {
        switch strategy {
        case .useLocal:
            return localVersion.data
            
        case .useRemote:
            return remoteVersion.data
            
        case .merge:
            return try mergeVersions(local: localVersion, remote: remoteVersion)
            
        case .createCopy:
            // Will be handled by caller to save to different location
            return localVersion.data
        }
    }
    
    /// Merges two versions of a project
    private func mergeVersions(local: ProjectVersion, remote: ProjectVersion) throws -> Data {
        // Parse both versions
        guard let localJSON = try? JSONSerialization.jsonObject(with: local.data) as? [String: Any],
              let remoteJSON = try? JSONSerialization.jsonObject(with: remote.data) as? [String: Any] else {
            throw AppError.mergeConflict("Unable to parse project files")
        }
        
        // Use the more recently modified version as base
        var merged = local.modifiedAt > remote.modifiedAt ? localJSON : remoteJSON
        
        // Merge slides (prefer remote if both have changes)
        if let localSlides = localJSON["slides"] as? [[String: Any]],
           let remoteSlides = remoteJSON["slides"] as? [[String: Any]] {
            merged["slides"] = mergeSlides(local: localSlides, remote: remoteSlides)
        }
        
        // Merge settings (prefer remote)
        if let remoteSettings = remoteJSON["settings"] {
            merged["settings"] = remoteSettings
        }
        
        // Update modification time
        merged["modifiedAt"] = ISO8601DateFormatter().string(from: Date())
        
        return try JSONSerialization.data(withJSONObject: merged, options: .prettyPrinted)
    }
    
    /// Merges slide arrays
    private func mergeSlides(local: [[String: Any]], remote: [[String: Any]]) -> [[String: Any]] {
        var slideMap: [String: [String: Any]] = [:]
        
        // Add local slides
        for slide in local {
            if let id = slide["id"] as? String {
                slideMap[id] = slide
            }
        }
        
        // Merge/add remote slides
        for slide in remote {
            if let id = slide["id"] as? String {
                if let existing = slideMap[id] {
                    // Merge individual slide
                    slideMap[id] = mergeSlide(local: existing, remote: slide)
                } else {
                    // New slide from remote
                    slideMap[id] = slide
                }
            }
        }
        
        // Convert back to array and sort by order
        return slideMap.values.sorted { s1, s2 in
            let order1 = s1["order"] as? Int ?? 0
            let order2 = s2["order"] as? Int ?? 0
            return order1 < order2
        }
    }
    
    /// Merges individual slide
    private func mergeSlide(local: [String: Any], remote: [String: Any]) -> [String: Any] {
        var merged = local
        
        // Prefer remote for content changes
        if let remoteTitle = remote["title"] {
            merged["title"] = remoteTitle
        }
        if let remoteContent = remote["content"] {
            merged["content"] = remoteContent
        }
        if let remoteDesignSpec = remote["designSpec"] {
            merged["designSpec"] = remoteDesignSpec
        }
        
        // Keep local order unless remote is more recent
        if let remoteModified = remote["modifiedAt"] as? String,
           let localModified = local["modifiedAt"] as? String,
           remoteModified > localModified {
            merged["order"] = remote["order"]
        }
        
        return merged
    }
    
    // MARK: - Safe Save
    
    /// Saves file with conflict detection
    func safeSave(data: Data, to url: URL, expectedChecksum: String?) async throws {
        try await withLock(for: url) {
            // Detect conflicts if checksum provided
            if let expected = expectedChecksum, fileManager.fileExists(atPath: url.path) {
                if try detectConflict(for: url, expectedChecksum: expected) {
                    throw AppError.mergeConflict("File has been modified externally")
                }
            }
            
            // Create backup before writing
            if fileManager.fileExists(atPath: url.path) {
                let backupURL = url.appendingPathExtension("backup")
                try? fileManager.copyItem(at: url, to: backupURL)
            }
            
            // Write atomically
            try data.write(to: url, options: .atomic)
            
            // Remove backup on success
            let backupURL = url.appendingPathExtension("backup")
            try? fileManager.removeItem(at: backupURL)
        }
    }
}

// MARK: - AppError Extension

extension AppError {
    static func fileLocked(_ path: String) -> AppError {
        .fileSystemError("File is locked: \(path)")
    }
    
    static func mergeConflict(_ message: String) -> AppError {
        .fileSystemError("Merge conflict: \(message)")
    }
}

// MARK: - CC_SHA256 Import

import CommonCrypto
