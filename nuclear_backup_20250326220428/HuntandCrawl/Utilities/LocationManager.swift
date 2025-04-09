import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var heading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10 // meters
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.showsBackgroundLocationIndicator = true
        self.locationManager.allowsBackgroundLocationUpdates = true
        
        // Initial status check
        self.authorizationStatus = locationManager.authorizationStatus
        self.isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startMonitoringLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // Check if user is near a specific location
    func isNearLocation(latitude: Double, longitude: Double, threshold: Double = 100) -> Bool {
        guard let userLocation = userLocation else { return false }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let distance = userLocation.distance(from: location)
        
        return distance <= threshold
    }
    
    // Calculate distance between user and a location
    func distanceToLocation(latitude: Double, longitude: Double) -> Double? {
        guard let userLocation = userLocation else { return nil }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: location)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        // Request location updates if authorized
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
    }
} 