import SwiftUI
import SwiftData
import Combine
import CoreLocation
import MapKit

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Managers
    @State private var locationManager = LocationManager()
    @StateObject private var navigationManager = NavigationManager()
    @State private var syncManager = SyncManager()
    
    // MARK: - State
    @State private var selectedTab = 0
    @State private var showingSyncMessage = false
    @State private var syncStatusMessage = ""
    @State private var showingSyncAlert = false
    @State private var syncAlertMessage = ""
    @State private var pendingSyncCount = 0
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationManager.path) {
                ExploreView()
                    .navigationDestination(for: NavigationManager.Destination.self) { destination in
                        navigationManager.view(for: destination)
                    }
            }
            .tabItem {
                Label("Explore", systemImage: "map")
            }
            .tag(0)
            
            NavigationStack {
                CreateView()
            }
            .tabItem {
                Label("Create", systemImage: "plus.circle")
            }
            .tag(1)
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(2)
        }
        .overlay {
            if showingSyncMessage {
                VStack {
                    Text(syncStatusMessage)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding()
                    Spacer()
                }
                .transition(.move(edge: .top))
            }
        }
        .sheet(isPresented: $navigationManager.isSheetPresented) {
            if let activeSheet = navigationManager.activeSheet {
                navigationManager.view(for: activeSheet)
            }
        }
        .fullScreenCover(isPresented: $navigationManager.isFullscreenPresented) {
            if let fullscreenDestination = navigationManager.fullscreenDestination {
                navigationManager.view(for: fullscreenDestination)
            }
        }
        .confirmationDialog(
            navigationManager.confirmationTitle,
            isPresented: $navigationManager.isConfirmationDialogPresented,
            actions: {
                ForEach(navigationManager.confirmationActions) { action in
                    Button(role: action.role) {
                        action.handler()
                    } label: {
                        Text(action.title)
                    }
                }
            },
            message: {
                Text(navigationManager.confirmationMessage)
            }
        )
        .alert(
            navigationManager.alertTitle,
            isPresented: $navigationManager.isAlertPresented,
            actions: {
                ForEach(navigationManager.alertActions) { action in
                    Button(role: action.role) {
                        action.handler()
                    } label: {
                        Text(action.title)
                    }
                }
            },
            message: {
                Text(navigationManager.alertMessage)
            }
        )
        .onAppear {
            initializeManagers()
        }
        .onChange(of: syncManager.syncStatus) { _, newValue in
            handleSyncStatusChange(newValue)
        }
        .onChange(of: syncManager.pendingSyncCount) { _, newCount in
            pendingSyncCount = newCount
            if newCount > 0 {
                syncStatusMessage = "Pending syncs: \(newCount)"
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .environmentObject(navigationManager)
        .environment(locationManager)
        .environment(syncManager)
    }
    
    // MARK: - Methods
    private func initializeManagers() {
        // Initialize location services
        locationManager.checkLocationAuthorization()
        locationManager.startLocationUpdates()
        
        // Initialize sync manager with the current modelContext
        syncManager.initialize(modelContext: modelContext)
        
        // Print debug info
        print("MainTabView: Managers initialized")
        print("MainTabView: ModelContext available: \(modelContext != nil)")
    }
    
    private func handleSyncStatusChange(_ status: SyncManager.SyncStatus) {
        switch status {
        case .syncing:
            syncStatusMessage = "Syncing data..."
            showingSyncMessage = true
        case .synced:
            syncStatusMessage = "Data synced successfully"
            showingSyncMessage = true
            // Hide message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingSyncMessage = false
                }
            }
        case .error(let message):
            syncAlertMessage = "Sync error: \(message)"
            showingSyncAlert = true
        case .offline:
            syncStatusMessage = "Working offline"
            showingSyncMessage = true
            // Hide message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingSyncMessage = false
                }
            }
        case .idle:
            showingSyncMessage = false
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active
            locationManager.startLocationUpdates()
            syncManager.trySync()
        case .inactive:
            // App became inactive
            break
        case .background:
            // App went to background
            locationManager.stopLocationUpdates()
        @unknown default:
            break
        }
    }
}

// MARK: - Previews
#Preview {
    MainTabView()
        .modelContainer(PreviewContainer.previewContainer)
}

