import Foundation

/// Performance monitoring and optimization utilities
@MainActor
class PerformanceMonitor: ObservableObject {
    
    static let shared = PerformanceMonitor()
    
    @Published private(set) var metrics: [String: PerformanceMetric] = [:]
    
    private var timers: [String: Date] = [:]
    
    struct PerformanceMetric {
        let operationName: String
        let duration: TimeInterval
        let timestamp: Date
        let memoryUsage: UInt64?
        
        var formattedDuration: String {
            if duration < 0.001 {
                return String(format: "%.2f μs", duration * 1_000_000)
            } else if duration < 1.0 {
                return String(format: "%.2f ms", duration * 1000)
            } else {
                return String(format: "%.2f s", duration)
            }
        }
    }
    
    // MARK: - Timing Operations
    
    func startTimer(for operation: String) {
        timers[operation] = Date()
    }
    
    func endTimer(for operation: String) {
        guard let startTime = timers[operation] else {
            Logger.shared.warning("No start time found for operation: \(operation)", category: .performance)
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let metric = PerformanceMetric(
            operationName: operation,
            duration: duration,
            timestamp: Date(),
            memoryUsage: getMemoryUsage()
        )
        
        metrics[operation] = metric
        timers.removeValue(forKey: operation)
        
        Logger.shared.info(
            "⏱️ \(operation): \(metric.formattedDuration)",
            category: .performance
        )
        
        // Warn on slow operations
        if duration > 1.0 {
            Logger.shared.warning(
                "Slow operation detected: \(operation) took \(metric.formattedDuration)",
                category: .performance
            )
        }
    }
    
    /// Measures execution time of an async operation
    func measure<T>(_ operation: String, _ block: () async throws -> T) async rethrows -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation) }
        return try await block()
    }
    
    /// Measures execution time of a synchronous operation
    func measureSync<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        startTimer(for: operation)
        defer { endTimer(for: operation) }
        return try block()
    }
    
    // MARK: - Memory Monitoring
    
    func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    func getFormattedMemoryUsage() -> String {
        let bytes = getMemoryUsage()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - Reporting
    
    func generateReport() -> String {
        var report = "=== Performance Report ===\n"
        report += "Generated: \(Date())\n"
        report += "Memory Usage: \(getFormattedMemoryUsage())\n\n"
        
        let sortedMetrics = metrics.values.sorted { $0.timestamp > $1.timestamp }
        
        report += "Recent Operations:\n"
        for metric in sortedMetrics.prefix(20) {
            report += "  • \(metric.operationName): \(metric.formattedDuration)\n"
        }
        
        // Find slowest operations
        let slowest = metrics.values.sorted { $0.duration > $1.duration }.prefix(5)
        if !slowest.isEmpty {
            report += "\nSlowest Operations:\n"
            for metric in slowest {
                report += "  • \(metric.operationName): \(metric.formattedDuration)\n"
            }
        }
        
        return report
    }
    
    func logReport() {
        Logger.shared.info(generateReport(), category: .performance)
    }
    
    func clearMetrics() {
        metrics.removeAll()
        timers.removeAll()
    }
}

// MARK: - Image Cache Optimization

class ImageCache {
    static let shared = ImageCache()
    
    private var cache = NSCache<NSString, NSData>()
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100 MB
    private let maxCacheCount = 100
    
    init() {
        cache.totalCostLimit = maxCacheSize
        cache.countLimit = maxCacheCount
    }
    
    func set(_ data: Data, forKey key: String) {
        cache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }
    
    func get(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as Data?
    }
    
    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearAll() {
        cache.removeAllObjects()
    }
    
    func currentSize() -> Int {
        // Approximate - NSCache doesn't provide actual size
        return cache.totalCostLimit
    }
}

// MARK: - Debouncer for Performance

class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(_ action: @escaping () -> Void) {
        workItem?.cancel()
        
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

// MARK: - Batch Processor

actor BatchProcessor<T> {
    private var items: [T] = []
    private let batchSize: Int
    private let processor: ([T]) async throws -> Void
    
    init(batchSize: Int = 10, processor: @escaping ([T]) async throws -> Void) {
        self.batchSize = batchSize
        self.processor = processor
    }
    
    func add(_ item: T) async throws {
        items.append(item)
        
        if items.count >= batchSize {
            try await flush()
        }
    }
    
    func flush() async throws {
        guard !items.isEmpty else { return }
        
        let batch = items
        items.removeAll()
        
        try await processor(batch)
    }
}
