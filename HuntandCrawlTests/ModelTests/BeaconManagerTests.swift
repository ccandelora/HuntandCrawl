import XCTest
import CoreLocation
@testable import HuntandCrawl

class BeaconManagerTests: XCTestCase {
    var beaconManager: BeaconManager!
    var mockLocationManager: MockCLLocationManager!
    
    override func setUpWithError() throws {
        mockLocationManager = MockCLLocationManager()
        beaconManager = BeaconManager()
        beaconManager.locationManager = mockLocationManager
    }
    
    override func tearDownWithError() throws {
        beaconManager = nil
        mockLocationManager = nil
    }
    
    func testInitialization() throws {
        // Test that the beacon manager initializes properly
        XCTAssertNotNil(beaconManager)
        XCTAssertNotNil(beaconManager.locationManager)
        XCTAssertEqual(beaconManager.detectedBeacons.count, 0)
        XCTAssertFalse(beaconManager.isMonitoring)
    }
    
    func testStartMonitoring() throws {
        // Test starting monitoring
        beaconManager.startMonitoring()
        
        // Verify monitoring is started
        XCTAssertTrue(beaconManager.isMonitoring)
        
        // Verify location manager properly set up
        XCTAssertTrue(mockLocationManager.isAuthorizationRequested)
        
        // Simulate authorization granted
        beaconManager.locationManager(mockLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        // Verify region monitoring started
        XCTAssertTrue(mockLocationManager.isRegionMonitoringStarted)
        XCTAssertEqual(mockLocationManager.monitoredRegions.count, beaconManager.beaconRegions.count)
    }
    
    func testStopMonitoring() throws {
        // Start monitoring first
        beaconManager.startMonitoring()
        XCTAssertTrue(beaconManager.isMonitoring)
        
        // Grant authorization
        beaconManager.locationManager(mockLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        XCTAssertTrue(mockLocationManager.isRegionMonitoringStarted)
        
        // Test stopping monitoring
        beaconManager.stopMonitoring()
        
        // Verify monitoring is stopped
        XCTAssertFalse(beaconManager.isMonitoring)
        XCTAssertTrue(mockLocationManager.isRegionMonitoringStopped)
    }
    
    func testLocationAuthorizationDenied() throws {
        // Start monitoring
        beaconManager.startMonitoring()
        
        // Simulate authorization denied
        beaconManager.locationManager(mockLocationManager, didChangeAuthorization: .denied)
        
        // Verify that monitoring remains off due to denied authorization
        XCTAssertFalse(mockLocationManager.isRegionMonitoringStarted)
        XCTAssertEqual(beaconManager.authorizationStatus, .denied)
    }
    
    func testBeaconDetection() throws {
        // Set up a beacon region and beacon
        let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        let beaconRegion = CLBeaconRegion(
            uuid: beaconUUID,
            identifier: "TestBeaconRegion"
        )
        let beacon = MockCLBeacon(
            uuid: beaconUUID,
            major: 1,
            minor: 1,
            proximity: .immediate,
            accuracy: 0.5,
            rssi: -50
        )
        
        // Start monitoring
        beaconManager.startMonitoring()
        beaconManager.locationManager(mockLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        // Simulate region entry
        beaconManager.locationManager(mockLocationManager, didEnterRegion: beaconRegion)
        
        // Verify ranging is started
        XCTAssertTrue(mockLocationManager.isRangingStarted)
        XCTAssertEqual(mockLocationManager.rangedRegions.count, 1)
        
        // Simulate beacon detection
        beaconManager.locationManager(mockLocationManager, didRangeBeacons: [beacon], in: beaconRegion)
        
        // Verify beacon is detected and stored
        XCTAssertEqual(beaconManager.detectedBeacons.count, 1)
        XCTAssertEqual(beaconManager.detectedBeacons.first?.proximityUUID, beaconUUID)
        XCTAssertEqual(beaconManager.detectedBeacons.first?.major, 1)
        XCTAssertEqual(beaconManager.detectedBeacons.first?.minor, 1)
        XCTAssertEqual(beaconManager.nearestBeacon?.proximityUUID, beaconUUID)
    }
    
    func testRegionExit() throws {
        // Set up a beacon region
        let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        let beaconRegion = CLBeaconRegion(
            uuid: beaconUUID,
            identifier: "TestBeaconRegion"
        )
        
        // Start monitoring
        beaconManager.startMonitoring()
        beaconManager.locationManager(mockLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        // Simulate region entry
        beaconManager.locationManager(mockLocationManager, didEnterRegion: beaconRegion)
        XCTAssertTrue(mockLocationManager.isRangingStarted)
        
        // Simulate region exit
        beaconManager.locationManager(mockLocationManager, didExitRegion: beaconRegion)
        
        // Verify ranging is stopped
        XCTAssertTrue(mockLocationManager.isRangingStopped)
    }
    
    func testCleanupOldBeacons() throws {
        // Add test beacons with different timestamps
        let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        let oldBeacon = MockCLBeacon(
            uuid: beaconUUID,
            major: 1,
            minor: 1,
            proximity: .immediate,
            accuracy: 0.5,
            rssi: -50
        )
        let newBeacon = MockCLBeacon(
            uuid: beaconUUID,
            major: 2,
            minor: 2,
            proximity: .immediate,
            accuracy: 0.5,
            rssi: -50
        )
        
        // Add beacons to the detected beacons list
        let beaconRegion = CLBeaconRegion(
            uuid: beaconUUID,
            identifier: "TestBeaconRegion"
        )
        beaconManager.locationManager(mockLocationManager, didRangeBeacons: [oldBeacon, newBeacon], in: beaconRegion)
        
        // Verify both beacons were added
        XCTAssertEqual(beaconManager.detectedBeacons.count, 2)
        
        // Manipulate lastSeen time for the old beacon
        let oldTime = Date().addingTimeInterval(-300) // 5 minutes ago
        beaconManager.detectedBeacons[0].lastSeen = oldTime
        
        // Call cleanup method
        beaconManager.cleanupOldBeacons(olderThan: 120) // 2 minutes
        
        // Verify old beacon was removed
        XCTAssertEqual(beaconManager.detectedBeacons.count, 1)
        XCTAssertEqual(beaconManager.detectedBeacons.first?.major, 2)
    }
    
    func testIsNearTaskLocation() throws {
        // Create a task with a location
        let taskLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let task = Task(name: "Test Task", pointValue: 10, verificationMethod: .location)
        task.latitude = taskLocation.latitude
        task.longitude = taskLocation.longitude
        
        // Set up a beacon UUID that matches a task location
        let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        task.beaconUUID = beaconUUID.uuidString
        
        // Create a matching beacon
        let beacon = MockCLBeacon(
            uuid: beaconUUID,
            major: 1,
            minor: 1,
            proximity: .immediate,
            accuracy: 0.5,
            rssi: -50
        )
        
        // Add the beacon to detected beacons
        let beaconRegion = CLBeaconRegion(
            uuid: beaconUUID,
            identifier: "TestBeaconRegion"
        )
        beaconManager.locationManager(mockLocationManager, didRangeBeacons: [beacon], in: beaconRegion)
        
        // Verify beacon is detected
        XCTAssertEqual(beaconManager.detectedBeacons.count, 1)
        
        // Test proximity check
        XCTAssertTrue(beaconManager.isNearTaskLocation(task))
        
        // Test with a different task UUID
        let differentTask = Task(name: "Different Task", pointValue: 5, verificationMethod: .location)
        differentTask.beaconUUID = UUID().uuidString
        
        // Verify not near different task
        XCTAssertFalse(beaconManager.isNearTaskLocation(differentTask))
    }
    
    func testIsNearBarStop() throws {
        // Create a bar stop with a location
        let barStopLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let barStop = BarStop(name: "Test Bar", specialDrink: "Test Drink", drinkPrice: 10.0)
        barStop.latitude = barStopLocation.latitude
        barStop.longitude = barStopLocation.longitude
        
        // Set up a beacon UUID that matches a bar stop location
        let beaconUUID = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
        barStop.beaconUUID = beaconUUID.uuidString
        
        // Create a matching beacon
        let beacon = MockCLBeacon(
            uuid: beaconUUID,
            major: 1,
            minor: 1,
            proximity: .immediate,
            accuracy: 0.5,
            rssi: -50
        )
        
        // Add the beacon to detected beacons
        let beaconRegion = CLBeaconRegion(
            uuid: beaconUUID,
            identifier: "TestBeaconRegion"
        )
        beaconManager.locationManager(mockLocationManager, didRangeBeacons: [beacon], in: beaconRegion)
        
        // Verify beacon is detected
        XCTAssertEqual(beaconManager.detectedBeacons.count, 1)
        
        // Test proximity check
        XCTAssertTrue(beaconManager.isNearBarStop(barStop))
        
        // Test with a different bar stop UUID
        let differentBarStop = BarStop(name: "Different Bar", specialDrink: "Different Drink", drinkPrice: 5.0)
        differentBarStop.beaconUUID = UUID().uuidString
        
        // Verify not near different bar stop
        XCTAssertFalse(beaconManager.isNearBarStop(differentBarStop))
    }
}

// MARK: - Mock Classes for Testing

class MockCLLocationManager: CLLocationManager {
    var isAuthorizationRequested = false
    var isRegionMonitoringStarted = false
    var isRegionMonitoringStopped = false
    var isRangingStarted = false
    var isRangingStopped = false
    
    var monitoredRegions: Set<CLRegion> = []
    var rangedRegions: Set<CLBeaconRegion> = []
    
    override func requestWhenInUseAuthorization() {
        isAuthorizationRequested = true
    }
    
    override func startMonitoring(for region: CLRegion) {
        isRegionMonitoringStarted = true
        monitoredRegions.insert(region)
    }
    
    override func stopMonitoring(for region: CLRegion) {
        isRegionMonitoringStopped = true
        monitoredRegions.remove(region)
    }
    
    override func startRangingBeacons(in region: CLBeaconRegion) {
        isRangingStarted = true
        rangedRegions.insert(region)
    }
    
    override func stopRangingBeacons(in region: CLBeaconRegion) {
        isRangingStopped = true
        rangedRegions.remove(region)
    }
}

class MockCLBeacon: CLBeacon {
    private let _proximityUUID: UUID
    private let _major: NSNumber
    private let _minor: NSNumber
    private let _proximity: CLProximity
    private let _accuracy: CLLocationAccuracy
    private let _rssi: Int
    
    init(uuid: UUID, major: UInt16, minor: UInt16, proximity: CLProximity, accuracy: CLLocationAccuracy, rssi: Int) {
        self._proximityUUID = uuid
        self._major = NSNumber(value: major)
        self._minor = NSNumber(value: minor)
        self._proximity = proximity
        self._accuracy = accuracy
        self._rssi = rssi
        super.init()
    }
    
    override var proximityUUID: UUID {
        return _proximityUUID
    }
    
    override var major: NSNumber {
        return _major
    }
    
    override var minor: NSNumber {
        return _minor
    }
    
    override var proximity: CLProximity {
        return _proximity
    }
    
    override var accuracy: CLLocationAccuracy {
        return _accuracy
    }
    
    override var rssi: Int {
        return _rssi
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
} 