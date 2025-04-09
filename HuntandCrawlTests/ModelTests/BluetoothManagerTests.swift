import XCTest
import CoreBluetooth
@testable import HuntandCrawl

class BluetoothManagerTests: XCTestCase {
    var bluetoothManager: BluetoothManager!
    var mockCentralManager: MockCentralManager!
    var mockPeripheralManager: MockPeripheralManager!
    
    override func setUpWithError() throws {
        mockCentralManager = MockCentralManager()
        mockPeripheralManager = MockPeripheralManager()
        bluetoothManager = BluetoothManager()
        
        // Inject mock managers
        bluetoothManager.centralManager = mockCentralManager
        bluetoothManager.peripheralManager = mockPeripheralManager
    }
    
    override func tearDownWithError() throws {
        bluetoothManager = nil
        mockCentralManager = nil
        mockPeripheralManager = nil
    }
    
    func testStartAdvertising() throws {
        // Test starting advertising
        bluetoothManager.startAdvertising()
        
        // Verify advertising is started
        XCTAssertTrue(mockPeripheralManager.isAdvertising)
        XCTAssertNotNil(mockPeripheralManager.advertisementData)
        
        // Verify service UUIDs are included
        if let services = mockPeripheralManager.advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            XCTAssertTrue(services.contains(bluetoothManager.serviceUUID))
        } else {
            XCTFail("No service UUIDs in advertisement data")
        }
    }
    
    func testStartScanning() throws {
        // Test starting scanning
        bluetoothManager.startScanning()
        
        // Verify scanning is started
        XCTAssertTrue(mockCentralManager.isScanning)
        
        // Verify service UUIDs are included
        XCTAssertEqual(mockCentralManager.scanServices?.count, 1)
        XCTAssertEqual(mockCentralManager.scanServices?.first, bluetoothManager.serviceUUID)
    }
    
    func testStopScanning() throws {
        // Start scanning
        bluetoothManager.startScanning()
        XCTAssertTrue(mockCentralManager.isScanning)
        
        // Stop scanning
        bluetoothManager.stopScanning()
        
        // Verify scanning is stopped
        XCTAssertFalse(mockCentralManager.isScanning)
    }
    
    func testDiscoverPeripheral() throws {
        // Create a mock peripheral
        let mockPeripheral = MockPeripheral(identifier: UUID())
        mockPeripheral.name = "TestDevice"
        
        // Simulate the discovery of a peripheral
        bluetoothManager.centralManager(mockCentralManager, didDiscover: mockPeripheral, advertisementData: [CBAdvertisementDataServiceUUIDsKey: [bluetoothManager.serviceUUID]], rssi: -50)
        
        // Verify the peripheral is added to nearby devices
        XCTAssertEqual(bluetoothManager.nearbyDevices.count, 1)
        XCTAssertEqual(bluetoothManager.nearbyDevices.first?.name, "TestDevice")
        XCTAssertEqual(bluetoothManager.nearbyDevices.first?.signalStrength, -50)
    }
    
    func testConnectToPeripheral() throws {
        // Create a mock peripheral
        let mockPeripheral = MockPeripheral(identifier: UUID())
        mockPeripheral.name = "TestDevice"
        
        // Simulate the discovery of a peripheral
        bluetoothManager.centralManager(mockCentralManager, didDiscover: mockPeripheral, advertisementData: [CBAdvertisementDataServiceUUIDsKey: [bluetoothManager.serviceUUID]], rssi: -50)
        
        // Connect to the discovered peripheral
        if let device = bluetoothManager.nearbyDevices.first {
            bluetoothManager.connectToDevice(device)
            
            // Verify that connect was called on the central manager
            XCTAssertTrue(mockCentralManager.didCallConnect)
            XCTAssertEqual(mockCentralManager.connectedPeripheral?.identifier, mockPeripheral.identifier)
        } else {
            XCTFail("No nearby devices found")
        }
        
        // Simulate successful connection
        bluetoothManager.centralManager(mockCentralManager, didConnect: mockPeripheral)
        
        // Verify the connection status
        XCTAssertEqual(bluetoothManager.connectedDevice?.peripheral.identifier, mockPeripheral.identifier)
        
        // Verify services discovery is initiated
        XCTAssertTrue(mockPeripheral.didCallDiscoverServices)
    }
    
    func testSendData() throws {
        // Setup connected peripheral
        let mockPeripheral = MockPeripheral(identifier: UUID())
        mockPeripheral.name = "TestDevice"
        
        // Create mock characteristic
        let mockCharacteristic = MockCharacteristic(uuid: bluetoothManager.messageCharacteristicUUID)
        
        // Add the characteristic to the peripheral
        mockPeripheral.mockCharacteristics[bluetoothManager.messageCharacteristicUUID] = mockCharacteristic
        
        // Create service with the characteristic
        let mockService = MockService(uuid: bluetoothManager.serviceUUID)
        mockService.characteristics = [mockCharacteristic]
        mockPeripheral.mockServices = [mockService]
        
        // Simulate discovery and connection
        bluetoothManager.centralManager(mockCentralManager, didDiscover: mockPeripheral, advertisementData: [:], rssi: -50)
        bluetoothManager.centralManager(mockCentralManager, didConnect: mockPeripheral)
        
        // Simulate service discovery
        bluetoothManager.peripheral(mockPeripheral, didDiscoverServices: nil)
        
        // Simulate characteristic discovery
        bluetoothManager.peripheral(mockPeripheral, didDiscoverCharacteristicsFor: mockService, error: nil)
        
        // Verify connected device is updated with the found characteristic
        XCTAssertNotNil(bluetoothManager.connectedDevice)
        XCTAssertEqual(bluetoothManager.connectedDevice?.messageCharacteristic?.uuid, bluetoothManager.messageCharacteristicUUID)
        
        // Test sending data
        let testData = "Test message".data(using: .utf8)!
        bluetoothManager.sendData(testData, toDevice: bluetoothManager.connectedDevice!)
        
        // Verify write was called on the peripheral
        XCTAssertTrue(mockPeripheral.didCallWriteValue)
        XCTAssertEqual(mockPeripheral.lastWrittenData, testData)
        XCTAssertEqual(mockPeripheral.lastWriteType, .withResponse)
    }
    
    func testReceiveData() throws {
        // Setup peripheral
        let mockPeripheral = MockPeripheral(identifier: UUID())
        
        // Create mock characteristic
        let mockCharacteristic = MockCharacteristic(uuid: bluetoothManager.messageCharacteristicUUID)
        
        // Add the characteristic to the peripheral
        mockPeripheral.mockCharacteristics[bluetoothManager.messageCharacteristicUUID] = mockCharacteristic
        
        // Create service with the characteristic
        let mockService = MockService(uuid: bluetoothManager.serviceUUID)
        mockService.characteristics = [mockCharacteristic]
        mockPeripheral.mockServices = [mockService]
        
        // Connect the peripheral
        bluetoothManager.centralManager(mockCentralManager, didConnect: mockPeripheral)
        
        // Simulate service discovery
        bluetoothManager.peripheral(mockPeripheral, didDiscoverServices: nil)
        
        // Simulate characteristic discovery
        bluetoothManager.peripheral(mockPeripheral, didDiscoverCharacteristicsFor: mockService, error: nil)
        
        // Set up message received expectation
        let expectation = self.expectation(description: "Receive data")
        var receivedMessage: Data?
        
        bluetoothManager.onMessageReceived = { message, _ in
            receivedMessage = message
            expectation.fulfill()
        }
        
        // Simulate receiving data
        let testData = "Test message".data(using: .utf8)!
        mockCharacteristic.mockValue = testData
        bluetoothManager.peripheral(mockPeripheral, didUpdateValueFor: mockCharacteristic, error: nil)
        
        // Wait for the async operation to complete
        waitForExpectations(timeout: 1.0)
        
        // Verify the received data
        XCTAssertEqual(receivedMessage, testData)
    }
    
    func testDisconnect() throws {
        // Setup connected peripheral
        let mockPeripheral = MockPeripheral(identifier: UUID())
        
        // Simulate the connection
        bluetoothManager.centralManager(mockCentralManager, didConnect: mockPeripheral)
        
        // Disconnect
        bluetoothManager.disconnect()
        
        // Verify disconnect was called
        XCTAssertTrue(mockCentralManager.didCallDisconnect)
        XCTAssertEqual(mockCentralManager.disconnectedPeripheral?.identifier, mockPeripheral.identifier)
        
        // Simulate successful disconnection
        bluetoothManager.centralManager(mockCentralManager, didDisconnectPeripheral: mockPeripheral, error: nil)
        
        // Verify connected device is cleared
        XCTAssertNil(bluetoothManager.connectedDevice)
    }
    
    func testCleanupOldDevices() throws {
        // Create mock devices with old timestamps
        let mockPeripheral1 = MockPeripheral(identifier: UUID())
        mockPeripheral1.name = "OldDevice"
        
        let mockPeripheral2 = MockPeripheral(identifier: UUID())
        mockPeripheral2.name = "NewDevice"
        
        // Add devices with different last seen times
        let oldTime = Date().addingTimeInterval(-300) // 5 minutes ago
        let newTime = Date()
        
        bluetoothManager.centralManager(mockCentralManager, didDiscover: mockPeripheral1, advertisementData: [:], rssi: -60)
        bluetoothManager.centralManager(mockCentralManager, didDiscover: mockPeripheral2, advertisementData: [:], rssi: -40)
        
        // Manually set the lastSeen time for testing
        if var device = bluetoothManager.nearbyDevices.first(where: { $0.name == "OldDevice" }) {
            device.lastSeen = oldTime
            bluetoothManager.nearbyDevices[bluetoothManager.nearbyDevices.firstIndex(where: { $0.name == "OldDevice" })!] = device
        }
        
        // Verify both devices are in the list
        XCTAssertEqual(bluetoothManager.nearbyDevices.count, 2)
        
        // Clean up old devices (devices older than 2 minutes)
        bluetoothManager.cleanupOldDevices(olderThan: 120) // 2 minutes
        
        // Verify old device is removed
        XCTAssertEqual(bluetoothManager.nearbyDevices.count, 1)
        XCTAssertEqual(bluetoothManager.nearbyDevices.first?.name, "NewDevice")
    }
}

