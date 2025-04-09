import Foundation
import CoreLocation
import Combine
import Observation
import MapKit

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    // Basic location properties
    var userLocation: CLLocation?
    var userHeading: CLLocationDirection = 0
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLocationServicesEnabled: Bool = CLLocationManager.locationServicesEnabled()
    
    // Navigation-specific properties
    var location: CLLocation?
    var heading: CLHeading?
    var distance: CLLocationDistance?
    var expectedTravelTime: TimeInterval?
    var currentDestinationCoordinate: CLLocationCoordinate2D?
    var route: MKRoute?
    var navigationDirections: [String] = []
    var currentNavigationStep: Int = 0
    var isNavigating: Bool = false
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10 // meters
        
        // Initial status check
        self.authorizationStatus = locationManager.authorizationStatus
        self.isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    // Check current authorization and update status
    func checkLocationAuthorization() {
        self.isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
        self.authorizationStatus = locationManager.authorizationStatus
        
        if !isLocationServicesEnabled {
            // Location services are disabled
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            requestLocationPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            // We're good to go
            startLocationUpdates()
        case .restricted, .denied:
            // We can't access location
            break
        @unknown default:
            break
        }
    }
    
    // Request permission to access location
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Start updating location
    func startLocationUpdates() {
        if isAuthorized {
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    
    // Stop updating location
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // Check if user is near a specific coordinate
    func isUserNearCoordinate(latitude: Double?, longitude: Double?, radius: Double = 100) -> Bool {
        guard let userLocation = userLocation,
              let latitude = latitude,
              let longitude = longitude else { 
            return false 
        }
        
        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distance = userLocation.distance(from: targetLocation)
        
        return distance <= radius
    }
    
    // Calculate distance to a coordinate
    func distanceToCoordinate(latitude: Double?, longitude: Double?) -> Double {
        guard let userLocation = userLocation,
              let latitude = latitude,
              let longitude = longitude else { 
            return Double.infinity 
        }
        
        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: targetLocation)
    }
    
    // Navigation methods required by NavigationView
    func startNavigation(to destination: CLLocation) {
        guard let userLocation = userLocation else { return }
        
        // Set navigation properties
        isNavigating = true
        currentDestinationCoordinate = destination.coordinate
        
        // Calculate route (mock implementation)
        // In a real app, you would use MKDirections to get the route
        calculateRoute(from: userLocation.coordinate, to: destination.coordinate)
        
        // Update distance
        distance = userLocation.distance(from: destination)
    }
    
    func stopNavigation() {
        isNavigating = false
        route = nil
        navigationDirections = []
        currentNavigationStep = 0
        distance = nil
        expectedTravelTime = nil
        currentDestinationCoordinate = nil
    }
    
    func distance(to location: CLLocation) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        return userLocation.distance(from: location)
    }
    
    // Helper method to calculate route (mock version)
    private func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        // In a real app, this would use MKDirections
        // For now, we'll just simulate some mock data
        
        // Mock directions
        navigationDirections = [
            "Head north on Current Street",
            "Turn right onto Main Avenue",
            "Continue straight for 500 meters",
            "Turn left at the traffic light",
            "Your destination is on the right"
        ]
        
        currentNavigationStep = 0
        expectedTravelTime = 600 // 10 minutes
        
        // Mock a route - this would be replaced with actual MKRoute in real implementation
        // In a full implementation, you would use MKDirections to get the actual route
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
            self.location = location
            
            // Update navigation information if we're navigating
            if isNavigating, let destCoord = currentDestinationCoordinate {
                distance = location.distance(from: CLLocation(
                    latitude: destCoord.latitude,
                    longitude: destCoord.longitude
                ))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        userHeading = newHeading.magneticHeading
        heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        // Update based on new authorization
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startLocationUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
    }
} 