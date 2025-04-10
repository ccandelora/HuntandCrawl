import XCTest
import CoreBluetooth
import Combine
@testable import HuntandCrawl

final class BluetoothManagerTests: XCTestCase {
    
    var bluetoothManager: MockableBluetoothManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        // Initialize a mock Bluetooth manager for testing
        bluetoothManager = MockableBluetoothManager()
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        bluetoothManager = nil
    }
    
    func testBluetoothStateAuthorization() throws {
        // Test Bluetooth state changes
        let stateExpectation = expectation(description: "Bluetooth state should change")
        
        // Monitor Bluetooth state updates
        bluetoothManager.$isBluetoothEnabled
            .dropFirst() // Skip initial value
            .sink { isEnabled in
                if isEnabled {
                    stateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate Bluetooth state change
        bluetoothManager.simulateBluetoothStateChange(state: .poweredOn)
        
        // Wait for the expectation to be fulfilled
        wait(for: [stateExpectation], timeout: 1.0)
        
        // Test authorization status changes
        let authExpectation = expectation(description: "Authorization status should change")
        
        // Monitor authorization status updates
        bluetoothManager.$authorizationStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if status == .allowedAlways {
                    authExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate authorization status change
        bluetoothManager.simulateAuthorizationStatusChange(status: .allowedAlways)
        
        // Wait for the expectation to be fulfilled
        wait(for: [authExpectation], timeout: 1.0)
    }
    
    func testScanningForDevices() throws {
        // Test starting scanning for devices
        let scanningExpectation = expectation(description: "Scanning state should change")
        
        // Monitor scanning state updates
        bluetoothManager.$isScanning
            .dropFirst() // Skip initial value
            .sink { isScanning in
                if isScanning {
                    scanningExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start scanning
        bluetoothManager.startScanning()
        
        // Wait for the expectation to be fulfilled
        wait(for: [scanningExpectation], timeout: 1.0)
        
        // Test stopping scanning
        let stoppedScanningExpectation = expectation(description: "Scanning state should change to stopped")
        
        // Monitor scanning state updates again
        bluetoothManager.$isScanning
            .dropFirst() // Skip the current value
            .sink { isScanning in
                if !isScanning {
                    stoppedScanningExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Stop scanning
        bluetoothManager.stopScanning()
        
        // Wait for the expectation to be fulfilled
        wait(for: [stoppedScanningExpectation], timeout: 1.0)
    }
    
    func testAdvertisingServices() throws {
        // Test starting advertising services
        let advertisingExpectation = expectation(description: "Advertising state should change")
        
        // Monitor advertising state updates
        bluetoothManager.$isAdvertising
            .dropFirst() // Skip initial value
            .sink { isAdvertising in
                if isAdvertising {
                    advertisingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start advertising
        bluetoothManager.startAdvertising()
        
        // Wait for the expectation to be fulfilled
        wait(for: [advertisingExpectation], timeout: 1.0)
        
        // Test stopping advertising
        let stoppedAdvertisingExpectation = expectation(description: "Advertising state should change to stopped")
        
        // Monitor advertising state updates again
        bluetoothManager.$isAdvertising
            .dropFirst() // Skip the current value
            .sink { isAdvertising in
                if !isAdvertising {
                    stoppedAdvertisingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Stop advertising
        bluetoothManager.stopAdvertising()
        
        // Wait for the expectation to be fulfilled
        wait(for: [stoppedAdvertisingExpectation], timeout: 1.0)
    }
    
    func testDiscoveringNearbyDevices() throws {
        // Test discovering a device
        let discoveryExpectation = expectation(description: "Device should be discovered")
        
        // Monitor nearby devices updates
        bluetoothManager.$nearbyDevices
            .dropFirst() // Skip initial value
            .sink { devices in
                if devices.count > 0 {
                    discoveryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate finding a device
        let mockPeripheral = MockCBPeripheral(identifier: UUID(), name: "Test Device")
        bluetoothManager.simulateDiscoveredDevice(peripheral: mockPeripheral, rssi: -50)
        
        // Wait for the expectation to be fulfilled
        wait(for: [discoveryExpectation], timeout: 1.0)
        
        // Verify the device was added
        XCTAssertEqual(bluetoothManager.nearbyDevices.count, 1)
        XCTAssertEqual(bluetoothManager.nearbyDevices.first?.name, "Test Device")
    }
    
    func testConnectingToDevice() throws {
        // First, simulate discovering a device
        let mockPeripheral = MockCBPeripheral(identifier: UUID(), name: "Test Device")
        bluetoothManager.simulateDiscoveredDevice(peripheral: mockPeripheral, rssi: -50)
        
        // Verify the device was added
        XCTAssertEqual(bluetoothManager.nearbyDevices.count, 1)
        
        // Get the device
        let device = bluetoothManager.nearbyDevices.first!
        
        // Test connecting to the device
        let connectionExpectation = expectation(description: "Connection state should change")
        
        // Connect to the device
        bluetoothManager.connect(to: device)
        
        // Simulate successful connection
        bluetoothManager.simulateDeviceConnection(device: device)
        
        // Monitor device connection status
        bluetoothManager.$nearbyDevices
            .dropFirst() // Skip initial value
            .sink { devices in
                if let device = devices.first, device.isConnected {
                    connectionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Wait for the expectation to be fulfilled
        wait(for: [connectionExpectation], timeout: 1.0)
        
        // Verify the device is now connected
        XCTAssertTrue(bluetoothManager.nearbyDevices.first!.isConnected)
    }
    
    func testSendingData() throws {
        // First, simulate discovering and connecting to a device
        let mockPeripheral = MockCBPeripheral(identifier: UUID(), name: "Test Device")
        bluetoothManager.simulateDiscoveredDevice(peripheral: mockPeripheral, rssi: -50)
        
        // Get the device
        let device = bluetoothManager.nearbyDevices.first!
        
        // Connect to the device
        bluetoothManager.connect(to: device)
        bluetoothManager.simulateDeviceConnection(device: device)
        
        // Prepare test data
        let testData = "Test message".data(using: .utf8)!
        
        // Test sending data
        let sentExpectation = expectation(description: "Data should be sent")
        
        // Set up the mock to notify when data is sent
        bluetoothManager.onDataSent = {
            sentExpectation.fulfill()
        }
        
        // Send data
        bluetoothManager.sendData(testData, to: device, characteristic: bluetoothManager.messageCharacteristicUUID)
        
        // Wait for the expectation to be fulfilled
        wait(for: [sentExpectation], timeout: 1.0)
        
        // Verify data was sent
        XCTAssertEqual(bluetoothManager.lastSentData, testData)
    }
    
    func testReceivingData() throws {
        // First, simulate discovering and connecting to a device
        let mockPeripheral = MockCBPeripheral(identifier: UUID(), name: "Test Device")
        bluetoothManager.simulateDiscoveredDevice(peripheral: mockPeripheral, rssi: -50)
        
        // Get the device
        let device = bluetoothManager.nearbyDevices.first!
        
        // Connect to the device
        bluetoothManager.connect(to: device)
        bluetoothManager.simulateDeviceConnection(device: device)
        
        // Prepare test message data
        let messageData = "Test message".data(using: .utf8)!
        
        // Test receiving data
        let dataReceived = expectation(description: "Data should be received")
        
        // Set up notification to know when data is received
        NotificationCenter.default.addObserver(forName: .bluetoothDataReceived, object: nil, queue: nil) { notification in
            if let receivedData = notification.userInfo?["data"] as? Data,
               String(data: receivedData, encoding: .utf8) == "Test message" {
                dataReceived.fulfill()
            }
        }
        
        // Simulate receiving data
        bluetoothManager.simulateDataReceived(data: messageData, from: device)
        
        // Wait for the expectation to be fulfilled
        wait(for: [dataReceived], timeout: 1.0)
    }
    
    func testDisconnectingFromDevice() throws {
        // First, simulate discovering and connecting to a device
        let mockPeripheral = MockCBPeripheral(identifier: UUID(), name: "Test Device")
        bluetoothManager.simulateDiscoveredDevice(peripheral: mockPeripheral, rssi: -50)
        
        // Get the device
        let device = bluetoothManager.nearbyDevices.first!
        
        // Connect to the device
        bluetoothManager.connect(to: device)
        bluetoothManager.simulateDeviceConnection(device: device)
        
        // Verify the device is connected
        XCTAssertTrue(bluetoothManager.nearbyDevices.first!.isConnected)
        
        // Test disconnecting from the device
        let disconnectionExpectation = expectation(description: "Disconnection should occur")
        
        // Monitor device disconnection
        bluetoothManager.$nearbyDevices
            .dropFirst() // Skip initial value
            .sink { devices in
                if let device = devices.first, !device.isConnected {
                    disconnectionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Disconnect from the device
        bluetoothManager.disconnect(from: device)
        
        // Simulate the disconnection
        bluetoothManager.simulateDeviceDisconnection(device: device)
        
        // Wait for the expectation to be fulfilled
        wait(for: [disconnectionExpectation], timeout: 1.0)
        
        // Verify the device is now disconnected
        XCTAssertFalse(bluetoothManager.nearbyDevices.first!.isConnected)
    }
}

// MARK: - Mock Classes for Testing

class MockCBPeripheral: CBPeripheral {
    private let mockIdentifier: UUID
    private let mockName: String?
    
    init(identifier: UUID, name: String? = nil) {
        self.mockIdentifier = identifier
        self.mockName = name
        super.init()
    }
    
    override var identifier: UUID {
        return mockIdentifier
    }
    
    override var name: String? {
        return mockName
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Extension to BluetoothManager for testing
class MockableBluetoothManager: BluetoothManager {
    var onDataSent: (() -> Void)?
    var lastSentData: Data?
    
    func simulateBluetoothStateChange(state: CBManagerState) {
        isBluetoothEnabled = state == .poweredOn
    }
    
    func simulateAuthorizationStatusChange(status: CBManagerAuthorization) {
        authorizationStatus = status
    }
    
    func simulateDiscoveredDevice(peripheral: CBPeripheral, rssi: NSNumber) {
        // Create a new NearbyDevice
        let device = NearbyDevice(
            id: peripheral.identifier,
            name: peripheral.name ?? "Unknown Device",
            rssi: rssi.intValue
        )
        
        // Check if device already exists
        if !nearbyDevices.contains(where: { $0.id == device.id }) {
            // Add to the devices list
            nearbyDevices.append(device)
        }
    }
    
    func simulateDeviceConnection(device: NearbyDevice) {
        // Find the device in the list
        if let index = nearbyDevices.firstIndex(where: { $0.id == device.id }) {
            // Update connection status
            nearbyDevices[index].isConnected = true
            
            // This triggers @Published updates
            objectWillChange.send()
        }
    }
    
    func simulateDeviceDisconnection(device: NearbyDevice) {
        // Find the device in the list
        if let index = nearbyDevices.firstIndex(where: { $0.id == device.id }) {
            // Update connection status
            nearbyDevices[index].isConnected = false
            
            // This triggers @Published updates
            objectWillChange.send()
        }
    }
    
    override func sendData(_ data: Data, to device: NearbyDevice, characteristic: CBUUID) {
        // Store the data for verification
        lastSentData = data
        
        // Call the callback
        onDataSent?()
    }
    
    func simulateDataReceived(data: Data, from device: NearbyDevice) {
        // Post a notification with the received data
        NotificationCenter.default.post(
            name: .bluetoothDataReceived,
            object: self,
            userInfo: ["data": data, "deviceId": device.id]
        )
    }
} 