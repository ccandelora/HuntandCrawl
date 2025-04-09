//
//  HuntandCrawlApp.swift
//  HuntandCrawl
//
//  Created by Chris Candelora on 3/26/25.
//

import SwiftUI
import SwiftData

struct HuntandCrawlApp: App {
    @State var networkMonitor = NetworkMonitor()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,  // Include Item.self (the default model)
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
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If we can't create the model container, print the error and use a fail-safe container
            print("Failed to create ModelContainer: \(error)")
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Make sure we have at least one item for the ContentView if it's needed
                    let context = sharedModelContainer.mainContext
                    let fetchDescriptor = FetchDescriptor<Item>()
                    do {
                        if try context.fetch(fetchDescriptor).isEmpty {
                            let newItem = Item(timestamp: Date())
                            context.insert(newItem)
                            try context.save()
                            print("Added sample item on first launch")
                        }
                    } catch {
                        print("Error checking or adding sample item: \(error)")
                    }
                    
                    print("MainTabView appeared")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
