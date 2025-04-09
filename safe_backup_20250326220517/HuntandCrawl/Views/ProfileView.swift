import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Query private var users: [User]
    @Query private var teams: [Team]
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    
    @State private var currentUser: User?
    @State private var isEditingProfile = false
    @State private var showCreateTeam = false
    @State private var showNearbyDevices = false
    @State private var showTeamMap: Team? = nil
    
    var body: some View {
        NavigationStack {
            List {
                // User Profile Section
                Section {
                    if let user = currentUser {
                        userProfileRow(user: user)
                    } else {
                        Text("Create a profile to track your progress")
                    }
                } header: {
                    Text("Profile")
                }
                
                // Teams Section
                Section {
                    ForEach(userTeams) { team in
                        teamRow(team: team)
                    }
                    
                    Button(action: { showCreateTeam = true }) {
                        Label("Create or Join Team", systemImage: "person.3.fill")
                    }
                } header: {
                    Text("Teams")
                }
                
                // Bluetooth Section
                Section {
                    // Nearby Players Button
                    Button(action: { showNearbyDevices = true }) {
                        HStack {
                            Image(systemName: "wave.3.right")
                                .foregroundColor(.blue)
                            Text("Nearby Players")
                            Spacer()
                            if bluetoothManager.nearbyDevices.count > 0 {
                                Text("\(bluetoothManager.nearbyDevices.count)")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Bluetooth Status
                    HStack {
                        Image(systemName: bluetoothManager.isBluetoothEnabled ? "bolt.horizontal.circle.fill" : "bolt.horizontal.circle")
                            .foregroundColor(bluetoothManager.isBluetoothEnabled ? .green : .gray)
                        Text("Bluetooth: \(bluetoothManager.isBluetoothEnabled ? "On" : "Off")")
                        Spacer()
                        Toggle("", isOn: Binding<Bool>(
                            get: { bluetoothManager.isAdvertising },
                            set: { newValue in
                                if newValue {
                                    bluetoothManager.startAdvertising()
                                } else {
                                    bluetoothManager.stopAdvertising()
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Connect")
                }
                
                // Settings Section
                Section {
                    NavigationLink(destination: OfflineSettingsView()) {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("Offline Settings")
                        }
                    }
                } header: {
                    Text("Settings")
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                if currentUser != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            isEditingProfile = true
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create") {
                            isEditingProfile = true
                        }
                    }
                }
            }
            .onAppear {
                if users.isEmpty {
                    currentUser = nil
                } else {
                    currentUser = users.first
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(existingUser: currentUser)
            }
            .sheet(isPresented: $showCreateTeam) {
                CreateTeamView()
            }
            .sheet(isPresented: $showNearbyDevices) {
                NearbyDevicesView()
            }
            .fullScreenCover(item: $showTeamMap) { team in
                NavigationStack {
                    TeamMapView()
                        .onAppear {
                            if let teamCoordinator = teamCoordinator {
                                teamCoordinator.startTeamCoordination(for: team)
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Close") {
                                    if let teamCoordinator = teamCoordinator {
                                        teamCoordinator.stopTeamCoordination()
                                    }
                                    showTeamMap = nil
                                }
                            }
                        }
                }
            }
        }
    }
    
    @EnvironmentObject private var teamCoordinator: BluetoothTeamCoordinator
    
    // User Profile Row
    private func userProfileRow(user: User) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(user.displayName.prefix(1).uppercased())
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("\(user.totalPoints)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Spacer()
                        .frame(width: 20)
                    
                    Text("Joined \(user.createdAt.formatted(.dateTime.month().year()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // Team Row
    private func teamRow(team: Team) -> some View {
        Button(action: {
            showTeamMap = team
        }) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(team.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text(team.name)
                        .font(.headline)
                    
                    Text("\(team.memberIds.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
                
                Spacer()
                
                Image(systemName: "map")
                    .foregroundColor(.blue)
                    .padding(.trailing, 8)
            }
        }
    }
    
    // Teams that the current user is a member of
    private var userTeams: [Team] {
        guard let currentUser = currentUser else { return [] }
        
        // Manual filtering instead of using SwiftData predicate
        return teams.filter { team in
            // Manually check if the currentUser.id is in the memberIds array
            for memberId in team.memberIds {
                if memberId == currentUser.id {
                    return true
                }
            }
            return false
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [User.self, Hunt.self], inMemory: true)
} 