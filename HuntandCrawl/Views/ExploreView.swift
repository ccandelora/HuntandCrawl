import SwiftUI
import SwiftData

struct ExploreView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(LocationManager.self) private var locationManager
    
    @State private var searchText = ""
    
    // Use separate queries for Hunts and BarCrawls
    @Query(sort: \Hunt.startTime) private var hunts: [Hunt]
    @Query(sort: \BarCrawl.startTime) private var barCrawls: [BarCrawl]

    // Filtered results based on search text
    var filteredHunts: [Hunt] {
        if searchText.isEmpty {
            return hunts
        } else {
            return hunts.filter { $0.name.localizedCaseInsensitiveContains(searchText) || 
                ($0.huntDescription?.localizedCaseInsensitiveContains(searchText) ?? false) }
        }
    }

    var filteredBarCrawls: [BarCrawl] {
        if searchText.isEmpty {
            return barCrawls
        } else {
            return barCrawls.filter { $0.name.localizedCaseInsensitiveContains(searchText) || 
                ($0.barCrawlDescription?.localizedCaseInsensitiveContains(searchText) ?? false) }
        }
    }

    var body: some View {
        List {
            // Featured Section with Location-based Features
            featuredSection
                
            // Scavenger Hunts Section
            Section("Scavenger Hunts") {
                if filteredHunts.isEmpty {
                    Text(searchText.isEmpty ? "No scavenger hunts available." : "No hunts match your search.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredHunts) { hunt in
                        Button {
                            navigationManager.navigateToHunt(hunt)
                        } label: {
                            huntRow(hunt: hunt)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Bar Crawls Section
            Section("Bar Crawls") {
                if filteredBarCrawls.isEmpty {
                    Text(searchText.isEmpty ? "No bar crawls available." : "No bar crawls match your search.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredBarCrawls) { barCrawl in
                        Button {
                            navigationManager.navigateToBarCrawl(barCrawl)
                        } label: {
                            barCrawlRow(barCrawl: barCrawl)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Explore")
        .searchable(text: $searchText, prompt: "Search Hunts & Crawls")
        .refreshable {
            // Add logic to refresh data if necessary
            print("Refresh triggered")
        }
    }
    
    // Featured location-based features
    private var featuredSection: some View {
        Section {
            // Team Challenges
            Button {
                navigationManager.navigateToDynamicChallenges()
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .frame(width: 36, height: 36)
                        .background(Color.blue)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text("Team Challenges")
                            .font(.headline)
                        Text("Create and complete challenges with your team")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Nearby View Button
            Button {
                navigationManager.navigateToNearbyLocations()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.green)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text("Nearby Points of Interest")
                            .font(.headline)
                        Text("Discover nearby stops and tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Location Status
            HStack {
                Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(locationManager.isAuthorized ? Color.blue : Color.gray)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text("Location Status")
                        .font(.headline)
                    Text(locationStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        } header: {
            Text("Featured")
        } footer: {
            Text("Location features enhance your experience with real-time proximity detection and offline capabilities.")
        }
    }
    
    private var locationStatusText: String {
        if !locationManager.isAuthorized {
            return "Location services disabled"
        } else if locationManager.userLocation != nil {
            return "Location available"
        } else {
            return "Waiting for location..."
        }
    }

    // Row view for a Hunt
    @ViewBuilder
    private func huntRow(hunt: Hunt) -> some View {
        HStack {
            Image(systemName: "map.fill") // Placeholder icon
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text(hunt.name).font(.headline)
                if let description = hunt.huntDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let startTime = hunt.startTime {
                    Text("Starts: \(startTime.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // Row view for a Bar Crawl
    @ViewBuilder
    private func barCrawlRow(barCrawl: BarCrawl) -> some View {
        HStack {
             Image(systemName: "figure.walk.motion") // Placeholder icon
                 .foregroundColor(.purple)
                 .frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text(barCrawl.name).font(.headline)
                if let description = barCrawl.barCrawlDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let startTime = barCrawl.startTime {
                    Text("Starts: \(startTime.formatted(.dateTime.month().day()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExploreView()
            .modelContainer(PreviewContainer.previewContainer)
            .environmentObject(NavigationManager())
            .environment(LocationManager())
    }
} 