import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    // Service and characteristic UUIDs
    let serviceUUID = CBUUID(string: "5A27C360-89AB-4F12-A4A3-8D7B1C0CE850")
    let messageCharacteristicUUID = CBUUID(string: "5A27D890-89AB-4F12-A4A3-8D7B1C0CE850")
    let presenceCharacteristicUUID = CBUUID(string: "5A27E912-89AB-4F12-A4A3-8D7B1C0CE850")
    
    // Core Bluetooth objects
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var discoveredPeripherals = [CBPeripheral]()
    var connectedPeripherals = [CBPeripheral]()
    private var messageCharacteristic: CBCharacteristic?
    private var service: CBService?
    
    // Published properties for UI updates
    @Published var isScanning = false
    @Published var isAdvertising = false
    @Published var nearbyDevices = [NearbyDevice]()
    @Published var isBluetoothEnabled = false
    @Published var authorizationStatus: CBManagerAuthorization = .notDetermined
    
    // UserInfo for advertising
    var userId: UUID?
    var username: String?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Central Role Methods (Scanning/Connecting)
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to device: NearbyDevice) {
        guard let peripheral = discoveredPeripherals.first(where: { $0.identifier == device.id }) else { return }
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect(from device: NearbyDevice) {
        guard let peripheral = connectedPeripherals.first(where: { $0.identifier == device.id }) else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // Disconnect from all connected devices
    func disconnectFromAllDevices() {
        for peripheral in connectedPeripherals {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
    }
    
    // MARK: - Peripheral Role Methods (Advertising)
    
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn,
              let userId = userId,
              let username = username else { return }
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        // Message characteristic (read, write, notify)
        let messageCharacteristic = CBMutableCharacteristic(
            type: messageCharacteristicUUID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        // Presence characteristic with user info (read only)
        let userInfoData = try? JSONEncoder().encode([
            "userId": userId.uuidString,
            "username": username
        ])
        
        let presenceCharacteristic = CBMutableCharacteristic(
            type: presenceCharacteristicUUID,
            properties: [.read],
            value: userInfoData,
            permissions: [.readable]
        )
        
        service.characteristics = [messageCharacteristic, presenceCharacteristic]
        peripheralManager.add(service)
        
        // Start advertising
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "HuntandCrawl"
        ])
        
        isAdvertising = true
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        isAdvertising = false
    }
    
    // MARK: - Data Transfer
    
    // Method for sending data specifying the characteristic
    func sendData(_ data: Data, to device: NearbyDevice, characteristic: CBUUID) {
        guard let peripheral = connectedPeripherals.first(where: { $0.identifier == device.id }),
              let characteristic = peripheral.services?
                .compactMap({ $0.characteristics })
                .flatMap({ $0 })
                .first(where: { $0.uuid == characteristic }) else {
            print("Cannot find peripheral or characteristic to send data")
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    // Method for sending data without specifying characteristic (uses message characteristic)
    func sendData(_ data: Data, to peripheral: CBPeripheral) {
        guard let services = peripheral.services,
              let service = services.first(where: { $0.uuid == serviceUUID }),
              let characteristics = service.characteristics,
              let messageChar = characteristics.first(where: { $0.uuid == messageCharacteristicUUID }) else {
            print("Message characteristic not found")
            return
        }
        
        peripheral.writeValue(data, for: messageChar, type: .withResponse)
    }
    
    // Method to send data to all connected devices
    func sendDataToAllConnectedDevices(_ data: Data) {
        for peripheral in connectedPeripherals {
            sendData(data, to: peripheral)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothEnabled = central.state == .poweredOn
        authorizationStatus = CBManager.authorization
        
        if central.state == .poweredOn && isScanning {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if we already discovered this peripheral
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            
            // Create a NearbyDevice
            let device = NearbyDevice(
                id: peripheral.identifier,
                name: peripheral.name ?? "Unknown Device",
                rssi: RSSI.intValue,
                peripheral: peripheral
            )
            
            // Add to the devices list
            if !nearbyDevices.contains(where: { $0.id == device.id }) {
                nearbyDevices.append(device)
            }
        } else {
            // Update RSSI for existing device
            if let index = nearbyDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                nearbyDevices[index].rssi = RSSI.intValue
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Add to connected peripherals if not already there
        if !connectedPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            connectedPeripherals.append(peripheral)
        }
        
        // Update device connection status
        if let index = nearbyDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            nearbyDevices[index].isConnected = true
        }
        
        // Set delegate and discover services
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Remove from connected peripherals
        connectedPeripherals.removeAll { $0.identifier == peripheral.identifier }
        
        // Update device connection status
        if let index = nearbyDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            nearbyDevices[index].isConnected = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral), error: \(String(describing: error))")
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("Error discovering characteristics: \(error!)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == messageCharacteristicUUID {
                self.messageCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            
            if characteristic.uuid == presenceCharacteristicUUID {
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error updating value for characteristic: \(error!)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        if characteristic.uuid == messageCharacteristicUUID {
            // Notify that data was received
            NotificationCenter.default.post(
                name: .bluetoothDataReceived,
                object: self,
                userInfo: [
                    "data": data,
                    "deviceId": peripheral.identifier
                ]
            )
        } else if characteristic.uuid == presenceCharacteristicUUID {
            // Try to parse user info
            if let userInfo = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let userId = userInfo["userId"],
               let username = userInfo["username"] {
                
                // Update device with user info
                if let index = nearbyDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
                    nearbyDevices[index].userId = UUID(uuidString: userId)
                    nearbyDevices[index].username = username
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing data to peripheral: \(error)")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        isBluetoothEnabled = peripheral.state == .poweredOn
        
        if peripheral.state == .poweredOn && isAdvertising {
            startAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("Error adding service: \(error)")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Error starting advertising: \(error)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == presenceCharacteristicUUID,
           let userId = userId,
           let username = username {
            
            // Prepare user info data
            let userInfoData = try? JSONEncoder().encode([
                "userId": userId.uuidString,
                "username": username
            ])
            
            request.value = userInfoData
            peripheral.respond(to: request, withResult: .success)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == messageCharacteristicUUID,
               let data = request.value {
                
                // Notify that data was received
                NotificationCenter.default.post(
                    name: .bluetoothDataReceived,
                    object: self,
                    userInfo: ["data": data]
                )
                
                peripheral.respond(to: request, withResult: .success)
            } else {
                peripheral.respond(to: request, withResult: .requestNotSupported)
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let bluetoothDataReceived = Notification.Name("bluetoothDataReceived")
} 