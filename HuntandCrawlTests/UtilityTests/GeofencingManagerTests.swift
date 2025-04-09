import XCTest
import CoreLocation
import Combine
@testable import HuntandCrawl

final class GeofencingManagerTests: XCTestCase {
    
    var geofencingManager: MockableGeofencingManager!
    var locationManager: MockableLocationManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        // Initialize a mock Location manager for testing
        locationManager = MockableLocationManager()
        
        // Initialize a mock Geofencing manager with the mock location manager
        geofencingManager = MockableGeofencingManager(locationManager: locationManager)
    }
    
    override func tearDownWithError() throws {
        cancellables.removeAll()
        geofencingManager = nil
        locationManager = nil
    }
    
    func testAddGeofence() throws {
        // Add a geofence
        let identifier = "test-geofence-1"
        let coordinate = CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788) // Miami
        let radius: CLLocationDistance = 100.0
        
        geofencingManager.addGeofence(identifier: identifier, coordinate: coordinate, radius: radius)
        
        // Verify the geofence was added
        XCTAssertEqual(geofencingManager.monitoredRegions.count, 1)
        XCTAssertTrue(geofencingManager.monitoredRegions.contains { $0.identifier == identifier })
    }
    
    func testRemoveGeofence() throws {
        // First, add a geofence
        let identifier = "test-geofence-1"
        let coordinate = CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788) // Miami
        let radius: CLLocationDistance = 100.0
        
        geofencingManager.addGeofence(identifier: identifier, coordinate: coordinate, radius: radius)
        
        // Verify the geofence was added
        XCTAssertEqual(geofencingManager.monitoredRegions.count, 1)
        
        // Remove the geofence
        geofencingManager.removeGeofence(identifier: identifier)
        
        // Verify the geofence was removed
        XCTAssertEqual(geofencingManager.monitoredRegions.count, 0)
    }
    
    func testAddMultipleGeofences() throws {
        // Add multiple geofences
        let geofences = [
            (identifier: "test-geofence-1", coordinate: CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788), radius: 100.0),
            (identifier: "test-geofence-2", coordinate: CLLocationCoordinate2D(latitude: 40.712776, longitude: -74.005974), radius: 150.0),
            (identifier: "test-geofence-3", coordinate: CLLocationCoordinate2D(latitude: 34.052235, longitude: -118.243683), radius: 200.0)
        ]
        
        for geofence in geofences {
            geofencingManager.addGeofence(identifier: geofence.identifier, coordinate: geofence.coordinate, radius: geofence.radius)
        }
        
        // Verify all geofences were added
        XCTAssertEqual(geofencingManager.monitoredRegions.count, 3)
        for geofence in geofences {
            XCTAssertTrue(geofencingManager.monitoredRegions.contains { $0.identifier == geofence.identifier })
        }
    }
    
    func testGeofenceRegionEnter() throws {
        // Set up an expectation for region entry
        let entryExpectation = expectation(description: "Region entry should be detected")
        
        // Add a geofence
        let identifier = "test-geofence-1"
        let coordinate = CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788) // Miami
        let radius: CLLocationDistance = 100.0
        
        geofencingManager.addGeofence(identifier: identifier, coordinate: coordinate, radius: radius)
        
        // Monitor active geofences
        geofencingManager.$activeGeofences
            .dropFirst() // Skip initial value
            .sink { activeGeofences in
                if activeGeofences.contains(identifier) {
                    entryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate entering the region
        geofencingManager.simulateRegionEnter(identifier: identifier)
        
        // Wait for the expectation to be fulfilled
        wait(for: [entryExpectation], timeout: 1.0)
        
        // Verify the geofence is now active
        XCTAssertTrue(geofencingManager.activeGeofences.contains(identifier))
    }
    
    func testGeofenceRegionExit() throws {
        // Add a geofence and simulate entering it
        let identifier = "test-geofence-1"
        let coordinate = CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788) // Miami
        let radius: CLLocationDistance = 100.0
        
        geofencingManager.addGeofence(identifier: identifier, coordinate: coordinate, radius: radius)
        geofencingManager.simulateRegionEnter(identifier: identifier)
        
        // Verify the geofence is active
        XCTAssertTrue(geofencingManager.activeGeofences.contains(identifier))
        
        // Set up an expectation for region exit
        let exitExpectation = expectation(description: "Region exit should be detected")
        
        // Monitor active geofences
        geofencingManager.$activeGeofences
            .dropFirst() // Skip initial value
            .sink { activeGeofences in
                if !activeGeofences.contains(identifier) {
                    exitExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate exiting the region
        geofencingManager.simulateRegionExit(identifier: identifier)
        
        // Wait for the expectation to be fulfilled
        wait(for: [exitExpectation], timeout: 1.0)
        
        // Verify the geofence is no longer active
        XCTAssertFalse(geofencingManager.activeGeofences.contains(identifier))
    }
    
    func testGeofenceNotification() throws {
        // Add a geofence
        let identifier = "test-geofence-1"
        let coordinate = CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788) // Miami
        let radius: CLLocationDistance = 100.0
        
        geofencingManager.addGeofence(identifier: identifier, coordinate: coordinate, radius: radius)
        
        // Set up an expectation for notification
        let notificationExpectation = expectation(description: "Notification should be posted")
        
        // Monitor for region entry notifications
        NotificationCenter.default.addObserver(forName: .geofenceEntered, object: nil, queue: nil) { notification in
            if let id = notification.userInfo?["identifier"] as? String, id == identifier {
                notificationExpectation.fulfill()
            }
        }
        
        // Simulate entering the region
        geofencingManager.simulateRegionEnter(identifier: identifier)
        
        // Wait for the expectation to be fulfilled
        wait(for: [notificationExpectation], timeout: 1.0)
    }
    
    func testClearAllGeofences() throws {
        // Add multiple geofences
        let geofences = [
            (identifier: "test-geofence-1", coordinate: CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788), radius: 100.0),
            (identifier: "test-geofence-2", coordinate: CLLocationCoordinate2D(latitude: 40.712776, longitude: -74.005974), radius: 150.0),
            (identifier: "test-geofence-3", coordinate: CLLocationCoordinate2D(latitude: 34.052235, longitude: -118.243683), radius: 200.0)
        ]
        
        for geofence in geofences {
            geofencingManager.addGeofence(identifier: geofence.identifier, coordinate: geofence.coordinate, radius: geofence.radius)
        }
        
        // Verify all geofences were added
        XCTAssertEqual(geofencingManager.monitoredRegions.count, 3)
        
        // Clear all geofences
        geofencingManager.clearAllGeofences()
        
        // Verify all geofences were removed
        XCTAssertEqual(geofencingManager.monitoredRegions.count, 0)
    }
    
    func testIsUserInGeofence() throws {
        // Add a geofence
        let identifier = "test-geofence-1"
        let coordinate = CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788) // Miami
        let radius: CLLocationDistance = 100.0
        
        geofencingManager.addGeofence(identifier: identifier, coordinate: coordinate, radius: radius)
        
        // First, check when user is not in any geofence
        XCTAssertFalse(geofencingManager.isUserInGeofence(identifier: identifier))
        
        // Simulate entering the region
        geofencingManager.simulateRegionEnter(identifier: identifier)
        
        // Now check if user is in the geofence
        XCTAssertTrue(geofencingManager.isUserInGeofence(identifier: identifier))
    }
    
    func testGeofenceLocations() throws {
        // Add multiple geofences with different coordinates
        let geofences = [
            (identifier: "test-geofence-1", coordinate: CLLocationCoordinate2D(latitude: 25.761681, longitude: -80.191788), radius: 100.0),
            (identifier: "test-geofence-2", coordinate: CLLocationCoordinate2D(latitude: 40.712776, longitude: -74.005974), radius: 150.0)
        ]
        
        for geofence in geofences {
            geofencingManager.addGeofence(identifier: geofence.identifier, coordinate: geofence.coordinate, radius: geofence.radius)
        }
        
        // Get the coordinates for each geofence
        let coordinates = geofencingManager.getGeofenceCoordinates()
        
        // Verify coordinates were correctly stored
        XCTAssertEqual(coordinates.count, 2)
        XCTAssertEqual(coordinates["test-geofence-1"]?.latitude, 25.761681, accuracy: 0.0001)
        XCTAssertEqual(coordinates["test-geofence-1"]?.longitude, -80.191788, accuracy: 0.0001)
        XCTAssertEqual(coordinates["test-geofence-2"]?.latitude, 40.712776, accuracy: 0.0001)
        XCTAssertEqual(coordinates["test-geofence-2"]?.longitude, -74.005974, accuracy: 0.0001)
    }
}

