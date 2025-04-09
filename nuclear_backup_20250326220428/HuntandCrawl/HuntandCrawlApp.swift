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
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var syncManager: SyncManager?

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Initialize the SyncManager with the model context from the container
                    if syncManager == nil {
                        let context = sharedModelContainer.mainContext
                        syncManager = SyncManager(modelContext: context, networkMonitor: networkMonitor)
                    }
                }
                .environmentObject(networkMonitor)
        }
        .modelContainer(sharedModelContainer)
    }
}
