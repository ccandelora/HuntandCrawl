import XCTest
import CoreLocation
import Combine
@testable import HuntandCrawl

final class LocationManagerTests: XCTestCase {
    
    var locationManager: MockableLocationManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        // Initialize a mock Location manager for testing
        locationManager = MockableLocationManager()
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        locationManager = nil
    }
    
    func testAuthorizationStatusChanges() throws {
        // Test location authorization status changes
        let authExpectation = expectation(description: "Authorization status should change")
        
        // Monitor authorization status updates
        locationManager.$authorizationStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if status == .authorizedAlways {
                    authExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate authorization status change
        locationManager.simulateAuthorizationStatusChange(status: .authorizedAlways)
        
        // Wait for the expectation to be fulfilled
        wait(for: [authExpectation], timeout: 1.0)
    }
    
    func testLocationServicesEnabled() throws {
        // Test location services enabled status
        let servicesExpectation = expectation(description: "Location services status should change")
        
        // Monitor location services status updates
        locationManager.$isLocationServicesEnabled
            .dropFirst() // Skip initial value
            .sink { isEnabled in
                if isEnabled {
                    servicesExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate location services status change
        locationManager.simulateLocationServicesEnabledChange(enabled: true)
        
        // Wait for the expectation to be fulfilled
        wait(for: [servicesExpectation], timeout: 1.0)
    }
    
    func testLocationUpdate() throws {
        // Test receiving location updates
        let locationExpectation = expectation(description: "Location should update")
        
        // Monitor location updates
        locationManager.$userLocation
            .dropFirst() // Skip initial value
            .sink { location in
                if let location = location {
                    locationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate a location update
        let newLocation = CLLocation(latitude: 25.761681, longitude: -80.191788) // Miami
        locationManager.simulateLocationUpdate(location: newLocation)
        
        // Wait for the expectation to be fulfilled
        wait(for: [locationExpectation], timeout: 1.0)
        
        // Verify location was updated correctly
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 25.761681, accuracy: 0.0001)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, -80.191788, accuracy: 0.0001)
    }
    
    func testLocationUpdatesWhileMonitoring() throws {
        // Start monitoring location
        locationManager.startMonitoringLocation()
        
        // Test receiving location updates
        let locationExpectation = expectation(description: "Location should update multiple times")
        locationExpectation.expectedFulfillmentCount = 3
        
        // Monitor location updates
        locationManager.$userLocation
            .dropFirst() // Skip initial value
            .sink { _ in
                locationExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate multiple location updates
        let locations = [
            CLLocation(latitude: 25.761681, longitude: -80.191788), // Miami
            CLLocation(latitude: 40.712776, longitude: -74.005974), // New York
            CLLocation(latitude: 34.052235, longitude: -118.243683) // Los Angeles
        ]
        
        // Send the updates
        for location in locations {
            locationManager.simulateLocationUpdate(location: location)
        }
        
        // Wait for all updates to be processed
        wait(for: [locationExpectation], timeout: 2.0)
        
        // Verify the final location is correct
        XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 34.052235, accuracy: 0.0001)
        XCTAssertEqual(locationManager.userLocation?.coordinate.longitude, -118.243683, accuracy: 0.0001)
    }
    
    func testStopMonitoringLocation() throws {
        // Start monitoring location
        locationManager.startMonitoringLocation()
        
        // Verify monitoring is active
        XCTAssertTrue(locationManager.isMonitoring)
        
        // Stop monitoring location
        locationManager.stopMonitoringLocation()
        
        // Verify monitoring has stopped
        XCTAssertFalse(locationManager.isMonitoring)
        
        // Test that location updates no longer affect the user location
        let originalLocation = locationManager.userLocation
        
        // Simulate a location update
        let newLocation = CLLocation(latitude: 25.761681, longitude: -80.191788) // Miami
        locationManager.simulateLocationUpdate(location: newLocation)
        
        // Wait a short time for any processing to occur
        usleep(100000) // 0.1 seconds
        
        // Verify location was not updated
        XCTAssertEqual(locationManager.userLocation, originalLocation)
    }
    
    func testDistanceBetweenLocations() throws {
        // Test the distance calculation between two locations
        let location1 = CLLocation(latitude: 25.761681, longitude: -80.191788) // Miami
        let location2 = CLLocation(latitude: 40.712776, longitude: -74.005974) // New York
        
        // Calculate distance
        let distance = locationManager.distanceBetween(location1: location1, location2: location2)
        
        // The expected distance is approximately 1767 km / 1098 miles
        // We'll convert to miles for testing
        let distanceInMiles = distance / 1609.34
        
        // Verify the distance is correct (with some tolerance)
        XCTAssertEqual(distanceInMiles, 1098.0, accuracy: 10.0)
    }
    
    func testNearbyPoints() throws {
        // Set up the current location
        let currentLocation = CLLocation(latitude: 25.761681, longitude: -80.191788) // Miami
        locationManager.simulateLocationUpdate(location: currentLocation)
        
        // Define some points of interest
        let pointsOfInterest = [
            (name: "Point 1", coordinate: CLLocationCoordinate2D(latitude: 25.764, longitude: -80.195)), // Very close
            (name: "Point 2", coordinate: CLLocationCoordinate2D(latitude: 25.770, longitude: -80.187)), // Somewhat close
            (name: "Point 3", coordinate: CLLocationCoordinate2D(latitude: 40.712, longitude: -74.005))  // Very far (New York)
        ]
        
        // Test finding nearby points of interest
        let nearbyPoints = locationManager.findNearbyPoints(points: pointsOfInterest, maxDistance: 2000) // 2 km radius
        
        // Verify only the first two points are considered nearby
        XCTAssertEqual(nearbyPoints.count, 2)
        XCTAssertTrue(nearbyPoints.contains { $0.name == "Point 1" })
        XCTAssertTrue(nearbyPoints.contains { $0.name == "Point 2" })
        XCTAssertFalse(nearbyPoints.contains { $0.name == "Point 3" })
    }
    
    func testHeadingUpdates() throws {
        // Test receiving heading updates
        let headingExpectation = expectation(description: "Heading should update")
        
        // Monitor heading updates
        locationManager.$heading
            .dropFirst() // Skip initial value
            .sink { heading in
                if heading != nil {
                    headingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate a heading update
        let newHeading = CLHeading(magneticHeading: 45.0, trueHeading: 47.5, timestamp: Date(), headingAccuracy: 2.0, x: 1.0, y: 1.0, z: 1.0)
        locationManager.simulateHeadingUpdate(heading: newHeading)
        
        // Wait for the expectation to be fulfilled
        wait(for: [headingExpectation], timeout: 1.0)
        
        // Verify heading was updated correctly
        XCTAssertEqual(locationManager.heading?.trueHeading, 47.5, accuracy: 0.1)
        XCTAssertEqual(locationManager.heading?.magneticHeading, 45.0, accuracy: 0.1)
    }
}

// MARK: - Mock Classes for Testing

class MockableLocationManager: LocationManager {
    var isMonitoring = false
    
    override func startMonitoringLocation() {
        super.startMonitoringLocation()
        isMonitoring = true
    }
    
    override func stopMonitoringLocation() {
        super.stopMonitoringLocation()
        isMonitoring = false
    }
    
    func simulateLocationServicesEnabledChange(enabled: Bool) {
        isLocationServicesEnabled = enabled
    }
    
    func simulateAuthorizationStatusChange(status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
    
    func simulateLocationUpdate(location: CLLocation) {
        guard isMonitoring || userLocation == nil else { return }
        userLocation = location
    }
    
    func simulateHeadingUpdate(heading: CLHeading) {
        self.heading = heading
    }
    
    func findNearbyPoints<T>(points: [(name: String, coordinate: CLLocationCoordinate2D)], maxDistance: Double) -> [T] where T: Any {
        guard let userLocation = userLocation else { return [] }
        
        let nearbyPoints = points.filter { point in
            let pointLocation = CLLocation(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude)
            let distance = userLocation.distance(from: pointLocation)
            return distance <= maxDistance
        }
        
        return nearbyPoints as! [T]
    }
    
    func distanceBetween(location1: CLLocation, location2: CLLocation) -> Double {
        return location1.distance(from: location2)
    }
} 