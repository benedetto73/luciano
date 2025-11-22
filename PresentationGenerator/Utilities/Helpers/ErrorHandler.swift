import Foundation
import SwiftUI

/// Centralized error handling utility
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Handles an error by logging it and optionally displaying to user
    func handle(
        _ error: Error,
        shouldDisplay: Bool = true,
        context: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let appError = convertToAppError(error)
        
        // Log the error
        var logMessage = "Error occurred"
        if let context = context {
            logMessage += " in \(context)"
        }
        Logger.shared.error(logMessage, error: error, file: file, function: function, line: line)
        
        // Display to user if requested
        if shouldDisplay {
            currentError = appError
            showingError = true
        }
    }
    
    /// Handles multiple errors
    func handleMultiple(_ errors: [Error], shouldDisplay: Bool = true) {
        guard !errors.isEmpty else { return }
        
        if errors.count == 1 {
            handle(errors[0], shouldDisplay: shouldDisplay)
        } else {
            let message = "Multiple errors occurred (\(errors.count))"
            Logger.shared.error(message, category: .error)
            
            if shouldDisplay {
                currentError = .unknownError(message)
                showingError = true
            }
        }
    }
    
    /// Dismisses current error
    func dismissError() {
        currentError = nil
        showingError = false
    }
    
    /// Wraps an async throwing function with error handling
    func withErrorHandling<T>(
        context: String? = nil,
        shouldDisplay: Bool = true,
        _ operation: () async throws -> T
    ) async -> Result<T, Error> {
        do {
            let result = try await operation()
            return .success(result)
        } catch {
            handle(error, shouldDisplay: shouldDisplay, context: context)
            return .failure(error)
        }
    }
    
    /// Wraps a throwing function with error handling
    func withErrorHandling<T>(
        context: String? = nil,
        shouldDisplay: Bool = true,
        _ operation: () throws -> T
    ) -> Result<T, Error> {
        do {
            let result = try operation()
            return .success(result)
        } catch {
            handle(error, shouldDisplay: shouldDisplay, context: context)
            return .failure(error)
        }
    }
    
    // MARK: - Error Conversion
    
    private func convertToAppError(_ error: Error) -> AppError {
        // If already an AppError, return as is
        if let appError = error as? AppError {
            return appError
        }
        
        // Check for specific error types
        if let keychainError = error as? KeychainError {
            return .unknownError("Keychain error: \(keychainError.localizedDescription)")
        }
        
        if let openAIError = error as? OpenAIError {
            return .openAIError(openAIError.localizedDescription)
        }
        
        // Check for URL/Network errors
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return handleURLError(nsError)
        }
        
        // Default to unknown error
        return .unknownError(error.localizedDescription)
    }
    
    private func handleURLError(_ error: NSError) -> AppError {
        switch error.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost:
            return .networkError(error)
        case NSURLErrorTimedOut:
            return .networkError(error)
        case NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost:
            return .networkError(error)
        default:
            return .networkError(error)
        }
    }
    
    // MARK: - Retry Logic
    
    /// Retries an operation with exponential backoff
    func retry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry if it's not a retryable error
                if let openAIError = error as? OpenAIError, !openAIError.isRetryable {
                    throw error
                }
                
                // Don't sleep on last attempt
                if attempt < maxAttempts {
                    let backoffDelay = delay * pow(2.0, Double(attempt - 1))
                    Logger.shared.warning(
                        "Attempt \(attempt) failed, retrying in \(backoffDelay)s...",
                        category: .network
                    )
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
            }
        }
        
        // All attempts failed
        if let error = lastError {
            throw error
        } else {
            throw AppError.unknownError("Operation failed after \(maxAttempts) attempts")
        }
    }
}

// MARK: - SwiftUI Error Alert Modifier
extension View {
    /// Adds automatic error handling with alerts
    func withErrorHandling(errorHandler: ErrorHandler = .shared) -> some View {
        self.alert(
            "Error",
            isPresented: Binding(
                get: { errorHandler.showingError },
                set: { if !$0 { errorHandler.dismissError() } }
            ),
            presenting: errorHandler.currentError
        ) { _ in
            Button("OK") {
                errorHandler.dismissError()
            }
        } message: { error in
            VStack(alignment: .leading, spacing: 8) {
                Text(error.localizedDescription)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                }
            }
        }
    }
}
