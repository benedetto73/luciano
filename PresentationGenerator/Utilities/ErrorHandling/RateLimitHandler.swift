import Foundation

/// Handles API rate limiting with token bucket algorithm and request queuing
@MainActor
class RateLimitHandler {
    
    // MARK: - Properties
    
    private var tokenBucket: TokenBucket
    private var requestQueue: [QueuedRequest] = []
    private var isProcessingQueue = false
    
    // Rate limit tracking
    private var rateLimitInfo: RateLimitInfo?
    
    // MARK: - Types
    
    struct RateLimitInfo {
        let limit: Int
        let remaining: Int
        let resetTime: Date
    }
    
    struct QueuedRequest {
        let id: UUID
        let operation: () async throws -> Void
        let priority: Priority
        let addedAt: Date
        
        enum Priority: Int, Comparable {
            case low = 0
            case normal = 1
            case high = 2
            
            static func < (lhs: Priority, rhs: Priority) -> Bool {
                lhs.rawValue < rhs.rawValue
            }
        }
    }
    
    // MARK: - Initialization
    
    init(requestsPerMinute: Int = 60, requestsPerDay: Int = 10000) {
        self.tokenBucket = TokenBucket(
            capacity: requestsPerMinute,
            refillRate: Double(requestsPerMinute) / 60.0
        )
    }
    
    // MARK: - Request Execution
    
    /// Executes a request with rate limiting
    func executeRequest<T>(
        priority: QueuedRequest.Priority = .normal,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Try to acquire token
        if tokenBucket.tryConsume() {
            return try await operation()
        }
        
        // Queue the request if no tokens available
        return try await withCheckedThrowingContinuation { continuation in
            let request = QueuedRequest(
                id: UUID(),
                operation: {
                    do {
                        let result = try await operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                },
                priority: priority,
                addedAt: Date()
            )
            
            requestQueue.append(request)
            requestQueue.sort { $0.priority > $1.priority || ($0.priority == $1.priority && $0.addedAt < $1.addedAt) }
            
            Task {
                await processQueue()
            }
        }
    }
    
    /// Processes queued requests
    private func processQueue() async {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true
        
        defer { isProcessingQueue = false }
        
        while !requestQueue.isEmpty {
            // Wait for token availability
            await tokenBucket.waitForToken()
            
            // Get next request
            guard let request = requestQueue.first else { break }
            requestQueue.removeFirst()
            
            // Execute request
            do {
                try await request.operation()
            } catch {
                // Log error but continue processing queue
                print("Queued request failed: \(error)")
            }
        }
    }
    
    // MARK: - Rate Limit Info
    
    /// Updates rate limit information from API response headers
    func updateRateLimitInfo(limit: Int?, remaining: Int?, resetTime: Date?) {
        guard let limit = limit,
              let remaining = remaining,
              let resetTime = resetTime else {
            return
        }
        
        rateLimitInfo = RateLimitInfo(
            limit: limit,
            remaining: remaining,
            resetTime: resetTime
        )
        
        // Token bucket will be adjusted through refill process
    }
    
    /// Handles rate limit exceeded error
    func handleRateLimitExceeded(retryAfter: TimeInterval?) async throws {
        let waitTime = retryAfter ?? calculateWaitTime()
        
        // Notify user
        NotificationCenter.default.post(
            name: .rateLimitExceeded,
            object: nil,
            userInfo: ["waitTime": waitTime]
        )
        
        // Wait before retrying
        try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        
        // Refill tokens
        tokenBucket.refill()
    }
    
    /// Calculates wait time based on rate limit info
    private func calculateWaitTime() -> TimeInterval {
        guard let info = rateLimitInfo else {
            return 60.0 // Default 1 minute
        }
        
        let timeUntilReset = info.resetTime.timeIntervalSinceNow
        return max(timeUntilReset, 0)
    }
    
    // MARK: - Queue Management
    
    /// Returns current queue size
    var queueSize: Int {
        requestQueue.count
    }
    
    /// Clears the request queue
    func clearQueue() {
        requestQueue.removeAll()
    }
}

// MARK: - Token Bucket

/// Token bucket algorithm for rate limiting
class TokenBucket {
    
    let capacity: Int
    let refillRate: Double // tokens per second
    
    private(set) var currentTokens: Int
    private var lastRefillTime: Date
    
    init(capacity: Int, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.currentTokens = capacity
        self.lastRefillTime = Date()
    }
    
    /// Attempts to consume a token
    func tryConsume() -> Bool {
        refill()
        
        if currentTokens > 0 {
            currentTokens -= 1
            return true
        }
        
        return false
    }
    
    /// Waits for a token to become available
    func waitForToken() async {
        while !tryConsume() {
            // Calculate wait time for next token
            let waitTime = 1.0 / refillRate
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
    }
    
    /// Refills tokens based on elapsed time
    func refill() {
        let now = Date()
        let timeSinceLastRefill = now.timeIntervalSince(lastRefillTime)
        let tokensToAdd = Int(timeSinceLastRefill * refillRate)
        
        if tokensToAdd > 0 {
            currentTokens = min(currentTokens + tokensToAdd, capacity)
            lastRefillTime = now
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let rateLimitExceeded = Notification.Name("rateLimitExceeded")
}
