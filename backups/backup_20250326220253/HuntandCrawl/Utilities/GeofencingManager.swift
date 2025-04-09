import Foundation
import CoreLocation
import SwiftData
import Combine

class GeofencingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Published Properties
    
    /// All active geofences
    @Published var activeGeofences: [String] = []
    
    /// Geofences the user is currently inside
    @Published var geofencesInside: [String] = []
    
    /// Whether the user is inside the ship boundaries
    @Published var isWithinShipBoundaries = false
    
    /// Unvisited tasks that are nearby
    @Published var nearbyTasks: [GeofenceData] = []
    
    /// Unvisited bar stops that are nearby
    @Published var nearbyBarStops: [GeofenceData] = []
    
    // MARK: - Private Properties
    private var locationManager: LocationManager
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // Geofence configuration
    private let taskRadius: CLLocationDistance = 50 // meters
    private let barStopRadius: CLLocationDistance = 30 // meters
    private let proximityRadius: CLLocationDistance = 300 // meters - for nearby alerts
    
    // MARK: - Initialization
    init(locationManager: LocationManager, modelContext: ModelContext) {
        self.locationManager = locationManager
        self.modelContext = modelContext
        
        super.init()
        
        // Listen for region events
        setupNotificationObservers()
        
        // Check for nearby locations when user's location changes
        locationManager.$location
            .sink { [weak self] location in
                if let location = location {
                    self?.checkProximityToPoints(from: location)
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Setup geofences for all tasks in a hunt
    func setupGeofencesForHunt(_ hunt: Hunt) {
        // First remove any existing hunt geofences
        removeGeofencesForHunt(hunt.id)
        
        // Get all completed tasks to avoid setting up geofences for them
        let completedTaskDescriptor = FetchDescriptor<TaskCompletion>()
        let completedTasks: [TaskCompletion]
        
        do {
            completedTasks = try modelContext.fetch(completedTaskDescriptor)
        } catch {
            completedTasks = []
            print("Error fetching completed tasks: \(error)")
        }
        
        let completedTaskIds = Set(completedTasks.map { $0.taskId })
        
        // Add geofences for incomplete tasks
        hunt.tasks?.forEach { task in
            // Skip if task is already completed
            if completedTaskIds.contains(task.id) {
                return
            }
            
            // Create geofence for this task
            addTaskGeofence(task, huntId: hunt.id)
        }
    }
    
    /// Setup geofences for all stops in a bar crawl
    func setupGeofencesForBarCrawl(_ barCrawl: BarCrawl) {
        // First remove any existing bar crawl geofences
        removeGeofencesForBarCrawl(barCrawl.id)
        
        // Get all visited bar stops to avoid setting up geofences for them
        let visitedStopsDescriptor = FetchDescriptor<BarStopVisit>()
        let visitedStops: [BarStopVisit]
        
        do {
            visitedStops = try modelContext.fetch(visitedStopsDescriptor)
        } catch {
            visitedStops = []
            print("Error fetching visited bar stops: \(error)")
        }
        
        let visitedStopIds = Set(visitedStops.map { $0.barStopId })
        
        // Add geofences for unvisited stops
        barCrawl.barStops?.forEach { barStop in
            // Skip if bar stop is already visited
            if visitedStopIds.contains(barStop.id) {
                return
            }
            
            // Create geofence for this bar stop
            addBarStopGeofence(barStop, barCrawlId: barCrawl.id)
        }
    }
    
    /// Remove all geofences for a specific hunt
    func removeGeofencesForHunt(_ huntId: UUID) {
        // Find all geofences for this hunt
        let huntGeofences = activeGeofences.filter { $0.contains("task_\(huntId.uuidString)") }
        
        // Remove each one
        huntGeofences.forEach { identifier in
            locationManager.stopMonitoringLocation(identifier: identifier)
            activeGeofences.removeAll { $0 == identifier }
        }
    }
    
    /// Remove all geofences for a specific bar crawl
    func removeGeofencesForBarCrawl(_ barCrawlId: UUID) {
        // Find all geofences for this bar crawl
        let barCrawlGeofences = activeGeofences.filter { $0.contains("barStop_\(barCrawlId.uuidString)") }
        
        // Remove each one
        barCrawlGeofences.forEach { identifier in
            locationManager.stopMonitoringLocation(identifier: identifier)
            activeGeofences.removeAll { $0 == identifier }
        }
    }
    
    /// Remove all active geofences
    func removeAllGeofences() {
        activeGeofences.forEach { identifier in
            locationManager.stopMonitoringLocation(identifier: identifier)
        }
        activeGeofences.removeAll()
    }
    
    /// Check if the user is near a specific task location
    func isNearTask(_ task: Task) -> Bool {
        guard let location = locationManager.location else { return false }
        
        let taskLocation = CLLocation(latitude: task.latitude, longitude: task.longitude)
        let distance = location.distance(from: taskLocation)
        
        return distance <= proximityRadius
    }
    
    /// Check if the user is near a specific bar stop location
    func isNearBarStop(_ barStop: BarStop) -> Bool {
        guard let location = locationManager.location else { return false }
        
        let barStopLocation = CLLocation(latitude: barStop.latitude, longitude: barStop.longitude)
        let distance = location.distance(from: barStopLocation)
        
        return distance <= proximityRadius
    }
    
    /// Get "warmer/colder" hints for a specific task
    func getProximityHintForTask(_ task: Task) -> String {
        guard let location = locationManager.location else { return "Move around to get hints" }
        
        let taskLocation = CLLocation(latitude: task.latitude, longitude: task.longitude)
        return locationManager.getProximityHint(to: taskLocation)
    }
    
    // MARK: - Private Methods
    
    /// Add a task geofence
    private func addTaskGeofence(_ task: Task, huntId: UUID) {
        let identifier = "task_\(task.id.uuidString)"
        
        // Create geofence data
        let geofenceData = GeofenceData(
            id: task.id,
            huntId: huntId,
            type: .task,
            name: task.title,
            description: task.description,
            latitude: task.latitude,
            longitude: task.longitude
        )
        
        // Add to active geofences
        activeGeofences.append(identifier)
        
        // Start monitoring this location
        locationManager.startMonitoringLocation(
            identifier: identifier,
            latitude: task.latitude,
            longitude: task.longitude,
            radius: taskRadius,
            notifyOnEntry: true,
            notifyOnExit: false
        )
    }
    
    /// Add a bar stop geofence
    private func addBarStopGeofence(_ barStop: BarStop, barCrawlId: UUID) {
        let identifier = "barStop_\(barStop.id.uuidString)"
        
        // Create geofence data
        let geofenceData = GeofenceData(
            id: barStop.id,
            barCrawlId: barCrawlId,
            type: .barStop,
            name: barStop.name,
            description: barStop.description,
            latitude: barStop.latitude,
            longitude: barStop.longitude
        )
        
        // Add to active geofences
        activeGeofences.append(identifier)
        
        // Start monitoring this location
        locationManager.startMonitoringLocation(
            identifier: identifier,
            latitude: barStop.latitude,
            longitude: barStop.longitude,
            radius: barStopRadius,
            notifyOnEntry: true,
            notifyOnExit: false
        )
    }
    
    /// Set up notification observers for region events
    private func setupNotificationObservers() {
        // Handle entering regions
        NotificationCenter.default.publisher(for: .didEnterRegion)
            .sink { [weak self] notification in
                if let regionIdentifier = notification.userInfo?["regionIdentifier"] as? String {
                    self?.handleRegionEntry(identifier: regionIdentifier)
                }
            }
            .store(in: &cancellables)
        
        // Handle exiting regions
        NotificationCenter.default.publisher(for: .didExitRegion)
            .sink { [weak self] notification in
                if let regionIdentifier = notification.userInfo?["regionIdentifier"] as? String {
                    self?.handleRegionExit(identifier: regionIdentifier)
                }
            }
            .store(in: &cancellables)
        
        // Handle ship boundary updates
        NotificationCenter.default.publisher(for: .enteredShipBoundaries)
            .sink { [weak self] _ in
                self?.isWithinShipBoundaries = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .exitedShipBoundaries)
            .sink { [weak self] _ in
                self?.isWithinShipBoundaries = false
            }
            .store(in: &cancellables)
    }
    
    /// Handle when the user enters a geofenced region
    private func handleRegionEntry(identifier: String) {
        // Add to list of regions user is inside
        if !geofencesInside.contains(identifier) {
            geofencesInside.append(identifier)
        }
        
        // If this is a task or bar stop geofence, trigger the appropriate action
        if let geofenceData = activeGeofences.first(where: { $0 == identifier }) {
            switch geofenceData {
            case "task_\(geofenceData)":
                handleTaskCompletion(geofenceData)
                
            case "barStop_\(geofenceData)":
                handleBarStopVisit(geofenceData)
                
            default:
                // Handle custom geofence entry
                break
            }
            
            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .didEnterGeofencedLocation,
                object: nil,
                userInfo: ["geofenceData": geofenceData]
            )
        }
    }
    
    /// Handle when the user exits a geofenced region
    private func handleRegionExit(identifier: String) {
        // Remove from list of regions user is inside
        geofencesInside.removeAll { $0 == identifier }
        
        // If this is a custom geofence, trigger the appropriate action
        if let geofenceData = activeGeofences.first(where: { $0 == identifier }) {
            // Handle custom geofence exit if needed
        }
    }
    
    /// Handle task completion when user enters a task geofence
    private func handleTaskCompletion(_ geofenceData: String) {
        // Extract IDs from geofence data before using in predicate
        guard let components = extractIdsFromGeofenceData(geofenceData),
              let taskId = components.firstId,
              let huntId = components.lastId else { 
            return 
        }
        
        // Check if task is already completed
        let taskCompletionDescriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate<TaskCompletion> { 
                $0.taskId == taskId && $0.huntId == huntId
            }
        )
        
        do {
            let existingCompletions = try modelContext.fetch(taskCompletionDescriptor)
            if !existingCompletions.isEmpty {
                // Task already completed
                return
            }
            
            // Create new task completion record
            let taskCompletion = TaskCompletion(
                taskId: taskId,
                huntId: huntId,
                completedAt: Date(),
                points: 10, // Default points, could be fetched from task
                verificationMethod: "location"
            )
            
            modelContext.insert(taskCompletion)
            
            // Remove the geofence since task is now completed
            locationManager.stopMonitoringLocation(identifier: geofenceData)
            activeGeofences.removeAll { $0 == geofenceData }
            
            // Notify the user
            NotificationCenter.default.post(
                name: .didCompleteTask,
                object: nil,
                userInfo: [
                    "taskId": taskId,
                    "huntId": huntId,
                    "taskCompletion": taskCompletion
                ]
            )
            
        } catch {
            print("Error handling task completion: \(error)")
        }
    }
    
    /// Handle bar stop visit when user enters a bar stop geofence
    private func handleBarStopVisit(_ geofenceData: String) {
        // Extract IDs from geofence data before using in predicate
        guard let components = extractIdsFromGeofenceData(geofenceData),
              let barStopId = components.firstId,
              let barCrawlId = components.lastId else { 
            return 
        }
        
        // Check if bar stop is already visited
        let barStopVisitDescriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate<BarStopVisit> { 
                $0.barStopId == barStopId && $0.barCrawlId == barCrawlId
            }
        )
        
        do {
            let existingVisits = try modelContext.fetch(barStopVisitDescriptor)
            if !existingVisits.isEmpty {
                // Bar stop already visited
                return
            }
            
            // Create new bar stop visit record
            let barStopVisit = BarStopVisit(
                barStopId: barStopId,
                barCrawlId: barCrawlId,
                visitedAt: Date(),
                checkInMethod: "location"
            )
            
            modelContext.insert(barStopVisit)
            
            // Remove the geofence since bar stop is now visited
            locationManager.stopMonitoringLocation(identifier: geofenceData)
            activeGeofences.removeAll { $0 == geofenceData }
            
            // Notify the user
            NotificationCenter.default.post(
                name: .didVisitBarStop,
                object: nil,
                userInfo: [
                    "barStopId": barStopId,
                    "barCrawlId": barCrawlId,
                    "barStopVisit": barStopVisit
                ]
            )
            
        } catch {
            print("Error handling bar stop visit: \(error)")
        }
    }
    
    // Helper function to extract IDs from geofence data string
    private func extractIdsFromGeofenceData(_ data: String) -> (firstId: UUID?, lastId: UUID?)? {
        let components = data.split(separator: "_")
        guard components.count >= 2 else { return nil }
        
        let firstIdString = String(components.first ?? "")
        let lastIdString = String(components.last ?? "")
        
        let firstId = UUID(uuidString: firstIdString)
        let lastId = UUID(uuidString: lastIdString)
        
        return (firstId, lastId)
    }
    
    /// Check for proximity to points of interest
    private func checkProximityToPoints(from location: CLLocation) {
        // Clear previous nearby points
        nearbyTasks.removeAll()
        nearbyBarStops.removeAll()
        
        // Check all active geofences
        for identifier in activeGeofences {
            // Extract location data outside of predicates
            let coords = extractCoordinatesFromIdentifier(identifier)
            guard let latitude = coords.latitude, let longitude = coords.longitude else {
                continue
            }
            
            let pointLocation = CLLocation(
                latitude: latitude,
                longitude: longitude
            )
            
            let distance = location.distance(from: pointLocation)
            
            if distance <= proximityRadius {
                // Extract IDs for use in predicates
                let ids = extractIdsFromGeofenceData(identifier)
                
                // Point is nearby
                switch identifier {
                case "task_\(identifier)":
                    guard let taskId = ids?.firstId, !nearbyTasks.contains(where: { $0.id == taskId }) else {
                        continue
                    }
                    
                    nearbyTasks.append(GeofenceData(
                        id: taskId,
                        huntId: ids?.lastId,
                        barCrawlId: nil,
                        type: .task,
                        name: extractNameFromIdentifier(identifier) ?? "",
                        description: "",
                        latitude: latitude,
                        longitude: longitude
                    ))
                    
                case "barStop_\(identifier)":
                    guard let barStopId = ids?.firstId, !nearbyBarStops.contains(where: { $0.id == barStopId }) else {
                        continue
                    }
                    
                    nearbyBarStops.append(GeofenceData(
                        id: barStopId,
                        huntId: nil,
                        barCrawlId: ids?.lastId,
                        type: .barStop,
                        name: extractNameFromIdentifier(identifier) ?? "",
                        description: "",
                        latitude: latitude,
                        longitude: longitude
                    ))
                    
                default:
                    break
                }
            }
        }
        
        // Sort by distance
        nearbyTasks.sort { locationDistance(to: $0) < locationDistance(to: $1) }
        nearbyBarStops.sort { locationDistance(to: $0) < locationDistance(to: $1) }
        
        // Post notifications if there are nearby points
        if !nearbyTasks.isEmpty {
            NotificationCenter.default.post(
                name: .tasksNearby,
                object: nil,
                userInfo: ["nearbyTasks": nearbyTasks]
            )
        }
        
        if !nearbyBarStops.isEmpty {
            NotificationCenter.default.post(
                name: .barStopsNearby,
                object: nil,
                userInfo: ["nearbyBarStops": nearbyBarStops]
            )
        }
    }
    
    // Helper function to extract coordinates from identifier string
    private func extractCoordinatesFromIdentifier(_ identifier: String) -> (latitude: Double?, longitude: Double?) {
        let components = identifier.split(separator: "_")
        guard components.count >= 2 else { return (nil, nil) }
        
        let latString = String(components.last ?? "")
        let lonString = String(components.first ?? "")
        
        let latitude = Double(latString)
        let longitude = Double(lonString)
        
        return (latitude, longitude)
    }
    
    // Helper function to extract name from identifier string
    private func extractNameFromIdentifier(_ identifier: String) -> String? {
        let components = identifier.split(separator: "_")
        guard !components.isEmpty else { return nil }
        
        return String(components.first ?? "")
    }
    
    /// Calculate distance from current location to a geofence point
    private func locationDistance(to geofenceData: GeofenceData) -> CLLocationDistance {
        guard let location = locationManager.location else { return .infinity }
        
        let pointLocation = CLLocation(
            latitude: geofenceData.latitude, 
            longitude: geofenceData.longitude
        )
        
        return location.distance(from: pointLocation)
    }
}

