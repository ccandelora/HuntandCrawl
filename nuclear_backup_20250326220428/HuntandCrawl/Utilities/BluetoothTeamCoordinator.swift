import Foundation
import CoreLocation
import Combine
import SwiftData

class BluetoothTeamCoordinator: NSObject, ObservableObject {
    // Published properties for UI updates
    @Published var teamMembers: [TeamMember] = []
    @Published var teamChat: [ChatMessage] = []
    @Published var isCoordinatingTeam: Bool = false
    @Published var currentTeam: Team?
    
    // Dependencies
    private var bluetoothManager: BluetoothManager
    private var messageManager: BluetoothMessageManager
    private var locationManager: CLLocationManager
    private var modelContext: ModelContext
    private var currentUser: User?
    
    // Timers and state
    private var locationUpdateTimer: Timer?
    private var memberCleanupTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Initialization
    init(modelContext: ModelContext? = nil, 
         bluetoothManager: BluetoothManager, 
         messageManager: BluetoothMessageManager,
         currentUser: User?) {
        self.modelContext = modelContext ?? ModelContext(ModelContainer.shared)
        self.bluetoothManager = bluetoothManager
        self.messageManager = messageManager
        self.currentUser = currentUser
        self.locationManager = CLLocationManager()
        
        super.init()
        
        // Set up location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 20 // Update when user moves 20 meters
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Set up notification observers
        setupNotificationObservers()
    }
    
