import Foundation

/// Application-wide constants
enum AppConstants {
    // MARK: - File Paths
    static let projectsDirectoryName = "PresentationProjects"
    static let imagesDirectoryName = "Images"
    static let exportsDirectoryName = "Exports"
    static let tempDirectoryName = "Temp"
    
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static var projectsDirectory: URL {
        documentsDirectory.appendingPathComponent(projectsDirectoryName)
    }
    
    static var imagesDirectory: URL {
        projectsDirectory.appendingPathComponent(imagesDirectoryName)
    }
    
    static var exportsDirectory: URL {
        projectsDirectory.appendingPathComponent(exportsDirectoryName)
    }
    
    static var tempDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(tempDirectoryName)
    }
    
    // MARK: - File Extensions
    static let projectFileExtension = "presentation"
    static let supportedDocumentTypes = ["doc", "docx", "txt", "rtf"]
    static let supportedImageTypes = ["png", "jpg", "jpeg"]
    
    // MARK: - Defaults
    static let defaultProjectName = "Untitled Presentation"
    static let defaultSlideCount = 5
    static let minSlideCount = 3
    static let maxSlideCount = 50
    static let minKeyPoints = 3
    static let maxKeyPoints = 20
    
    // MARK: - UI Defaults
    static let defaultWindowWidth: CGFloat = 1200
    static let defaultWindowHeight: CGFloat = 800
    static let minWindowWidth: CGFloat = 1000
    static let minWindowHeight: CGFloat = 700
    
    // MARK: - Timeouts
    static let defaultTimeout: TimeInterval = 30.0
    static let longTimeout: TimeInterval = 120.0
    static let imageGenerationTimeout: TimeInterval = 60.0
    
    // MARK: - Cache Settings
    static let maxImageCacheSize: Int = 100 // Number of images
    static let maxImageCacheSizeBytes: Int64 = 500 * 1024 * 1024 // 500 MB
    
    // MARK: - Auto-save
    static let autoSaveInterval: TimeInterval = 60.0 // 1 minute
    
    // MARK: - Content Limits
    static let maxFileSize: Int64 = 10 * 1024 * 1024 // 10 MB
    static let minTextLength = 100 // characters
    static let maxTextLength = 50000 // characters per file
    
    // MARK: - Animation
    static let defaultAnimationDuration: Double = 0.3
    static let fastAnimationDuration: Double = 0.15
    static let slowAnimationDuration: Double = 0.5
    
    // MARK: - App Info
    static let appName = "PresentationGenerator"
    static let appVersion = "1.0.0"
    static let appBundleID = "com.catholic.presentationgenerator"
    
    // MARK: - Support
    static let supportEmail = "support@presentationgenerator.com"
    static let feedbackURL = URL(string: "https://presentationgenerator.com/feedback")
}