// Container for preview data
struct PreviewContainer {
    @MainActor
    static var previewContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Hunt.self,
            Task.self,
            TaskCompletion.self,
            SyncEvent.self,
            BarCrawl.self,
            BarStop.self,
            BarStopVisit.self,
            Team.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            // Create preview data in the container's context
            let modelContext = container.mainContext
            
            // Create a sample user
            let user = User(name: "John Doe", email: "john@example.com")
            user.avatarUrl = "https://randomuser.me/api/portraits/men/1.jpg"
            modelContext.insert(user)
            
            // Create sample hunts
            let hunt1 = Hunt(name: "Treasure Hunt", huntDescription: "Find hidden treasures around the ship", difficulty: "Medium")
            hunt1.startTime = Calendar.current.date(byAdding: .hour, value: -2, to: Date())
            hunt1.endTime = Calendar.current.date(byAdding: .day, value: 2, to: Date())
            hunt1.creator = user
            
            // Add tasks to hunt1
            let task1 = Task(title: "Find the Captain's Wheel", points: 100, verificationMethod: .photo)
            task1.taskDescription = "Take a photo of yourself at the captain's wheel on the bridge deck"
            task1.latitude = 25.0001
            task1.longitude = -80.0001
            task1.hunt = hunt1
            
            let task2 = Task(title: "Waterslide Challenge", points: 150, verificationMethod: .photo)
            task2.taskDescription = "Complete all waterslides and take a photo at the bottom of the biggest one"
            task2.latitude = 25.0015
            task2.longitude = -80.0020
            task2.hunt = hunt1
            
            let task3 = Task(title: "Cruise Trivia", points: 75, verificationMethod: .question)
            task3.taskDescription = "Answer this question about the ship"
            task3.question = "In what year was this cruise ship built?"
            task3.answer = "2015"
            task3.hunt = hunt1
            
            modelContext.insert(hunt1)
            modelContext.insert(task1)
            modelContext.insert(task2)
            modelContext.insert(task3)
            
            // Create another hunt
            let hunt2 = Hunt(name: "Night Adventure", huntDescription: "Explore the ship after dark", difficulty: "Hard")
            hunt2.startTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            hunt2.endTime = Calendar.current.date(byAdding: .day, value: 3, to: Date())
            hunt2.creator = user
            modelContext.insert(hunt2)
            
            // Create a bar crawl
            let barCrawl = BarCrawl(name: "Ultimate Cocktail Tour", barCrawlDescription: "Visit the best bars on the ship", theme: "Tropical")
            barCrawl.startTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())
            barCrawl.endTime = Calendar.current.date(byAdding: .day, value: 7, to: Date())
            barCrawl.creator = user
            modelContext.insert(barCrawl)
            
            // Add bar stops to the bar crawl
            let barStop1 = BarStop(name: "Sunset Bar", specialDrink: "Mai Tai", drinkPrice: 12.99)
            barStop1.barStopDescription = "Enjoy stunning sunset views with a delicious Mai Tai"
            barStop1.latitude = 25.0005
            barStop1.longitude = -80.0010
            barStop1.openingTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!
            barStop1.closingTime = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!
            barStop1.barCrawl = barCrawl
            barStop1.order = 1
            
            let barStop2 = BarStop(name: "Skyline Lounge", specialDrink: "Blue Horizon", drinkPrice: 14.99)
            barStop2.barStopDescription = "Sophisticated lounge with panoramic views and signature cocktails"
            barStop2.latitude = 25.0008
            barStop2.longitude = -80.0015
            barStop2.openingTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
            barStop2.closingTime = Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date())!
            barStop2.barCrawl = barCrawl
            barStop2.order = 2
            barStop2.isVIP = true
            
            modelContext.insert(barStop1)
            modelContext.insert(barStop2)
            
            // Create a task completion
            let completion = TaskCompletion(
                task: task1,
                userId: user.id,
                completedAt: Date(),
                verificationMethod: .photo,
                isVerified: true
            )
            modelContext.insert(completion)
            
            // Create a bar stop visit
            let visit = BarStopVisit(barStop: barStop1, user: user)
            visit.visitedAt = Date()
            modelContext.insert(visit)
            
            try? modelContext.save()
            
            return container
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }()
} 