    // Set up notification observers
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .didReceiveMessage)
            .sink { [weak self] notification in
                if let messageData = notification.userInfo?["data"] as? Data,
                   let message = BluetoothPeerMessage.fromData(messageData) {
                    self?.handleIncomingMessage(message)
                }
            }
            .store(in: &cancellables)
    }
    
    // Start team coordination for a specific team
    func startTeamCoordination(for team: Team) {
        currentTeam = team
        isCoordinatingTeam = true
        
        // Start location updates
        requestLocationPermission()
        
        // Set up timers
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendLocationUpdate()
        }
        
        memberCleanupTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            self?.cleanUpStaleMembers()
        }
        
        // Broadcast initial location
        sendLocationUpdate()
    }
    
    // Stop team coordination
    func stopTeamCoordination() {
        isCoordinatingTeam = false
        currentTeam = nil
        
        // Stop location updates
        locationManager.stopUpdatingLocation()
        
        // Invalidate timers
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        
        memberCleanupTimer?.invalidate()
        memberCleanupTimer = nil
        
        // Clear local state
        teamMembers.removeAll()
        teamChat.removeAll()
    }
    
    // Send a team chat message
    func sendTeamChatMessage(_ message: String) {
        guard let currentUser = currentUser, let team = currentTeam else { return }
        
        // Create chat message
        let chatMessage = ChatMessage(
            id: UUID(),
            teamId: team.id,
            senderId: currentUser.id,
            senderName: currentUser.displayName,
            message: message,
            timestamp: Date()
        )
        
        // Add to local chat
        teamChat.append(chatMessage)
        
        // Create message data
        let messageData: [String: Any] = [
            "teamId": team.id.uuidString,
            "senderId": currentUser.id.uuidString,
            "senderName": currentUser.displayName,
            "message": message,
            "timestamp": Date().ISO8601Format()
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: messageData)
        
        // Create Bluetooth message
        let bluetoothMessage = BluetoothPeerMessage(
            senderId: currentUser.id,
            senderName: currentUser.displayName,
            messageType: .teamChat,
            content: message,
            data: jsonData
        )
        
        // Broadcast to team
        broadcastToTeam(bluetoothMessage)
    }
    
    // Send location update to team
    private func sendLocationUpdate() {
        guard let currentUser = currentUser, 
              let team = currentTeam,
              let location = locationManager.location else { return }
        
        // Update local team member
        updateLocalTeamMember(location: location)
        
        // Broadcast location to team
        messageManager.broadcastTeamLocation(
            team.id,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
    
    // Update the local team member's location
    private func updateLocalTeamMember(location: CLLocation) {
        guard let currentUser = currentUser else { return }
        
        // Check if current user is already in the team members list
        if let index = teamMembers.firstIndex(where: { $0.userId == currentUser.id }) {
            teamMembers[index].latitude = location.coordinate.latitude
            teamMembers[index].longitude = location.coordinate.longitude
            teamMembers[index].lastUpdated = Date()
        } else {
            // Add current user to team members
            let member = TeamMember(
                userId: currentUser.id,
                displayName: currentUser.displayName,
                isCurrentUser: true,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                lastUpdated: Date()
            )
            teamMembers.append(member)
        }
    }
    
    // Clean up team members that haven't sent updates in a while
    private func cleanUpStaleMembers() {
        let now = Date()
        let staleThreshold: TimeInterval = 5 * 60 // 5 minutes
        
        teamMembers.removeAll { member in
            !member.isCurrentUser && now.timeIntervalSince(member.lastUpdated) > staleThreshold
        }
    }
    
    // Broadcast a message to the team
    private func broadcastToTeam(_ message: BluetoothPeerMessage) {
        // Save message to model context if needed
        
        // Broadcast to all connected devices
        if let messageData = try? message.toData() {
            for device in bluetoothManager.nearbyDevices where device.isConnected {
                // Send the message
                bluetoothManager.sendData(messageData, to: device)
            }
        }
    }
    
    // Handle an incoming message
    private func handleIncomingMessage(_ message: BluetoothPeerMessage) {
        if message.messageType == .teamLocation {
            handleTeamLocationUpdate(message)
        } else if message.messageType == .teamChat {
            handleTeamChatMessage(message)
        }
    }
    
    // Handle team location update
    private func handleTeamLocationUpdate(_ message: BluetoothPeerMessage) {
        guard let data = message.data,
              let locationInfo = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let teamIdString = locationInfo["teamId"],
              let teamId = UUID(uuidString: teamIdString),
              let currentTeam = currentTeam,
              teamId == currentTeam.id,
              let latString = locationInfo["latitude"],
              let longitude = Double(locationInfo["longitude"] ?? "0"),
              let latitude = Double(latString) else {
            return
        }
        
        // Create or update team member
        if let index = teamMembers.firstIndex(where: { $0.userId == message.senderId }) {
            // Update existing member
            teamMembers[index].latitude = latitude
            teamMembers[index].longitude = longitude
            teamMembers[index].lastUpdated = Date()
        } else {
            // Add new member
            let member = TeamMember(
                userId: message.senderId,
                displayName: message.senderName,
                isCurrentUser: false,
                latitude: latitude,
                longitude: longitude,
                lastUpdated: Date()
            )
            teamMembers.append(member)
        }
    }
    
    // Handle team chat message
    private func handleTeamChatMessage(_ message: BluetoothPeerMessage) {
        guard let data = message.data,
              let chatInfo = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let teamIdString = chatInfo["teamId"],
              let teamId = UUID(uuidString: teamIdString),
              let currentTeam = currentTeam,
              teamId == currentTeam.id,
              let timestampString = chatInfo["timestamp"],
              let timestamp = ISO8601DateFormatter().date(from: timestampString) else {
            return
        }
        
        // Create chat message
        let chatMessage = ChatMessage(
            id: UUID(),
            teamId: teamId,
            senderId: message.senderId,
            senderName: message.senderName,
            message: message.content,
            timestamp: timestamp
        )
        
        // Add to chat if not already present
        if !teamChat.contains(where: { $0.id == chatMessage.id }) {
            teamChat.append(chatMessage)
            
            // Sort by timestamp
            teamChat.sort { $0.timestamp < $1.timestamp }
        }
    }
    
    // Request location permission
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Handle denied permission
            print("Location permission denied")
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension BluetoothTeamCoordinator: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isCoordinatingTeam, let location = locations.last else { return }
        
        // Update local team member
        updateLocalTeamMember(location: location)
    }
}

// MARK: - Model Classes
struct TeamMember: Identifiable, Equatable {
    let id = UUID()
    let userId: UUID
    let displayName: String
    let isCurrentUser: Bool
    var latitude: Double
    var longitude: Double
    var lastUpdated: Date
    
    var distance: Double?
    
    static func == (lhs: TeamMember, rhs: TeamMember) -> Bool {
        return lhs.id == rhs.id && 
               lhs.userId == rhs.userId &&
               lhs.displayName == rhs.displayName
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let teamId: UUID
    let senderId: UUID
    let senderName: String
    let message: String
    let timestamp: Date
    
    var isFromCurrentUser: Bool {
        // This would be set when displaying the message
        return false
    }
} 