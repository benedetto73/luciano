import Foundation
import Network

/// Monitors network connectivity status
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
        
        var description: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .wiredEthernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring network connectivity
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(from: path)
                
                if path.status == .satisfied {
                    Logger.shared.info("Network connected via \(self?.connectionType.description ?? "unknown")", category: .network)
                } else {
                    Logger.shared.warning("Network disconnected", category: .network)
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /// Stops monitoring network connectivity (called from deinit - non-async)
    nonisolated private func cleanup() {
        monitor.cancel()
    }
    
    /// Stops monitoring network connectivity
    func stopMonitoring() {
        cleanup()
    }
    
    /// Checks if network is currently available
    var isNetworkAvailable: Bool {
        isConnected
    }
    
    /// Returns a user-friendly status message
    var statusMessage: String {
        if isConnected {
            return "Connected via \(connectionType.description)"
        } else {
            return "No internet connection"
        }
    }
    
    // MARK: - Private Methods
    
    private func updateConnectionType(from path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .unknown
        }
    }
}

// MARK: - Network Availability Check Extension
extension NetworkMonitor {
    /// Throws an error if network is not available
    func requireNetworkConnection() throws {
        guard isConnected else {
            throw AppError.networkError(
                NSError(
                    domain: "NetworkMonitor",
                    code: -1009,
                    userInfo: [NSLocalizedDescriptionKey: "No internet connection available"]
                )
            )
        }
    }
    
    /// Executes a block only if network is available
    func performIfConnected(_ action: () async throws -> Void) async throws {
        try requireNetworkConnection()
        try await action()
    }
}
