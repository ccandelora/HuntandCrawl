import XCTest
import CoreLocation
import Combine
@testable import HuntandCrawl

final class GeofencingManagerTests: XCTestCase {
    var geofencingManager: GeofencingManager!
    var mockCLLocationManager: MockCLLocationManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        mockCLLocationManager = MockCLLocationManager()
        mockCLLocationManager.mockLocationServicesEnabled = true
        MockCLLocationManager.authorizationStatusOverride = .authorizedWhenInUse
        
        geofencingManager = GeofencingManager()
        
        // Replace the CLLocationManager with our mock
        geofencingManager.locationManager = mockCLLocationManager
        mockCLLocationManager.delegate = geofencingManager
    }
    
    override func tearDownWithError() throws {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        mockCLLocationManager.reset()
        mockCLLocationManager = nil
        geofencingManager = nil
    }
    
    func testInitialState() {
        XCTAssertTrue(geofencingManager.monitoredRegions.isEmpty)
        XCTAssertEqual(geofencingManager.authorizationStatus, .authorizedWhenInUse)
    }
    
    func testStartMonitoring() {
        // Create expectation for region change
        let expectation = XCTestExpectation(description: "Region monitoring started")
        
        // Define a test geofence
        let testLocation = CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0)
        let identifier = "test-geofence"
        let regionRadius: CLLocationDistance = 100
        
        // Monitor changes to monitoredRegions
        geofencingManager.$monitoredRegions
            .dropFirst() // Skip initial value
            .sink { regions in
                if regions.contains(where: { $0.identifier == identifier }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start monitoring the region
        geofencingManager.startMonitoring(
            latitude: testLocation.latitude,
            longitude: testLocation.longitude,
            radius: regionRadius,
            identifier: identifier
        )
        
        // Verify expectation is fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the region was added to both our manager and the mock
        XCTAssertFalse(geofencingManager.monitoredRegions.isEmpty)
        XCTAssertTrue(geofencingManager.monitoredRegions.contains(where: { $0.identifier == identifier }))
        XCTAssertTrue(mockCLLocationManager.mockMonitoredRegions.contains(where: { $0.identifier == identifier }))
    }
    
    func testStopMonitoring() {
        // First add a region
        let testLocation = CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0)
        let identifier = "test-geofence"
        let regionRadius: CLLocationDistance = 100
        
        geofencingManager.startMonitoring(
            latitude: testLocation.latitude,
            longitude: testLocation.longitude,
            radius: regionRadius,
            identifier: identifier
        )
        
        // Create expectation for region removal
        let expectation = XCTestExpectation(description: "Region monitoring stopped")
        
        // Monitor changes to monitoredRegions
        geofencingManager.$monitoredRegions
            .dropFirst() // Skip initial value
            .sink { regions in
                if !regions.contains(where: { $0.identifier == identifier }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Stop monitoring the region
        geofencingManager.stopMonitoring(identifier: identifier)
        
        // Verify expectation is fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the region was removed
        XCTAssertFalse(geofencingManager.monitoredRegions.contains(where: { $0.identifier == identifier }))
        XCTAssertFalse(mockCLLocationManager.mockMonitoredRegions.contains(where: { $0.identifier == identifier }))
    }
    
    func testRegionEntry() {
        // Create expectation for region entry
        let expectation = XCTestExpectation(description: "Region entered")
        
        // Define a test geofence
        let testLocation = CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0)
        let identifier = "test-geofence-entry"
        let regionRadius: CLLocationDistance = 100
        
        // Add the region to monitored regions
        geofencingManager.startMonitoring(
            latitude: testLocation.latitude, 
            longitude: testLocation.longitude,
            radius: regionRadius, 
            identifier: identifier
        )
        
        // Find the region that was created
        let region = mockCLLocationManager.mockMonitoredRegions.first { $0.identifier == identifier } as? CLCircularRegion
        XCTAssertNotNil(region)
        
        // Set up observer for entered region
        geofencingManager.$regionsEntered
            .dropFirst() // Skip initial value
            .sink { regions in
                if regions.contains(where: { $0 == identifier }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate region entry
        mockCLLocationManager.simulateRegionEvent(
            region: region!,
            event: .didEnterRegion
        )
        
        // Verify expectation is fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify region was added to entered regions
        XCTAssertTrue(geofencingManager.regionsEntered.contains(identifier))
    }
    
    func testRegionExit() {
        // Create expectations
        let entryExpectation = XCTestExpectation(description: "Region entered")
        let exitExpectation = XCTestExpectation(description: "Region exited")
        
        // Define a test geofence
        let testLocation = CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0)
        let identifier = "test-geofence-exit"
        let regionRadius: CLLocationDistance = 100
        
        // Add the region to monitored regions
        geofencingManager.startMonitoring(
            latitude: testLocation.latitude,
            longitude: testLocation.longitude,
            radius: regionRadius,
            identifier: identifier
        )
        
        // Find the region that was created
        let region = mockCLLocationManager.mockMonitoredRegions.first { $0.identifier == identifier } as? CLCircularRegion
        XCTAssertNotNil(region)
        
        // Set up observer for entered region
        geofencingManager.$regionsEntered
            .dropFirst() // Skip initial value
            .sink { regions in
                if regions.contains(where: { $0 == identifier }) {
                    entryExpectation.fulfill()
                } else if !regions.contains(where: { $0 == identifier }) {
                    exitExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate region entry first
        mockCLLocationManager.simulateRegionEvent(
            region: region!,
            event: .didEnterRegion
        )
        
        // Verify entry expectation is fulfilled
        wait(for: [entryExpectation], timeout: 1.0)
        
        // Simulate region exit
        mockCLLocationManager.simulateRegionEvent(
            region: region!,
            event: .didExitRegion
        )
        
        // Verify exit expectation is fulfilled
        wait(for: [exitExpectation], timeout: 1.0)
        
        // Verify region was removed from entered regions
        XCTAssertFalse(geofencingManager.regionsEntered.contains(identifier))
    }
    
    func testIsUserInRegion() {
        // Define a test geofence
        let testLocation = CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0)
        let identifier = "test-region-check"
        let regionRadius: CLLocationDistance = 100
        
        // Add the region to monitored regions
        geofencingManager.startMonitoring(
            latitude: testLocation.latitude,
            longitude: testLocation.longitude,
            radius: regionRadius,
            identifier: identifier
        )
        
        // Find the region that was created
        let region = mockCLLocationManager.mockMonitoredRegions.first { $0.identifier == identifier } as? CLCircularRegion
        XCTAssertNotNil(region)
        
        // Initially user should not be in region
        XCTAssertFalse(geofencingManager.isUserInRegion(identifier: identifier))
        
        // Simulate region entry
        mockCLLocationManager.simulateRegionEvent(
            region: region!,
            event: .didEnterRegion
        )
        
        // Now user should be in region
        XCTAssertTrue(geofencingManager.isUserInRegion(identifier: identifier))
        
        // Simulate region exit
        mockCLLocationManager.simulateRegionEvent(
            region: region!,
            event: .didExitRegion
        )
        
        // User should no longer be in region
        XCTAssertFalse(geofencingManager.isUserInRegion(identifier: identifier))
    }
    
    func testClearAllRegions() {
        // Add multiple regions
        for i in 1...5 {
            let testLocation = CLLocationCoordinate2D(latitude: 25.0 + Double(i)/100, longitude: -80.0 + Double(i)/100)
            let identifier = "test-region-\(i)"
            let regionRadius: CLLocationDistance = 100
            
            geofencingManager.startMonitoring(
                latitude: testLocation.latitude,
                longitude: testLocation.longitude,
                radius: regionRadius,
                identifier: identifier
            )
        }
        
        // Verify regions were added
        XCTAssertEqual(geofencingManager.monitoredRegions.count, 5)
        XCTAssertEqual(mockCLLocationManager.mockMonitoredRegions.count, 5)
        
        // Create expectation for cleared regions
        let expectation = XCTestExpectation(description: "Regions cleared")
        
        // Monitor changes to monitoredRegions
        geofencingManager.$monitoredRegions
            .dropFirst() // Skip initial value
            .sink { regions in
                if regions.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Clear all regions
        geofencingManager.clearAllRegions()
        
        // Verify expectation is fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify all regions were removed
        XCTAssertTrue(geofencingManager.monitoredRegions.isEmpty)
        XCTAssertTrue(mockCLLocationManager.mockMonitoredRegions.isEmpty)
    }
} 