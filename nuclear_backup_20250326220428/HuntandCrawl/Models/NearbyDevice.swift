import Foundation
import CoreBluetooth

class NearbyDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    var rssi: Int
    var isConnected: Bool
    var peripheral: CBPeripheral
    var userId: UUID?
    var username: String?
    var lastSeen: Date
    
    init(id: UUID, name: String, rssi: Int, peripheral: CBPeripheral, userId: UUID? = nil, username: String? = nil) {
        self.id = id
        self.name = name
        self.rssi = rssi
        self.isConnected = false
        self.peripheral = peripheral
        self.userId = userId
        self.username = username
        self.lastSeen = Date()
    }
    
    func updateRSSI(_ newRSSI: Int) {
        self.rssi = newRSSI
        self.lastSeen = Date()
    }
    
    static func == (lhs: NearbyDevice, rhs: NearbyDevice) -> Bool {
        return lhs.id == rhs.id
    }
} 