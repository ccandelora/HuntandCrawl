import SwiftUI
import SwiftData
import PhotosUI

struct CreateView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var showingCreateHuntSheet = false
    @State private var showingCreateBarCrawlSheet = false

    // Example query to fetch existing items if needed for context
    // @Query var existingHunts: [Hunt]
    // @Query var existingBarCrawls: [BarCrawl]

    var body: some View {
        NavigationStack {
            List {
                Section("Create New Event") {
                    Button {
                        showingCreateHuntSheet = true
                    } label: {
                        Label("New Scavenger Hunt", systemImage: "map.fill")
                    }

                    Button {
                        showingCreateBarCrawlSheet = true
                    } label: {
                        Label("New Bar Crawl", systemImage: "figure.walk.motion")
                    }
                }
                
                // Add sections to display drafts or templates if needed
                // Section("Drafts") { ... }
            }
            .navigationTitle("Create")
            .sheet(isPresented: $showingCreateHuntSheet) {
                 // Assuming HuntCreatorView exists and takes no arguments initially
                 // or pass necessary context if required
                 HuntCreatorView()
                     .environment(\.modelContext, modelContext) // Pass context if needed
            }
            .sheet(isPresented: $showingCreateBarCrawlSheet) {
                 // Assuming BarCrawlCreatorView exists and takes no arguments initially
                 BarCrawlCreatorView()
                      .environment(\.modelContext, modelContext)
            }
        }
    }
}

// Placeholder for HuntCreatorView if it doesn't exist
struct HuntCreatorView: View {
     @Environment(\.dismiss) var dismiss
     var body: some View {
         NavigationStack {
             Text("Hunt Creator Placeholder")
             .navigationTitle("Create Hunt")
             .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
         }
     }
 }

// Placeholder for BarCrawlCreatorView
 struct BarCrawlCreatorView: View {
     @Environment(\.dismiss) var dismiss
     var body: some View {
         NavigationStack {
             Text("Bar Crawl Creator Placeholder")
             .navigationTitle("Create Bar Crawl")
             .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
         }
     }
 }

#Preview {
    NavigationStack {
        CreateView()
            .modelContainer(PreviewContainer.previewContainer) // Use the shared preview container
            .environmentObject(NavigationManager())
    }
} 