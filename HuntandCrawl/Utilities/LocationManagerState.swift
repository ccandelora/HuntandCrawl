import Foundation
import CoreLocation
import MapKit
import Observation

@Observable
final class LocationManagerState {
    // Basic location properties
    var userLocation: CLLocation?
    var userHeading: CLLocationDirection = 0
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLocationServicesEnabled: Bool = false  // Initialize as false, will be set properly later
    
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
} 