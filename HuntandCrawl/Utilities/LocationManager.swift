import Foundation
import CoreLocation
import Combine
import Observation
import MapKit
import SwiftUI

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    // Create the state without @ObservationTracked to avoid redeclaration issues
    var state = LocationManagerState()
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10 // meters
        
        // Perform initial checks on a background queue to avoid UI blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let authStatus = self.locationManager.authorizationStatus
            let isEnabled = CLLocationManager.locationServicesEnabled()
            
            // Update our properties on the main thread
            DispatchQueue.main.async {
                self.state.authorizationStatus = authStatus
                self.state.isLocationServicesEnabled = isEnabled
            }
        }
    }
    
    // Check current authorization and update status
    func checkLocationAuthorization() {
        // Perform status check on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let isEnabled = CLLocationManager.locationServicesEnabled()
            let authStatus = self.locationManager.authorizationStatus
            
            DispatchQueue.main.async {
                self.state.isLocationServicesEnabled = isEnabled
                self.state.authorizationStatus = authStatus
                
                if !isEnabled {
                    // Location services are disabled
                    return
                }
                
                switch authStatus {
                case .notDetermined:
                    self.requestLocationPermission()
                case .authorizedWhenInUse, .authorizedAlways:
                    // We're good to go
                    self.startLocationUpdates()
                case .restricted, .denied:
                    // We can't access location
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    // Request permission to access location
    func requestLocationPermission() {
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // Start updating location
    func startLocationUpdates() {
        if state.isAuthorized {
            DispatchQueue.main.async { [weak self] in
                self?.locationManager.startUpdatingLocation()
                self?.locationManager.startUpdatingHeading()
            }
        }
    }
    
    // Stop updating location
    func stopLocationUpdates() {
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.stopUpdatingLocation()
            self?.locationManager.stopUpdatingHeading()
        }
    }
    
    // Check if user is near a specific coordinate
    func isUserNearCoordinate(latitude: Double?, longitude: Double?, radius: Double = 100) -> Bool {
        guard let userLocation = state.userLocation,
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
        guard let userLocation = state.userLocation,
              let latitude = latitude,
              let longitude = longitude else { 
            return Double.infinity 
        }
        
        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: targetLocation)
    }
    
    // Navigation methods required by NavigationView
    func startNavigation(to destination: CLLocation) {
        guard let userLocation = state.userLocation else { return }
        
        // Set navigation properties
        state.isNavigating = true
        state.currentDestinationCoordinate = destination.coordinate
        
        // Calculate route (mock implementation)
        // In a real app, you would use MKDirections to get the route
        calculateRoute(from: userLocation.coordinate, to: destination.coordinate)
        
        // Update distance
        state.distance = userLocation.distance(from: destination)
    }
    
    func stopNavigation() {
        state.isNavigating = false
        state.route = nil
        state.navigationDirections = []
        state.currentNavigationStep = 0
        state.distance = nil
        state.expectedTravelTime = nil
        state.currentDestinationCoordinate = nil
    }
    
    func distance(to location: CLLocation) -> CLLocationDistance? {
        guard let userLocation = state.userLocation else { return nil }
        return userLocation.distance(from: location)
    }
    
    // Helper method to calculate route (mock version)
    private func calculateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        // In a real app, this would use MKDirections
        // For now, we'll just simulate some mock data
        
        // Mock directions
        state.navigationDirections = [
            "Head north on Current Street",
            "Turn right onto Main Avenue",
            "Continue straight for 500 meters",
            "Turn left at the traffic light",
            "Your destination is on the right"
        ]
        
        state.currentNavigationStep = 0
        state.expectedTravelTime = 600 // 10 minutes
        
        // Mock a route - this would be replaced with actual MKRoute in real implementation
        // In a full implementation, you would use MKDirections to get the actual route
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            state.userLocation = location
            state.location = location
            
            // Update navigation information if we're navigating
            if state.isNavigating, let destCoord = state.currentDestinationCoordinate {
                state.distance = location.distance(from: CLLocation(
                    latitude: destCoord.latitude,
                    longitude: destCoord.longitude
                ))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        state.userHeading = newHeading.magneticHeading
        state.heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Update status, but don't immediately query the manager again
        state.authorizationStatus = status
        
        // Use a small delay to prevent rapid UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Update based on new authorization
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startLocationUpdates()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
    }
} 