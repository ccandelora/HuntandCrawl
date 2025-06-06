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
        mainTabView
            .accentColor(AppColors.defaultPrimary)
            .overlay {
                syncMessageOverlay
                
                if selectedTab == 0 {
                    createFloatingButton
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
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Explore Tab
            NavigationStack(path: $navigationManager.path) {
                ExploreView()
                    .navigationDestination(for: NavigationManager.Destination.self) { destination in
                        navigationManager.view(for: destination)
                    }
            }
            .tabItem {
                Label("Explore", systemImage: "map.fill")
            }
            .tag(0)
            
            // Create Tab
            NavigationStack {
                CreateView()
                    .navigationDestination(for: NavigationManager.Destination.self) { destination in
                        navigationManager.view(for: destination)
                    }
            }
            .tabItem {
                Label("Create", systemImage: "plus.circle.fill")
            }
            .tag(1)
            
            // Profile Tab
            NavigationStack {
                ProfileView()
                    .navigationDestination(for: NavigationManager.Destination.self) { destination in
                        navigationManager.view(for: destination)
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(2)
        }
    }
    
    private var createFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    if showingSyncMessage {
                        syncManager.trySync()
                    } else {
                        presentCreateOptions()
                    }
                }) {
                    Image(systemName: showingSyncMessage ? "arrow.clockwise" : "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(AppColors.defaultPrimary)
                        .cornerRadius(28)
                        .shadow(radius: 3)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func presentCreateOptions() {
        let createActions: [NavigationManager.ConfirmationAction] = [
            NavigationManager.ConfirmationAction(
                title: "Create Hunt",
                role: nil,
                handler: { self.navigationManager.presentSheet(.createHunt) }
            ),
            NavigationManager.ConfirmationAction(
                title: "Create Bar Crawl",
                role: nil,
                handler: { self.navigationManager.presentSheet(.createBarCrawl) }
            ),
            NavigationManager.ConfirmationAction(
                title: "Cancel",
                role: .cancel,
                handler: {}
            )
        ]
        
        navigationManager.presentConfirmation(
            title: "Create",
            message: "What would you like to create?",
            actions: createActions
        )
    }
    
    // MARK: - Sync Message Overlay
    private var syncMessageOverlay: some View {
        VStack {
            if showingSyncMessage {
                syncMessageBanner
            }
            
            Spacer()
        }
    }
    
    private var syncMessageBanner: some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(AppColors.defaultPrimary)
            
            Text(syncStatusMessage)
                .font(AppTextStyles.footnote)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showingSyncMessage = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .zIndex(1)
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
        print("MainTabView: ModelContext available")
    }
    
    private func handleSyncStatusChange(_ status: SyncManager.SyncStatus) {
        switch status {
        case .syncing:
            syncStatusMessage = "Syncing data..."
            withAnimation {
                showingSyncMessage = true
            }
        case .synced:
            syncStatusMessage = "Data synced successfully"
            withAnimation {
                showingSyncMessage = true
            }
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
            withAnimation {
                showingSyncMessage = true
            }
            // Hide message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingSyncMessage = false
                }
            }
        case .idle:
            withAnimation {
                showingSyncMessage = false
            }
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
            HuntTask.self,
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
            let task1 = HuntTask(title: "Find the Captain's Wheel", points: 100, verificationMethod: .photo)
            task1.taskDescription = "Take a photo of yourself at the captain's wheel on the bridge deck"
            task1.deckNumber = 14
            task1.locationOnShip = "Bridge Deck"
            task1.section = "Forward"
            task1.hunt = hunt1
            
            let task2 = HuntTask(title: "Waterslide Challenge", points: 150, verificationMethod: .photo)
            task2.taskDescription = "Complete all waterslides and take a photo at the bottom of the biggest one"
            task2.deckNumber = 12
            task2.locationOnShip = "Pool Deck"
            task2.section = "Aft"
            task2.hunt = hunt1
            
            let task3 = HuntTask(title: "Cruise Trivia", points: 75, verificationMethod: .question)
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
            barStop1.deckNumber = 15
            barStop1.locationOnShip = "Pool Deck"
            barStop1.section = "Aft"
            barStop1.openingTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!
            barStop1.closingTime = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!
            barStop1.barCrawl = barCrawl
            barStop1.order = 1
            
            let barStop2 = BarStop(name: "Skyline Lounge", specialDrink: "Blue Horizon", drinkPrice: 14.99)
            barStop2.barStopDescription = "Sophisticated lounge with panoramic views and signature cocktails"
            barStop2.deckNumber = 14
            barStop2.locationOnShip = "Observation Deck"
            barStop2.section = "Forward"
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
            let visit = BarStopVisit(visitedAt: Date(), barStop: barStop1, user: user)
            modelContext.insert(visit)
            
            try? modelContext.save()
            
            return container
        } catch {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }()
} 