// MARK: - Supporting Types

/// Types of geofences
enum GeofenceType {
    case task
    case barStop
    case custom
}

/// Data model for geofence
struct GeofenceData: Identifiable {
    let id: UUID
    let huntId: UUID?
    let barCrawlId: UUID?
    let type: GeofenceType
    let name: String
    let description: String
    let latitude: Double
    let longitude: Double
    
    init(
        id: UUID,
        huntId: UUID? = nil,
        barCrawlId: UUID? = nil,
        type: GeofenceType,
        name: String,
        description: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.huntId = huntId
        self.barCrawlId = barCrawlId
        self.type = type
        self.name = name
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let didEnterRegion = Notification.Name("didEnterRegion")
    static let didExitRegion = Notification.Name("didExitRegion")
    static let didEnterGeofencedLocation = Notification.Name("didEnterGeofencedLocation")
    static let didCompleteTask = Notification.Name("didCompleteTask")
    static let didVisitBarStop = Notification.Name("didVisitBarStop")
    static let tasksNearby = Notification.Name("tasksNearby")
    static let barStopsNearby = Notification.Name("barStopsNearby")
    static let geofenceEntered = Notification.Name("geofenceEntered")
    static let geofenceExited = Notification.Name("geofenceExited")
    static let enteredShipBoundaries = Notification.Name("enteredShipBoundaries")
    static let exitedShipBoundaries = Notification.Name("exitedShipBoundaries")
}

// MARK: - CLLocationManagerDelegate

extension GeofencingManager {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        
        // Post notification about region entry
        NotificationCenter.default.post(
            name: .geofenceEntered,
            object: self,
            userInfo: ["identifier": region.identifier]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        
        // Post notification about region exit
        NotificationCenter.default.post(
            name: .geofenceExited,
            object: self,
            userInfo: ["identifier": region.identifier]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed to monitor region: \(error.localizedDescription)")
    }
} 