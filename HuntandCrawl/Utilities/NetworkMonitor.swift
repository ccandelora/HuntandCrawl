import Foundation
import Network
import Combine
import Observation

@Observable
class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var isConnected: Bool = false
    var connectionType: NWInterface.InterfaceType = .other
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                let connectionTypes: [NWInterface.InterfaceType] = [.wifi, .cellular, .wiredEthernet]
                self?.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let connectivityStatusChanged = Notification.Name("connectivityStatusChanged")
} 