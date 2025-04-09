import Foundation
import CoreLocation
import Combine

// Mock for CLLocationManager to use in unit tests
class MockCLLocationManager: CLLocationManager {
    // Mock properties
    var mockLocationServicesEnabled = true
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var mockLocation: CLLocation?
    var mockHeading: CLHeading?
    var mockMonitoredRegions: Set<CLRegion> = []
    
    // Delegate will be called when these closures are executed
    var locationUpdateHandler: (() -> Void)?
    var headingUpdateHandler: (() -> Void)?
    var regionEventHandler: ((CLRegion, Bool) -> Void)?
    var authorizationChangeHandler: (() -> Void)?
    
    // Mock the class method for checking if location services are enabled
    static var locationServicesEnabledOverride: Bool?
    override class var locationServicesEnabled: Bool {
        return locationServicesEnabledOverride ?? true
    }
    
    // Override authorizationStatus class method
    static var authorizationStatusOverride: CLAuthorizationStatus?
    override class func authorizationStatus() -> CLAuthorizationStatus {
        return authorizationStatusOverride ?? .notDetermined
    }
    
    // Override properties
    override var location: CLLocation? {
        return mockLocation
    }
    
    override var heading: CLHeading? {
        return mockHeading
    }
    
    override var monitoredRegions: Set<CLRegion> {
        return mockMonitoredRegions
    }
    
    // Mock methods
    override func requestWhenInUseAuthorization() {
        // Simulate authorization change after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            MockCLLocationManager.authorizationStatusOverride = .authorizedWhenInUse
            self.authorizationChangeHandler?()
        }
    }
    
    override func requestAlwaysAuthorization() {
        // Simulate authorization change after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            MockCLLocationManager.authorizationStatusOverride = .authorizedAlways
            self.authorizationChangeHandler?()
        }
    }
    
    override func startUpdatingLocation() {
        // Do nothing but could trigger location updates if needed
        locationUpdateHandler?()
    }
    
    override func stopUpdatingLocation() {
        // Do nothing
    }
    
    override func startUpdatingHeading() {
        headingUpdateHandler?()
    }
    
    override func stopUpdatingHeading() {
        // Do nothing
    }
    
    override func startMonitoringSignificantLocationChanges() {
        // Do nothing
    }
    
    override func stopMonitoringSignificantLocationChanges() {
        // Do nothing
    }
    
    override func startMonitoring(for region: CLRegion) {
        mockMonitoredRegions.insert(region)
    }
    
    override func stopMonitoring(for region: CLRegion) {
        mockMonitoredRegions.remove(region)
    }
    
    // Methods to simulate delegate callbacks
    func simulateLocationUpdate(location: CLLocation) {
        mockLocation = location
        delegate?.locationManager?(self, didUpdateLocations: [location])
    }
    
    func simulateHeadingUpdate(heading: CLHeading) {
        mockHeading = heading
        delegate?.locationManager?(self, didUpdateHeading: heading)
    }
    
    func simulateRegionEnter(region: CLRegion) {
        delegate?.locationManager?(self, didEnterRegion: region)
        regionEventHandler?(region, true)
    }
    
    func simulateRegionExit(region: CLRegion) {
        delegate?.locationManager?(self, didExitRegion: region)
        regionEventHandler?(region, false)
    }
    
    func simulateAuthorizationChange(status: CLAuthorizationStatus) {
        MockCLLocationManager.authorizationStatusOverride = status
        delegate?.locationManager?(self, didChangeAuthorization: status)
    }
    
    func simulateLocationError(error: Error) {
        delegate?.locationManager?(self, didFailWithError: error)
    }
    
    // Reset all mocked states
    func reset() {
        mockLocation = nil
        mockHeading = nil
        mockMonitoredRegions = []
        mockAuthorizationStatus = .notDetermined
        MockCLLocationManager.authorizationStatusOverride = nil
        MockCLLocationManager.locationServicesEnabledOverride = nil
    }
} 