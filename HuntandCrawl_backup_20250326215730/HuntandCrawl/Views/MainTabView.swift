import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.modelContext) private var modelContext
    @State private var syncManager: SyncManager?
    @State private var bluetoothManager = BluetoothManager()
    @State private var messageManager: BluetoothMessageManager?
    @State private var teamCoordinator: BluetoothTeamCoordinator?
    @State private var locationManager = LocationManager()
    @State private var geofencingManager: GeofencingManager?
    @State private var showNearbyLocations = false
    @Query private var currentUser: [User]
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                ExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "map")
                    }
                    .tag(0)
                
                CreateView()
                    .tabItem {
                        Label("Create", systemImage: "plus.circle")
                    }
                    .tag(1)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(2)
            }
            .accentColor(.indigo)
            
            // Show sync status at the top
            if let syncManager = syncManager {
                VStack {
                    HStack {
                        Spacer()
                        SyncStatusView(syncManager: syncManager)
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    Spacer()
                }
            }
            
            // Floating "Nearby" button for GPS discovery
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showNearbyLocations = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                                .shadow(radius: 4)
                            
                            VStack(spacing: 2) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                Text("Nearby")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding([.trailing, .bottom], 20)
                }
            }
        }
        .onAppear {
            // Set up synchronization manager if not already set
            if syncManager == nil {
                syncManager = SyncManager(modelContext: modelContext)
            }
            
            // Set up Bluetooth message manager
            if messageManager == nil {
                messageManager = BluetoothMessageManager(
                    modelContext: modelContext,
                    bluetoothManager: bluetoothManager,
                    currentUser: currentUser.first
                )
            }
            
            // Set up team coordinator
            if teamCoordinator == nil {
                teamCoordinator = BluetoothTeamCoordinator(
                    modelContext: modelContext,
                    bluetoothManager: bluetoothManager,
                    messageManager: messageManager ?? BluetoothMessageManager(
                        modelContext: modelContext,
                        bluetoothManager: bluetoothManager,
                        currentUser: currentUser.first
                    ),
                    currentUser: currentUser.first
                )
            }
            
            // Set up geofencing manager
            if geofencingManager == nil {
                geofencingManager = GeofencingManager(
                    locationManager: locationManager,
                    modelContext: modelContext
                )
                
                // Start location updates
                locationManager.startUpdatingLocation()
                
                // Setup geofences for active hunts and bar crawls
                setupGeofences()
            }
        }
        .environmentObject(bluetoothManager)
        .environmentObject(messageManager ?? BluetoothMessageManager(
            modelContext: modelContext,
            bluetoothManager: bluetoothManager,
            currentUser: currentUser.first
        ))
        .environmentObject(teamCoordinator ?? BluetoothTeamCoordinator(
            modelContext: modelContext,
            bluetoothManager: bluetoothManager,
            messageManager: messageManager ?? BluetoothMessageManager(
                modelContext: modelContext,
                bluetoothManager: bluetoothManager,
                currentUser: currentUser.first
            ),
            currentUser: currentUser.first
        ))
        .environmentObject(locationManager)
        .environmentObject(geofencingManager ?? GeofencingManager(
            locationManager: locationManager,
            modelContext: modelContext
        ))
        .sheet(isPresented: $showNearbyLocations) {
            NearbyLocationsView()
        }
    }
    
    // Setup geofences for currently active hunts and bar crawls
    private func setupGeofences() {
        guard let geofencingManager = geofencingManager else { return }
        
        // Fetch active hunts
        let huntDescriptor = FetchDescriptor<Hunt>()
        
        do {
            let hunts = try modelContext.fetch(huntDescriptor)
            
            // Setup geofences for all active hunts
            for hunt in hunts {
                geofencingManager.setupGeofencesForHunt(hunt)
            }
        } catch {
            print("Error fetching hunts: \(error)")
        }
        
        // Fetch active bar crawls
        let barCrawlDescriptor = FetchDescriptor<BarCrawl>()
        
        do {
            let barCrawls = try modelContext.fetch(barCrawlDescriptor)
            
            // Setup geofences for all active bar crawls
            for barCrawl in barCrawls {
                geofencingManager.setupGeofencesForBarCrawl(barCrawl)
            }
        } catch {
            print("Error fetching bar crawls: \(error)")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            Item.self, 
            Hunt.self, 
            Task.self, 
            User.self, 
            BarCrawl.self, 
            BarStop.self, 
            Team.self, 
            SyncEvent.self, 
            TaskCompletion.self,
            BarStopVisit.self,
            BluetoothPeerMessage.self
        ], inMemory: true)
        .environmentObject(NetworkMonitor())
} 