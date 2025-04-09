import SwiftUI
import SwiftData

struct SearchResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    
    @Query private var hunts: [Hunt]
    @Query private var barCrawls: [BarCrawl]
    @Query private var users: [User]
    
    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    
    enum SearchFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case hunts = "Hunts"
        case barCrawls = "Bar Crawls"
        case users = "Users"
        
        var id: String { self.rawValue }
    }
    
    // Optional initializer to set initial search text
    init(searchText: String = "") {
        self._searchText = State(initialValue: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter selector
            Picker("Filter", selection: $selectedFilter) {
                ForEach(SearchFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Search results
            List {
                if searchText.isEmpty {
                    ContentUnavailableView("Search", systemImage: "magnifyingglass", description: Text("Enter a search term to find hunts, bar crawls, and users"))
                } else if noResults {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("No matches for '\(searchText)'"))
                } else {
                    // Hunts section
                    if selectedFilter == .all || selectedFilter == .hunts {
                        if !filteredHunts.isEmpty {
                            Section("Hunts") {
                                ForEach(filteredHunts) { hunt in
                                    HuntRow(hunt: hunt)
                                        .onTapGesture {
                                            navigationManager.navigateToHunt(hunt)
                                        }
                                }
                            }
                        }
                    }
                    
                    // Bar Crawls section
                    if selectedFilter == .all || selectedFilter == .barCrawls {
                        if !filteredBarCrawls.isEmpty {
                            Section("Bar Crawls") {
                                ForEach(filteredBarCrawls) { barCrawl in
                                    BarCrawlRow(barCrawl: barCrawl)
                                        .onTapGesture {
                                            navigationManager.navigateToBarCrawl(barCrawl)
                                        }
                                }
                            }
                        }
                    }
                    
                    // Users section
                    if selectedFilter == .all || selectedFilter == .users {
                        if !filteredUsers.isEmpty {
                            Section("Users") {
                                ForEach(filteredUsers) { user in
                                    UserRow(user: user)
                                        .onTapGesture {
                                            navigationManager.navigateToUserProfile(user)
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .searchable(text: $searchText, prompt: "Search for hunts, bar crawls, users...")
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var filteredHunts: [Hunt] {
        if searchText.isEmpty {
            return []
        } else {
            return hunts.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.huntDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private var filteredBarCrawls: [BarCrawl] {
        if searchText.isEmpty {
            return []
        } else {
            return barCrawls.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return []
        } else {
            return users.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var noResults: Bool {
        switch selectedFilter {
        case .all:
            return filteredHunts.isEmpty && filteredBarCrawls.isEmpty && filteredUsers.isEmpty
        case .hunts:
            return filteredHunts.isEmpty
        case .barCrawls:
            return filteredBarCrawls.isEmpty
        case .users:
            return filteredUsers.isEmpty
        }
    }
}

struct HuntRow: View {
    let hunt: Hunt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(hunt.name)
                .font(.headline)
            
            if let description = hunt.huntDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let startTime = hunt.startTime {
                    Text(formatDate(startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let tasks = hunt.tasks {
                    Text("\(tasks.count) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct BarCrawlRow: View {
    let barCrawl: BarCrawl
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(barCrawl.name)
                .font(.headline)
            
            if let description = barCrawl.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let startTime = barCrawl.startTime {
                    Text(formatDate(startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let stops = barCrawl.barStops {
                    Text("\(stops.count) stops")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.headline)
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SearchResultsView(searchText: "test")
            .modelContainer(PreviewContainer.previewContainer)
            .environmentObject(NavigationManager())
    }
} 