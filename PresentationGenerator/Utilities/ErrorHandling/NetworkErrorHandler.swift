import Foundation

/// Handles network-related errors with retry logic and offline mode support
@MainActor
class NetworkErrorHandler {
    
    // MARK: - Properties
    
    private let maxRetries: Int
    private let baseDelay: TimeInterval
    private let maxDelay: TimeInterval
    
    // MARK: - Initialization
    
    init(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 60.0) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
    
    // MARK: - Retry Logic
    
    /// Executes a network operation with exponential backoff retry logic
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        shouldRetry: ((Error) -> Bool)? = nil
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Check if we should retry this error
                let shouldRetryError = shouldRetry?(error) ?? isRetriableError(error)
                
                // Don't retry on last attempt or non-retriable errors
                if attempt == maxRetries || !shouldRetryError {
                    throw error
                }
                
                // Calculate delay with exponential backoff
                let delay = calculateBackoffDelay(attempt: attempt)
                
                // Wait before retry
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // This should never be reached, but throw last error if it happens
        throw lastError ?? AppError.networkError("Maximum retries exceeded")
    }
    
    /// Determines if an error is retriable
    private func isRetriableError(_ error: Error) -> Bool {
        // Check for AppError types
        if let appError = error as? AppError {
            switch appError {
            case .networkError:
                return true
            case .apiError(let message):
                // Retry on server errors (5xx), but not client errors (4xx)
                return message.contains("500") || 
                       message.contains("502") || 
                       message.contains("503") || 
                       message.contains("504") ||
                       message.lowercased().contains("timeout") ||
                       message.lowercased().contains("connection")
            default:
                return false
            }
        }
        
        // Check for URLError types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .timedOut,
                 .cannotConnectToHost,
                 .dnsLookupFailed:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    /// Calculates exponential backoff delay
    private func calculateBackoffDelay(attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        return min(exponentialDelay + jitter, maxDelay)
    }
    
    // MARK: - Network Status
    
    /// Checks if network is available
    func isNetworkAvailable() -> Bool {
        // Simple check - assume network is available
        // In production, would use NWPathMonitor from Network framework
        return true
    }
    
    /// Waits for network to become available
    func waitForNetwork(timeout: TimeInterval = 30.0) async throws {
        let startTime = Date()
        
        while !isNetworkAvailable() {
            // Check timeout
            if Date().timeIntervalSince(startTime) > timeout {
                throw AppError.networkError("Network unavailable - timeout exceeded")
            }
            
            // Wait before checking again
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
    }
}
