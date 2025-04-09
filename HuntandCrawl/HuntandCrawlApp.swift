//
//  HuntandCrawlApp.swift
//  HuntandCrawl
//
//  Created by Chris Candelora on 3/26/25.
//

import SwiftUI
import SwiftData

@main
struct HuntandCrawlApp: App {
    @State var networkMonitor = NetworkMonitor()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Hunt.self,
            Task.self,
            TaskCompletion.self,
            BarCrawl.self,
            BarStop.self,
            BarStopVisit.self,
            User.self,
            Team.self,
            SyncEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            @MainActor func prepopulateIfNeeded() {
                // Pre-populate data if needed on first launch
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // Check Network Status and Inject NetworkMonitor
            if networkMonitor.isConnected {
                MainTabView()
            } else {
                // Show an offline view or alert
                OfflineView()
            }
        }
        .modelContainer(sharedModelContainer)
        .environment(networkMonitor)
    }
}