// MARK: - Mock Classes for Testing

class MockCentralManager: CBCentralManager {
    var isScanning = false
    var scanServices: [CBUUID]?
    var scanOptions: [String: Any]?
    
    var didCallConnect = false
    var connectedPeripheral: CBPeripheral?
    
    var didCallDisconnect = false
    var disconnectedPeripheral: CBPeripheral?
    
    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        isScanning = true
        scanServices = serviceUUIDs
        scanOptions = options
    }
    
    override func stopScan() {
        isScanning = false
    }
    
    override func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        didCallConnect = true
        connectedPeripheral = peripheral
    }
    
    override func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        didCallDisconnect = true
        disconnectedPeripheral = peripheral
    }
}

class MockPeripheralManager: CBPeripheralManager {
    var isAdvertising = false
    var advertisementData: [String: Any] = [:]
    
    override func startAdvertising(_ advertisementData: [String : Any]?) {
        isAdvertising = true
        if let data = advertisementData {
            self.advertisementData = data
        }
    }
    
    override func stopAdvertising() {
        isAdvertising = false
        advertisementData = [:]
    }
}

class MockPeripheral: CBPeripheral {
    let identifier: UUID
    var mockServices: [CBService] = []
    var mockCharacteristics: [CBUUID: CBCharacteristic] = [:]
    
