import XCTest
import CoreLocation
import MapKit
@testable import HuntandCrawl

class LocationManagerTests: XCTestCase {
    var locationManager: LocationManager!
    var mockCLLocationManager: MockCLLocationManager!
    
    override func setUpWithError() throws {
        mockCLLocationManager = MockCLLocationManager()
        locationManager = LocationManager()
        locationManager.clLocationManager = mockCLLocationManager
    }
    
    override func tearDownWithError() throws {
        locationManager = nil
        mockCLLocationManager = nil
    }
    
    func testInitialization() throws {
        // Test that location manager initializes properly
        XCTAssertNotNil(locationManager)
        XCTAssertNotNil(locationManager.clLocationManager)
        XCTAssertFalse(locationManager.locationServicesEnabled)
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined)
    }
    
    func testStartUpdatingLocation() throws {
        // Test starting location updates
        locationManager.startUpdatingLocation()
        
        // Verify location authorization is requested
        XCTAssertTrue(mockCLLocationManager.isAuthorizationRequested)
        
        // Simulate authorization granted
        locationManager.locationManagerDidChangeAuthorization(mockCLLocationManager)
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        locationManager.locationManagerDidChangeAuthorization(mockCLLocationManager)
        
        // Verify location updates started
        XCTAssertTrue(mockCLLocationManager.isLocationUpdatesStarted)
    }
    
    func testStopUpdatingLocation() throws {
        // Start updates first
        locationManager.startUpdatingLocation()
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        locationManager.locationManagerDidChangeAuthorization(mockCLLocationManager)
        
        // Verify location updates started
        XCTAssertTrue(mockCLLocationManager.isLocationUpdatesStarted)
        
        // Test stopping location updates
        locationManager.stopUpdatingLocation()
        
        // Verify location updates stopped
        XCTAssertTrue(mockCLLocationManager.isLocationUpdatesStopped)
    }
    
    func testLocationAuthorization() throws {
        // Test authorization denied
        mockCLLocationManager.mockAuthorizationStatus = .denied
        locationManager.locationManagerDidChangeAuthorization(mockCLLocationManager)
        
        // Verify authorization status is updated
        XCTAssertEqual(locationManager.authorizationStatus, .denied)
        XCTAssertFalse(locationManager.locationServicesEnabled)
        
        // Test authorization granted
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        locationManager.locationManagerDidChangeAuthorization(mockCLLocationManager)
        
        // Verify authorization status is updated
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
        XCTAssertTrue(locationManager.locationServicesEnabled)
    }
    
    func testLocationUpdate() throws {
        // Start location updates
        locationManager.startUpdatingLocation()
        mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
        locationManager.locationManagerDidChangeAuthorization(mockCLLocationManager)
        
        // Create a mock location
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let mockLocation = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())
        
        // Simulate location update
        locationManager.locationManager(mockCLLocationManager, didUpdateLocations: [mockLocation])
        
        // Verify location is updated
        XCTAssertEqual(locationManager.lastLocation?.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(locationManager.lastLocation?.coordinate.longitude, coordinate.longitude)
        XCTAssertNotNil(locationManager.lastLocationUpdateTime)
    }
    
    func testDistanceToCoordinate() throws {
        // Set current location
        let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let mockLocation = CLLocation(coordinate: sanFrancisco, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())
        locationManager.lastLocation = mockLocation
        
        // Test location in San Francisco
        let nearbySF = CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195)
        XCTAssertLessThan(locationManager.distanceTo(nearbySF), 100) // Should be less than 100 meters
        
        // Test distance to New York
        let newYork = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let expectedDistance = 4125000.0 // ~4125 km in meters with some tolerance
        let actualDistance = locationManager.distanceTo(newYork)
        XCTAssertTrue(abs(actualDistance - expectedDistance) < 100000) // Within 100km tolerance due to simplified calculation
    }
    
    func testIsNearCoordinate() throws {
        // Set current location
        let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let mockLocation = CLLocation(coordinate: sanFrancisco, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())
        locationManager.lastLocation = mockLocation
        
        // Test nearby location (within 100 meters)
        let nearbySF = CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195)
        XCTAssertTrue(locationManager.isNear(coordinate: nearbySF, radius: 100))
        
        // Test far location (not within 100 meters)
        let farFromSF = CLLocationCoordinate2D(latitude: 37.8000, longitude: -122.4300)
        XCTAssertFalse(locationManager.isNear(coordinate: farFromSF, radius: 100))
    }
    
    func testGetRegionForTask() throws {
        // Create a task with location
        let task = Task(name: "Test Task", pointValue: 10, verificationMethod: .location)
        task.latitude = 37.7749
        task.longitude = -122.4194
        task.completionRadius = 100
        
        // Get region for task
        let region = locationManager.getRegion(for: task)
        
        // Verify region is created with correct parameters
        XCTAssertNotNil(region)
        XCTAssertEqual(region.center.latitude, 37.7749)
        XCTAssertEqual(region.center.longitude, -122.4194)
        XCTAssertEqual(region.radius, 100)
        XCTAssertTrue(region.identifier.contains("task-"))
    }
    
    func testGetRegionForBarStop() throws {
        // Create a bar stop with location
        let barStop = BarStop(name: "Test Bar", specialDrink: "Test Drink", drinkPrice: 10.0)
        barStop.latitude = 37.7749
        barStop.longitude = -122.4194
        barStop.checkInRadius = 50
        
        // Get region for bar stop
        let region = locationManager.getRegion(for: barStop)
        
        // Verify region is created with correct parameters
        XCTAssertNotNil(region)
        XCTAssertEqual(region.center.latitude, 37.7749)
        XCTAssertEqual(region.center.longitude, -122.4194)
        XCTAssertEqual(region.radius, 50)
        XCTAssertTrue(region.identifier.contains("barstop-"))
    }
    
    func testLocationError() throws {
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Simulate location error
        let error = NSError(domain: "LocationError", code: 1, userInfo: nil)
        locationManager.locationManager(mockCLLocationManager, didFailWithError: error)
        
        // Verify error is handled (locationEnabled should be false)
        XCTAssertFalse(locationManager.locationServicesEnabled)
    }
    
    func testMapForCoordinate() throws {
        // Create a coordinate
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Get map region for coordinate
        let mapRegion = locationManager.mapRegion(for: coordinate, spanDelta: 0.01)
        
        // Verify map region is created correctly
        XCTAssertEqual(mapRegion.center.latitude, coordinate.latitude)
        XCTAssertEqual(mapRegion.center.longitude, coordinate.longitude)
        XCTAssertEqual(mapRegion.span.latitudeDelta, 0.01)
        XCTAssertEqual(mapRegion.span.longitudeDelta, 0.01)
    }
    
    func testIsTaskInRange() throws {
        // Set current location
        let currentLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let mockLocation = CLLocation(coordinate: currentLocation, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())
        locationManager.lastLocation = mockLocation
        
        // Create a task within range
        let nearbyTask = Task(name: "Nearby Task", pointValue: 10, verificationMethod: .location)
        nearbyTask.latitude = 37.7750
        nearbyTask.longitude = -122.4195
        nearbyTask.completionRadius = 100
        
        // Create a task out of range
        let farTask = Task(name: "Far Task", pointValue: 5, verificationMethod: .location)
        farTask.latitude = 37.8000
        farTask.longitude = -122.4300
        farTask.completionRadius = 100
        
        // Test task proximity
        XCTAssertTrue(locationManager.isTaskInRange(nearbyTask))
        XCTAssertFalse(locationManager.isTaskInRange(farTask))
    }
    
    func testIsBarStopInRange() throws {
        // Set current location
        let currentLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let mockLocation = CLLocation(coordinate: currentLocation, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())
        locationManager.lastLocation = mockLocation
        
        // Create a bar stop within range
        let nearbyBar = BarStop(name: "Nearby Bar", specialDrink: "Test Drink", drinkPrice: 10.0)
        nearbyBar.latitude = 37.7750
        nearbyBar.longitude = -122.4195
        nearbyBar.checkInRadius = 100
        
        // Create a bar stop out of range
        let farBar = BarStop(name: "Far Bar", specialDrink: "Test Drink", drinkPrice: 5.0)
        farBar.latitude = 37.8000
        farBar.longitude = -122.4300
        farBar.checkInRadius = 100
        
        // Test bar stop proximity
        XCTAssertTrue(locationManager.isBarStopInRange(nearbyBar))
        XCTAssertFalse(locationManager.isBarStopInRange(farBar))
    }
}

// Extended mock class for LocationManager tests
extension MockCLLocationManager {
    var isLocationUpdatesStarted = false
    var isLocationUpdatesStopped = false
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override var authorizationStatus: CLAuthorizationStatus {
        return mockAuthorizationStatus
    }
    
    override func startUpdatingLocation() {
        isLocationUpdatesStarted = true
    }
    
    override func stopUpdatingLocation() {
        isLocationUpdatesStopped = true
    }
} 