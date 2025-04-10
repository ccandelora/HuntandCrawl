import SwiftUI
import SwiftData

struct HuntandCrawlApp: App {
    // Create a migration plan for the memberIds array issue
    let container: ModelContainer
    let navigationManager = NavigationManager()
    let locationManager = LocationManager()
    let networkMonitor = NetworkMonitor()
    
    init() {
        // Define all the models for our app
        let schema = Schema([
            Team.self,
            User.self,
            Hunt.self,
            HuntTask.self,
            BarCrawl.self,
            BarStop.self,
            BarStopVisit.self,
            TaskCompletion.self,
            CruiseShip.self,
            CruiseLine.self,
            CruiseBar.self,
            CruiseBarStop.self,
            CruiseBarDrink.self,
            CruiseBarCrawlRoute.self,
            CruiseBarCrawlStop.self
        ])
        
        // Configure with standard settings
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        // Initialize the container
        do {
            // Create the container
            let tempContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Initialize the container property first
            self.container = tempContainer
            
            // Now we can safely call self methods after all properties are initialized
            // Run migrations if needed
            DataMigrationManager.shared.performMigrations(modelContainer: tempContainer)
            
            // Add sample data for the app
            HuntandCrawlApp.createSampleData(in: tempContainer)
            
        } catch {
            // Handle any errors
            print("Failed to create ModelContainer: \(error.localizedDescription)")
            
            // Create an in-memory container as fallback
            do {
                let fallbackContainer = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
                )
                
                self.container = fallbackContainer
                
                // Add sample data to the fallback container
                HuntandCrawlApp.createSampleData(in: fallbackContainer)
                
            } catch {
                fatalError("Could not create even a memory-only container: \(error)")
            }
        }
    }
    
    // Create sample data to populate the app
    static func createSampleData(in container: ModelContainer) {
        let context = ModelContext(container)
        
        // Check if we already have data (don't create duplicates on every launch)
        let huntsDescriptor = FetchDescriptor<Hunt>()
        let barCrawlsDescriptor = FetchDescriptor<BarCrawl>()
        
        do {
            // Only add sample data if we don't have any hunts or bar crawls
            let existingHunts = try context.fetch(huntsDescriptor)
            let existingBarCrawls = try context.fetch(barCrawlsDescriptor)
            
            if existingHunts.isEmpty && existingBarCrawls.isEmpty {
                // Create sample hunts
                let treasureHunt = Hunt(
                    name: "Treasure Hunt",
                    huntDescription: "Find hidden treasures around the ship",
                    difficulty: "Medium",
                    startTime: Calendar.current.date(bySettingHour: 8, minute: 45, second: 0, of: Date())!,
                    endTime: Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!,
                    isActive: true
                )
                
                let photoChallenge = Hunt(
                    name: "Photo Challenge",
                    huntDescription: "Capture the perfect moments on your cruise",
                    difficulty: "Easy",
                    startTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
                    endTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!,
                    isActive: true
                )
                
                // Create sample bar crawls
                let ultimateBarCrawl = BarCrawl(
                    name: "Ultimate Bar Tour",
                    barCrawlDescription: "Visit all the best bars on the ship",
                    theme: "Premium Drinks",
                    startTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!,
                    endTime: Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date().addingTimeInterval(86400))!,
                    isActive: true
                )
                
                let tropicalVibes = BarCrawl(
                    name: "Tropical Vibes",
                    barCrawlDescription: "Experience tropical drinks and atmosphere",
                    theme: "Tropical",
                    startTime: Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date())!,
                    endTime: Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!,
                    isActive: true
                )
                
                // Insert them into the context
                context.insert(treasureHunt)
                context.insert(photoChallenge)
                context.insert(ultimateBarCrawl)
                context.insert(tropicalVibes)
                
                // Save changes
                try context.save()
                print("Sample data created successfully")
            } else {
                print("Sample data already exists - skipping creation")
            }
        } catch {
            print("Error creating sample data: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(navigationManager)
                .environment(locationManager)
                .environment(networkMonitor)
        }
        .modelContainer(container)
    }
} 