    var didCallDiscoverServices = false
    var didCallDiscoverCharacteristics = false
    var didCallWriteValue = false
    var lastWrittenData: Data?
    var lastWriteType: CBCharacteristicWriteType?
    
    init(identifier: UUID) {
        self.identifier = identifier
        super.init()
    }
    
    override var identifier: UUID {
        return self.identifier
    }
    
    override var services: [CBService]? {
        return mockServices
    }
    
    override func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        didCallDiscoverServices = true
    }
    
    override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        didCallDiscoverCharacteristics = true
    }
    
    override func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        didCallWriteValue = true
        lastWrittenData = data
        lastWriteType = type
    }
}

class MockService: CBService {
    let uuid: CBUUID
    var mockCharacteristics: [CBCharacteristic]?
    
    init(uuid: CBUUID) {
        self.uuid = uuid
        super.init()
    }
    
    override var uuid: CBUUID {
        return self.uuid
    }
    
    override var characteristics: [CBCharacteristic]? {
        get { return mockCharacteristics }
        set { mockCharacteristics = newValue }
    }
}

class MockCharacteristic: CBCharacteristic {
    let uuid: CBUUID
    var mockValue: Data?
    
    init(uuid: CBUUID) {
        self.uuid = uuid
        super.init()
    }
    
    override var uuid: CBUUID {
        return self.uuid
    }
    
    override var value: Data? {
        return mockValue
    }
} 