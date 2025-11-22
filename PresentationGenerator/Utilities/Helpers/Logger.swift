import Foundation
import os.log

/// Application-wide logging utility
class Logger {
    static let shared = Logger()
    
    private let subsystem = AppConstants.appBundleID
    private var loggers: [String: os.Logger] = [:]
    
    private init() {}
    
    // MARK: - Log Categories
    enum Category: String {
        case app = "App"
        case ui = "UI"
        case network = "Network"
        case openai = "OpenAI"
        case storage = "Storage"
        case keychain = "Keychain"
        case fileImport = "FileImport"
        case slideGeneration = "SlideGeneration"
        case export = "Export"
        case error = "Error"
    }
    
    // MARK: - Private Methods
    private func logger(for category: Category) -> os.Logger {
        if let existingLogger = loggers[category.rawValue] {
            return existingLogger
        }
        
        let newLogger = os.Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category.rawValue] = newLogger
        return newLogger
    }
    
    // MARK: - Public Logging Methods
    
    /// Log debug information
    func debug(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = logger(for: category)
        let fileName = self.sourceFileName(file)
        logger.debug("[\(fileName):\(line)] \(function) - \(message)")
    }
    
    /// Log informational message
    func info(_ message: String, category: Category = .app, file: String = #file, function: String = #function) {
        let logger = logger(for: category)
        let fileName = self.sourceFileName(file)
        logger.info("[\(fileName)] \(function) - \(message)")
    }
    
    /// Log warning
    func warning(_ message: String, category: Category = .app, file: String = #file, function: String = #function) {
        let logger = logger(for: category)
        let fileName = self.sourceFileName(file)
        logger.warning("[\(fileName)] \(function) - ⚠️ \(message)")
    }
    
    /// Log error
    func error(_ message: String, error: Error? = nil, category: Category = .error, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = logger(for: category)
        let fileName = self.sourceFileName(file)
        var logMessage = "[\(fileName):\(line)] \(function) - ❌ \(message)"
        
        if let error = error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        
        logger.error("\(logMessage)")
    }
    
    /// Log critical error
    func critical(_ message: String, error: Error? = nil, category: Category = .error, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = logger(for: category)
        let fileName = self.sourceFileName(file)
        var logMessage = "[\(fileName):\(line)] \(function) - 🔥 CRITICAL: \(message)"
        
        if let error = error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        
        logger.critical("\(logMessage)")
    }
    
    /// Log API request
    func logAPIRequest(_ endpoint: String, method: String = "POST", category: Category = .network) {
        info("API Request: \(method) \(endpoint)", category: category)
    }
    
    /// Log API response
    func logAPIResponse(_ endpoint: String, statusCode: Int, category: Category = .network) {
        info("API Response: \(endpoint) - Status: \(statusCode)", category: category)
    }
    
    /// Log API error
    func logAPIError(_ endpoint: String, error: Error, category: Category = .network) {
        self.error("API Error: \(endpoint)", error: error, category: category)
    }
    
    /// Log file operation
    func logFileOperation(_ operation: String, path: String, category: Category = .storage) {
        info("File Operation: \(operation) - Path: \(path)", category: category)
    }
    
    /// Log slide generation progress
    func logSlideProgress(slideNumber: Int, totalSlides: Int, category: Category = .slideGeneration) {
        info("Generating slide \(slideNumber) of \(totalSlides)", category: category)
    }
    
    // MARK: - Helper Methods
    private func sourceFileName(_ filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.last ?? filePath
    }
}

// MARK: - Convenience Global Functions
func logDebug(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function) {
    Logger.shared.info(message, category: category, file: file, function: function)
}

func logWarning(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function) {
    Logger.shared.warning(message, category: category, file: file, function: function)
}

func logError(_ message: String, error: Error? = nil, category: Logger.Category = .error, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, error: error, category: category, file: file, function: function, line: line)
}