// MARK: - Mock Classes for Testing

class MockableGeofencingManager: GeofencingManager {
    var monitoredRegions = Set<CLCircularRegion>()
    
    override func addGeofence(identifier: String, coordinate: CLLocationCoordinate2D, radius: CLLocationDistance) {
        super.addGeofence(identifier: identifier, coordinate: coordinate, radius: radius)
        
        // Create and store the region
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
        monitoredRegions.insert(region)
    }
    
    override func removeGeofence(identifier: String) {
        super.removeGeofence(identifier: identifier)
        
        // Remove the region from our local storage
        monitoredRegions.removeAll { $0.identifier == identifier }
    }
    
    override func clearAllGeofences() {
        super.clearAllGeofences()
        
        // Clear all regions from our local storage
        monitoredRegions.removeAll()
    }
    
    func simulateRegionEnter(identifier: String) {
        // Find the region
        guard let region = monitoredRegions.first(where: { $0.identifier == identifier }) else {
            return
        }
        
        // Create a notification with the identifier
        NotificationCenter.default.post(
            name: .geofenceEntered,
            object: self,
            userInfo: ["identifier": identifier]
        )
        
        // Update active geofences
        if !activeGeofences.contains(identifier) {
            activeGeofences.append(identifier)
        }
    }
    
    func simulateRegionExit(identifier: String) {
        // Find the region
        guard let region = monitoredRegions.first(where: { $0.identifier == identifier }) else {
            return
        }
        
        // Create a notification with the identifier
        NotificationCenter.default.post(
            name: .geofenceExited,
            object: self,
            userInfo: ["identifier": identifier]
        )
        
        // Update active geofences
        if let index = activeGeofences.firstIndex(of: identifier) {
            activeGeofences.remove(at: index)
        }
    }
    
    func getGeofenceCoordinates() -> [String: CLLocationCoordinate2D] {
        var coordinates = [String: CLLocationCoordinate2D]()
        
        for region in monitoredRegions {
            coordinates[region.identifier] = region.center
        }
        
        return coordinates
    }
} 