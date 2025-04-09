import XCTest
import CoreLocation
import Combine
@testable import HuntandCrawl

final class LocationManagerTests: XCTestCase {
    var locationManager: LocationManager!
    var mockCLLocationManager: MockCLLocationManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        mockCLLocationManager = MockCLLocationManager()
        locationManager = LocationManager()
        
        // Replace the CLLocationManager with our mock
        locationManager.locationManager = mockCLLocationManager
        mockCLLocationManager.delegate = locationManager
    }
    
    override func tearDownWithError() throws {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        mockCLLocationManager.reset()
        mockCLLocationManager = nil
        locationManager = nil
    }
    
    func testInitialState() {
        XCTAssertFalse(locationManager.isLocationServicesEnabled)
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined)
        XCTAssertNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userHeading, 0)
    }
    
    func testLocationAuthorization() {
        // Create expectation for authorization change
        let expectation = XCTestExpectation(description: "Authorization status changed")
        
        // Monitor for changes
        locationManager.$authorizationStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if status == .authorizedWhenInUse {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Request authorization
        locationManager.requestLocationPermission()
        
        // Verify expectation is fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify final state
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
    }
    
    func testLocationUpdates() {
        // Set up authorized state
        MockCLLocationManager.authorizationStatusOverride = .authorizedWhenInUse
        locationManager.checkLocationAuthorization()
        
        // Create expectation for location update
        let expectation = XCTestExpectation(description: "Location updated")
        
        // Set up test location
        let testLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0),
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        // Monitor for changes
        locationManager.$userLocation
            .dropFirst() // Skip initial value
            .sink { location in
                if let location = location, 
                   location.coordinate.latitude == testLocation.coordinate.latitude,
                   location.coordinate.longitude == testLocation.coordinate.longitude {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start location updates
        locationManager.startLocationUpdates()
        
        // Simulate location update
        mockCLLocationManager.simulateLocationUpdate(location: testLocation)
        
        // Verify expectation is fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify final state
        XCTAssertNotNil(locationManager.userLocation)
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, testLocation.coordinate.latitude)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, testLocation.coordinate.longitude)
    }
    
    func testHeadingUpdates() {
        // Set up authorized state
        MockCLLocationManager.authorizationStatusOverride = .authorizedWhenInUse
        locationManager.checkLocationAuthorization()
        
        // Create expectation for heading update
        let expectation = XCTestExpectation(description: "Heading updated")
        
        // Create a test heading
        let mockHeading = MockCLHeading(magneticHeading: 45.0)
        
        // Monitor for changes
        locationManager.$userHeading
            .dropFirst() // Skip initial value
            .sink { heading in
                if heading == 45.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start heading updates
        locationManager.startLocationUpdates()
        
        // Simulate heading update
        mockCLLocationManager.simulateHeadingUpdate(heading: mockHeading)
        
        // Verify expectation is fulfilled
        wait(for: [expectation], timeout: 1.0)
        
        // Verify final state
        XCTAssertEqual(locationManager.userHeading, 45.0)
    }
    
    func testDistanceCalculation() {
        // Create two locations
        let cruiseLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0),
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        let otherLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 25.001, longitude: -80.001),
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        // Set user location
        mockCLLocationManager.simulateLocationUpdate(location: cruiseLocation)
        
        // Calculate distance
        let distance = locationManager.distanceToCoordinate(latitude: otherLocation.coordinate.latitude, longitude: otherLocation.coordinate.longitude)
        
        // Calculate expected distance
        let expectedDistance = cruiseLocation.distance(from: otherLocation)
        
        // Verify distance calculation
        XCTAssertEqual(distance, expectedDistance, accuracy: 0.1)
    }
    
    func testIsUserNearCoordinate() {
        // Create user location
        let cruiseLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0),
            altitude: 10.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )
        
        // Set user location
        mockCLLocationManager.simulateLocationUpdate(location: cruiseLocation)
        
        // Test within range (100m)
        let nearbyResult = locationManager.isUserNearCoordinate(latitude: 25.0001, longitude: -80.0001, radius: 100)
        XCTAssertTrue(nearbyResult)
        
        // Test outside range
        let farResult = locationManager.isUserNearCoordinate(latitude: 25.01, longitude: -80.01, radius: 100)
        XCTAssertFalse(farResult)
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization() {
        // Simulate initial state
        mockCLLocationManager.mockAuthorizationStatus = .notDetermined
        
        // Check initial state
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined)
        XCTAssertFalse(locationManager.isAuthorized)
        
        // Request authorization
        locationManager.requestAuthorization()
        
        // Verify request was made
        XCTAssertTrue(mockCLLocationManager.didRequestWhenInUseAuthorization)
        
        // Simulate authorization granted
        mockCLLocationManager.simulateAuthorizationStatusChange(to: .authorizedWhenInUse)
        
        // Verify state changes
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
        XCTAssertTrue(locationManager.isAuthorized)
    }
    
    func testAuthorizationDenied() {
        // Simulate initial state
        mockCLLocationManager.mockAuthorizationStatus = .notDetermined
        
        // Request authorization
        locationManager.requestAuthorization()
        
        // Simulate authorization denied
        mockCLLocationManager.simulateAuthorizationStatusChange(to: .denied)
        
        // Verify state changes
        XCTAssertEqual(locationManager.authorizationStatus, .denied)
        XCTAssertFalse(locationManager.isAuthorized)
    }
    
    // MARK: - Location Tracking Tests
    
    func testStartLocationTracking() {
        // Simulate authorized state
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Start tracking
        locationManager.startLocationTracking()
        
        // Verify tracking is started
        XCTAssertTrue(mockCLLocationManager.isUpdatingLocation)
        XCTAssertTrue(locationManager.isTrackingLocation)
    }
    
    func testStopLocationTracking() {
        // Simulate tracking
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        locationManager.startLocationTracking()
        
        // Stop tracking
        locationManager.stopLocationTracking()
        
        // Verify tracking is stopped
        XCTAssertFalse(mockCLLocationManager.isUpdatingLocation)
        XCTAssertFalse(locationManager.isTrackingLocation)
    }
    
    func testLocationUpdate() {
        // Simulate authorized state
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Start tracking
        locationManager.startLocationTracking()
        
        // Create expectation for location update
        let expectation = self.expectation(description: "Location update received")
        
        // Add observer for location changes
        var receivedLocation: CLLocation?
        let cancellable = locationManager.$currentLocation.dropFirst().sink { location in
            receivedLocation = location
            expectation.fulfill()
        }
        
        // Simulate location update
        let mockLocation = CLLocation(latitude: 25.0, longitude: -80.0)
        mockCLLocationManager.simulateLocationUpdate(locations: [mockLocation])
        
        // Wait for expectation
        waitForExpectations(timeout: 1)
        
        // Verify location was updated
        XCTAssertNotNil(receivedLocation)
        XCTAssertEqual(receivedLocation?.coordinate.latitude, 25.0, accuracy: 0.0001)
        XCTAssertEqual(receivedLocation?.coordinate.longitude, -80.0, accuracy: 0.0001)
        
        // Clean up
        cancellable.cancel()
    }
    
    // MARK: - Geofencing Tests
    
    func testStartMonitoringRegion() {
        // Simulate authorized state
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Create a task with location
        let task = Task(
            title: "Visit the beach",
            description: "Go to the beach",
            points: 50,
            verificationMethod: .location,
            latitude: 25.123,
            longitude: -80.456,
            checkInRadius: 100
        )
        
        // Start monitoring
        locationManager.startMonitoringTask(task)
        
        // Verify region is being monitored
        XCTAssertEqual(mockCLLocationManager.monitoredRegions.count, 1)
        
        // Get the monitored region
        guard let region = mockCLLocationManager.monitoredRegions.first as? CLCircularRegion else {
            XCTFail("No monitored region found")
            return
        }
        
        // Verify region properties
        XCTAssertEqual(region.identifier, task.id)
        XCTAssertEqual(region.center.latitude, task.latitude ?? 0, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, task.longitude ?? 0, accuracy: 0.0001)
        XCTAssertEqual(region.radius, task.checkInRadius ?? 0, accuracy: 0.0001)
    }
    
    func testStopMonitoringRegion() {
        // Simulate authorized state and existing region
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Create a task with location
        let task = Task(
            title: "Visit the beach",
            description: "Go to the beach",
            points: 50,
            verificationMethod: .location,
            latitude: 25.123,
            longitude: -80.456,
            checkInRadius: 100
        )
        
        // Start monitoring
        locationManager.startMonitoringTask(task)
        
        // Verify region is being monitored
        XCTAssertEqual(mockCLLocationManager.monitoredRegions.count, 1)
        
        // Stop monitoring
        locationManager.stopMonitoringTask(task)
        
        // Verify region is no longer monitored
        XCTAssertEqual(mockCLLocationManager.monitoredRegions.count, 0)
    }
    
    func testRegionEnter() {
        // Simulate authorized state
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Create a task with location
        let task = Task(
            id: "task123",
            title: "Visit the beach",
            description: "Go to the beach",
            points: 50,
            verificationMethod: .location,
            latitude: 25.123,
            longitude: -80.456,
            checkInRadius: 100
        )
        
        // Start monitoring
        locationManager.startMonitoringTask(task)
        
        // Create expectation for region enter event
        let expectation = self.expectation(description: "Region enter event received")
        
        // Add observer for region enter
        var enteredRegionId: String?
        let cancellable = locationManager.$enteredRegionIds.dropFirst().sink { regionIds in
            enteredRegionId = regionIds.first
            expectation.fulfill()
        }
        
        // Simulate region enter
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 25.123, longitude: -80.456),
            radius: 100,
            identifier: task.id
        )
        mockCLLocationManager.simulateRegionEnter(region: region)
        
        // Wait for expectation
        waitForExpectations(timeout: 1)
        
        // Verify region entered event was processed
        XCTAssertNotNil(enteredRegionId)
        XCTAssertEqual(enteredRegionId, task.id)
        XCTAssertTrue(locationManager.isInRegion(taskId: task.id))
        
        // Clean up
        cancellable.cancel()
    }
    
    func testRegionExit() {
        // Simulate authorized state and being in a region
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        
        // Create a task with location
        let task = Task(
            id: "task123",
            title: "Visit the beach",
            description: "Go to the beach",
            points: 50,
            verificationMethod: .location,
            latitude: 25.123,
            longitude: -80.456,
            checkInRadius: 100
        )
        
        // Start monitoring and simulate already being in the region
        locationManager.startMonitoringTask(task)
        locationManager.enteredRegionIds.insert(task.id)
        
        // Verify we're in the region
        XCTAssertTrue(locationManager.isInRegion(taskId: task.id))
        
        // Create expectation for region exit event
        let expectation = self.expectation(description: "Region exit event received")
        
        // Add observer for region exit
        var isInRegion = true
        let cancellable = locationManager.$enteredRegionIds.dropFirst().sink { regionIds in
            isInRegion = regionIds.contains(task.id)
            expectation.fulfill()
        }
        
        // Simulate region exit
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 25.123, longitude: -80.456),
            radius: 100,
            identifier: task.id
        )
        mockCLLocationManager.simulateRegionExit(region: region)
        
        // Wait for expectation
        waitForExpectations(timeout: 1)
        
        // Verify region exit event was processed
        XCTAssertFalse(isInRegion)
        XCTAssertFalse(locationManager.isInRegion(taskId: task.id))
        
        // Clean up
        cancellable.cancel()
    }
    
    // MARK: - Distance Calculation Tests
    
    func testDistanceToCoordinate() {
        // Set current location
        let currentLocation = CLLocation(latitude: 25.0, longitude: -80.0)
        locationManager.currentLocation = currentLocation
        
        // Calculate distance to another coordinate
        let targetCoordinate = CLLocationCoordinate2D(latitude: 25.1, longitude: -80.1)
        let distance = locationManager.distanceToCoordinate(targetCoordinate)
        
        // Expected distance (approximately 15.7 km)
        let expectedDistance = currentLocation.distance(from: CLLocation(
            latitude: targetCoordinate.latitude,
            longitude: targetCoordinate.longitude
        ))
        
        // Verify distance calculation
        XCTAssertEqual(distance, expectedDistance, accuracy: 1.0)
    }
    
    func testIsWithinRange() {
        // Set current location
        let currentLocation = CLLocation(latitude: 25.0, longitude: -80.0)
        locationManager.currentLocation = currentLocation
        
        // Test coordinate within range (less than 100m)
        let nearbyCoordinate = CLLocationCoordinate2D(latitude: 25.0001, longitude: -80.0001)
        XCTAssertTrue(locationManager.isWithinRange(of: nearbyCoordinate, range: 100))
        
        // Test coordinate outside range (more than 100m)
        let farCoordinate = CLLocationCoordinate2D(latitude: 25.01, longitude: -80.01)
        XCTAssertFalse(locationManager.isWithinRange(of: farCoordinate, range: 100))
    }
    
    func testIsWithinRangeOfTask() {
        // Set current location
        let currentLocation = CLLocation(latitude: 25.0, longitude: -80.0)
        locationManager.currentLocation = currentLocation
        
        // Create task with location near current location
        let nearbyTask = Task(
            title: "Nearby Task",
            description: "This task is nearby",
            points: 10,
            verificationMethod: .location,
            latitude: 25.0001,
            longitude: -80.0001,
            checkInRadius: 100
        )
        
        // Create task with location far from current location
        let farTask = Task(
            title: "Far Task",
            description: "This task is far away",
            points: 10,
            verificationMethod: .location,
            latitude: 25.01,
            longitude: -80.01,
            checkInRadius: 100
        )
        
        // Test nearby task
        XCTAssertTrue(locationManager.isWithinRange(of: nearbyTask))
        
        // Test far task
        XCTAssertFalse(locationManager.isWithinRange(of: farTask))
    }
}

// Mock CLHeading class for testing
class MockCLHeading: CLHeading {
    private let _magneticHeading: CLLocationDirection
    
    init(magneticHeading: CLLocationDirection) {
        self._magneticHeading = magneticHeading
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var magneticHeading: CLLocationDirection {
        return _magneticHeading
    }
    
    override var trueHeading: CLLocationDirection {
        return _magneticHeading
    }
} 