import Foundation
import CoreLocation
import Combine

class BeaconManager: NSObject, ObservableObject {
    // Beacon related UUIDs
    private let huntBeaconUUID = UUID(uuidString: "74278BDA-B644-4520-8F0C-720EAF059935")!
    private let barCrawlBeaconUUID = UUID(uuidString: "65078BDA-C644-4520-8F0C-720EAF059935")!
    
    // Published properties for UI updates
    @Published var isMonitoring = false
    @Published var detectedBeacons: [DetectedBeacon] = []
    @Published var isLocationServicesEnabled = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var nearestBeacon: DetectedBeacon?
    
    // Core Location objects
    private var locationManager: CLLocationManager!
    private var beaconRegions: [CLBeaconRegion] = []
    
    // Timer for cleaning up old beacons
    private var cleanupTimer: Timer?
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Set up beacon regions
        setupBeaconRegions()
        
        // Start cleanup timer
        startCleanupTimer()
    }
    
    // Set up beacon regions for monitoring
    private func setupBeaconRegions() {
        // Hunt beacon region
        let huntRegion = CLBeaconRegion(
            uuid: huntBeaconUUID,
            identifier: "com.huntandcrawl.huntbeacons"
        )
        huntRegion.notifyEntryStateOnDisplay = true
        beaconRegions.append(huntRegion)
        
        // Bar crawl beacon region
        let barCrawlRegion = CLBeaconRegion(
            uuid: barCrawlBeaconUUID, 
            identifier: "com.huntandcrawl.barcrawlbeacons"
        )
        barCrawlRegion.notifyEntryStateOnDisplay = true
        beaconRegions.append(barCrawlRegion)
    }
    
    // Start monitoring for beacons
    func startMonitoring() {
        guard CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self),
              CLLocationManager.isRangingAvailable() else {
            print("Beacon monitoring or ranging not available")
            return
        }
        
        // Start monitoring and ranging for each region
        for region in beaconRegions {
            locationManager.startMonitoring(for: region)
            locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
        
        isMonitoring = true
    }
    
    // Stop monitoring for beacons
    func stopMonitoring() {
        for region in beaconRegions {
            locationManager.stopMonitoring(for: region)
            locationManager.stopRangingBeacons(satisfying: region.beaconIdentityConstraint)
        }
        
        isMonitoring = false
    }
    
    // Start the cleanup timer to remove old beacons
    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.cleanupOldBeacons()
        }
    }
    
    // Remove beacons that haven't been detected recently
    private func cleanupOldBeacons() {
        let currentTime = Date()
        detectedBeacons.removeAll { beacon in
            let timeSinceLastSeen = currentTime.timeIntervalSince(beacon.lastSeen)
            return timeSinceLastSeen > 10.0 // Remove if not seen for 10 seconds
        }
        
        updateNearestBeacon()
    }
    
    // Update which beacon is nearest
    private func updateNearestBeacon() {
        nearestBeacon = detectedBeacons.min { $0.proximity.rawValue < $1.proximity.rawValue }
    }
    
    // Check if a specific task location is nearby
    func isTaskLocationNearby(taskId: UUID) -> Bool {
        return detectedBeacons.contains { beacon in
            beacon.type == .hunt && beacon.identifier == taskId.uuidString && beacon.proximity != .unknown && beacon.proximity != .far
        }
    }
    
    // Check if a specific bar stop is nearby
    func isBarStopNearby(barStopId: UUID) -> Bool {
        return detectedBeacons.contains { beacon in
            beacon.type == .barCrawl && beacon.identifier == barStopId.uuidString && beacon.proximity != .unknown && beacon.proximity != .far
        }
    }
    
    // Get all nearby hunt beacons
    func nearbyHuntBeacons() -> [DetectedBeacon] {
        return detectedBeacons.filter { $0.type == .hunt && $0.proximity != .unknown && $0.proximity != .far }
    }
    
    // Get all nearby bar crawl beacons
    func nearbyBarCrawlBeacons() -> [DetectedBeacon] {
        return detectedBeacons.filter { $0.type == .barCrawl && $0.proximity != .unknown && $0.proximity != .far }
    }
}

// MARK: - CLLocationManagerDelegate
extension BeaconManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        isLocationServicesEnabled = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        
        if isLocationServicesEnabled && isMonitoring {
            startMonitoring()
        } else if !isLocationServicesEnabled {
            stopMonitoring()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            manager.requestState(for: beaconRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            if state == .inside {
                // Start ranging beacons if we're inside the region
                manager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            } else {
                // Stop ranging beacons if we're outside the region
                manager.stopRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        // Update detected beacons
        let currentTime = Date()
        
        let beaconType: BeaconType = beaconConstraint.uuid == huntBeaconUUID ? .hunt : .barCrawl
        
        for beacon in beacons {
            let identifier = "\(beacon.major):\(beacon.minor)"
            
            // Check if we already have this beacon
            if let index = detectedBeacons.firstIndex(where: { 
                $0.uuid == beacon.uuid && 
                $0.major == beacon.major.intValue && 
                $0.minor == beacon.minor.intValue 
            }) {
                // Update existing beacon
                detectedBeacons[index].proximity = beacon.proximity
                detectedBeacons[index].rssi = beacon.rssi
                detectedBeacons[index].accuracy = beacon.accuracy
                detectedBeacons[index].lastSeen = currentTime
            } else {
                // Add new beacon
                let newBeacon = DetectedBeacon(
                    uuid: beacon.uuid,
                    major: beacon.major.intValue,
                    minor: beacon.minor.intValue,
                    identifier: identifier,
                    proximity: beacon.proximity,
                    rssi: beacon.rssi,
                    accuracy: beacon.accuracy,
                    type: beaconType
                )
                detectedBeacons.append(newBeacon)
            }
        }
        
        updateNearestBeacon()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with error: \(error.localizedDescription)")
    }
}

// MARK: - DetectedBeacon
struct DetectedBeacon: Identifiable, Equatable {
    let id = UUID()
    let uuid: UUID
    let major: Int
    let minor: Int
    let identifier: String
    var proximity: CLProximity
    var rssi: Int
    var accuracy: CLLocationAccuracy
    var lastSeen: Date = Date()
    let type: BeaconType
    
    static func == (lhs: DetectedBeacon, rhs: DetectedBeacon) -> Bool {
        return lhs.uuid == rhs.uuid && lhs.major == rhs.major && lhs.minor == rhs.minor
    }
}

// MARK: - BeaconType
enum BeaconType {
    case hunt
    case barCrawl
} 