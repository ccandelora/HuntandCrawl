import SwiftUI
import MapKit
import CoreLocation
import SwiftData

struct TeamMapView: View {
    @EnvironmentObject var teamCoordinator: BluetoothTeamCoordinator
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0), // Default to Caribbean
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showTeamChat = false
    @State private var chatInputText = ""
    
    private let locationManager = CLLocationManager()
    
    var body: some View {
        ZStack {
            // Map with team member locations
            Map(position: $cameraPosition) {
                // Add annotations for team members
                ForEach(teamCoordinator.teamMembers) { member in
                    Annotation(member.displayName, coordinate: CLLocationCoordinate2D(latitude: member.latitude, longitude: member.longitude)) {
                        TeamMemberAnnotationView(member: member)
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapCompass()
                MapUserLocationButton()
                MapPitchToggle()
            }
            
            // Overlay controls
            VStack {
                Spacer()
                
                // Team status card
                teamStatusCard
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                
                // Action buttons
                actionButtonsRow
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .onAppear {
            updateMapRegion()
            
            // Request location permissions if not already granted
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
        }
        .onChange(of: teamCoordinator.teamMembers) { _, _ in
            updateMapRegion()
        }
        .sheet(isPresented: $showTeamChat) {
            teamChatView
        }
        .navigationTitle("Team Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Team status card view
    private var teamStatusCard: some View {
        VStack(spacing: 8) {
            if let team = teamCoordinator.currentTeam {
                Text(team.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("\(teamCoordinator.teamMembers.count) members online")
                    
                    Spacer()
                    
                    if teamCoordinator.isCoordinatingTeam {
                        Text("Location sharing active")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                .font(.caption)
            } else {
                Text("No team selected")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Action buttons row
    private var actionButtonsRow: some View {
        HStack(spacing: 16) {
            // Center button
            Button(action: centerMapOnTeam) {
                VStack {
                    Image(systemName: "map")
                        .font(.system(size: 20))
                    Text("Center")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            
            // Chat button
            Button(action: { showTeamChat = true }) {
                VStack {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 20))
                    Text("Team Chat")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(12)
            }
            
            // Stop sharing button
            Button(action: toggleLocationSharing) {
                VStack {
                    Image(systemName: teamCoordinator.isCoordinatingTeam ? "location.slash" : "location")
                        .font(.system(size: 20))
                    Text(teamCoordinator.isCoordinatingTeam ? "Stop Sharing" : "Start Sharing")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(teamCoordinator.isCoordinatingTeam ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundColor(teamCoordinator.isCoordinatingTeam ? .red : .blue)
                .cornerRadius(12)
            }
        }
    }
    
    // Team chat view
    private var teamChatView: some View {
        NavigationStack {
            VStack {
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(teamCoordinator.teamChat) { message in
                            chatBubble(for: message)
                        }
                    }
                    .padding()
                }
                
                // Input area
                HStack {
                    TextField("Message your team...", text: $chatInputText)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    Button(action: sendChatMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                    .disabled(chatInputText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Team Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        showTeamChat = false
                    }
                }
            }
        }
    }
    
    // Chat bubble for a message
    private func chatBubble(for message: ChatMessage) -> some View {
        let isCurrentUser = teamCoordinator.teamMembers.first(where: { $0.isCurrentUser })?.userId == message.senderId
        
        return HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                
                Text(message.message)
                    .padding()
                    .background(isCurrentUser ? Color.blue : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatMessageTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    // Helper to format chat message time
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Update map region to contain all team members
    private func updateMapRegion() {
        guard !teamCoordinator.teamMembers.isEmpty else { return }
        
        // If there's only one team member, center on them with default zoom
        if teamCoordinator.teamMembers.count == 1, let member = teamCoordinator.teamMembers.first {
            mapRegion.center = CLLocationCoordinate2D(latitude: member.latitude, longitude: member.longitude)
            cameraPosition = .region(mapRegion)
            return
        }
        
        // Calculate the region that contains all team members
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        
        for member in teamCoordinator.teamMembers {
            minLat = min(minLat, member.latitude)
            maxLat = max(maxLat, member.latitude)
            minLon = min(minLon, member.longitude)
            maxLon = max(maxLon, member.longitude)
        }
        
        // Add some padding
        let latPadding = (maxLat - minLat) * 0.2
        let lonPadding = (maxLon - minLon) * 0.2
        
        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.005, (maxLat - minLat) + latPadding),
                longitudeDelta: max(0.005, (maxLon - minLon) + lonPadding)
            )
        )
        
        mapRegion = newRegion
        cameraPosition = .region(mapRegion)
    }
    
    // Center map on team
    private func centerMapOnTeam() {
        updateMapRegion()
    }
    
    // Toggle location sharing
    private func toggleLocationSharing() {
        if teamCoordinator.isCoordinatingTeam {
            teamCoordinator.stopTeamCoordination()
        } else if let team = teamCoordinator.currentTeam {
            teamCoordinator.startTeamCoordination(for: team)
        }
    }
    
    // Send chat message
    private func sendChatMessage() {
        guard !chatInputText.isEmpty else { return }
        
        teamCoordinator.sendTeamChatMessage(chatInputText)
        chatInputText = ""
    }
}

// Team member annotation view
struct TeamMemberAnnotationView: View {
    let member: TeamMember
    
    var body: some View {
        ZStack {
            Circle()
                .fill(member.isCurrentUser ? Color.blue : Color.green)
                .frame(width: 40, height: 40)
                .shadow(radius: 3)
            
            Text(member.displayName.prefix(1).uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct TeamMapView_Previews: PreviewProvider {
    static var previews: some View {
        let teamCoordinator = BluetoothTeamCoordinator(
            bluetoothManager: BluetoothManager(),
            messageManager: BluetoothMessageManager(
                bluetoothManager: BluetoothManager()
            ),
            currentUser: nil as User?
        )
        
        // Add sample team members for preview
        teamCoordinator.teamMembers = [
            TeamMember(
                userId: UUID(),
                displayName: "You",
                isCurrentUser: true,
                latitude: 25.0,
                longitude: -80.0,
                lastUpdated: Date()
            ),
            TeamMember(
                userId: UUID(),
                displayName: "John",
                isCurrentUser: false,
                latitude: 25.01,
                longitude: -80.01,
                lastUpdated: Date()
            ),
            TeamMember(
                userId: UUID(),
                displayName: "Emma",
                isCurrentUser: false,
                latitude: 24.99,
                longitude: -80.005,
                lastUpdated: Date()
            )
        ]
        
        return NavigationStack {
            TeamMapView()
                .environmentObject(teamCoordinator)
        }
    }
} 