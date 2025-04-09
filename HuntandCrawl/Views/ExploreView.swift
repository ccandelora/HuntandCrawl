import SwiftUI
import SwiftData

struct ExploreView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(LocationManager.self) private var locationManager
    
    @State private var searchText = ""
    @State private var selectedCategory: Category = .all
    
    enum Category: String, CaseIterable, Identifiable {
        case all = "All"
        case scavengerHunts = "Scavenger Hunts"
        case barCrawls = "Bar Crawls"
        
        var id: String { self.rawValue }
    }
    
    // Use separate queries for Hunts and BarCrawls
    @Query(sort: \Hunt.startTime) private var hunts: [Hunt]
    @Query(sort: \BarCrawl.startTime) private var barCrawls: [BarCrawl]

    // Filtered results based on search text and category
    var filteredHunts: [Hunt] {
        if selectedCategory == .barCrawls {
            return []
        }
        
        if searchText.isEmpty {
            return hunts
        } else {
            return hunts.filter { $0.name.localizedCaseInsensitiveContains(searchText) || 
                ($0.huntDescription?.localizedCaseInsensitiveContains(searchText) ?? false) }
        }
    }

    var filteredBarCrawls: [BarCrawl] {
        if selectedCategory == .scavengerHunts {
            return []
        }
        
        if searchText.isEmpty {
            return barCrawls
        } else {
            return barCrawls.filter { $0.name.localizedCaseInsensitiveContains(searchText) || 
                ($0.barCrawlDescription?.localizedCaseInsensitiveContains(searchText) ?? false) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Category.allCases) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Featured events with large cards
                if filteredHunts.count > 0 || filteredBarCrawls.count > 0 {
                    VStack(alignment: .leading) {
                        Text("Featured")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                if let featuredHunt = filteredHunts.first {
                                    FeaturedEventCard(
                                        title: featuredHunt.name,
                                        description: featuredHunt.huntDescription ?? "Join this exciting scavenger hunt!",
                                        date: featuredHunt.startTime?.formatted(.dateTime.month().day().hour().minute()) ?? "Coming soon",
                                        location: "Various locations",
                                        type: "Scavenger Hunt",
                                        action: { navigationManager.navigateToHunt(featuredHunt) }
                                    )
                                }
                                
                                if let featuredBarCrawl = filteredBarCrawls.first {
                                    FeaturedEventCard(
                                        title: featuredBarCrawl.name,
                                        description: featuredBarCrawl.barCrawlDescription ?? "Join this exciting bar crawl!",
                                        date: featuredBarCrawl.startTime?.formatted(.dateTime.month().day().hour().minute()) ?? "Coming soon",
                                        location: "Multiple venues",
                                        type: "Bar Crawl",
                                        action: { navigationManager.navigateToBarCrawl(featuredBarCrawl) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Scavenger Hunts
                if selectedCategory != .barCrawls && !filteredHunts.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Scavenger Hunts")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(filteredHunts) { hunt in
                                    EventCard(
                                        title: hunt.name,
                                        description: hunt.huntDescription ?? "A fun scavenger hunt",
                                        date: hunt.startTime?.formatted(.dateTime.month().day()) ?? "Coming soon",
                                        icon: "map.fill",
                                        color: .blue,
                                        action: { navigationManager.navigateToHunt(hunt) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if selectedCategory == .scavengerHunts && filteredHunts.isEmpty {
                    EmptyStateView(
                        title: "No Scavenger Hunts",
                        message: searchText.isEmpty ? 
                            "There are no scavenger hunts available right now." : 
                            "No hunts match your search criteria.",
                        icon: "map"
                    )
                }
                
                // Bar Crawls
                if selectedCategory != .scavengerHunts && !filteredBarCrawls.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Bar Crawls")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(filteredBarCrawls) { barCrawl in
                                    EventCard(
                                        title: barCrawl.name,
                                        description: barCrawl.barCrawlDescription ?? "A fun bar crawl",
                                        date: barCrawl.startTime?.formatted(.dateTime.month().day()) ?? "Coming soon",
                                        icon: "wineglass.fill",
                                        color: .purple,
                                        action: { navigationManager.navigateToBarCrawl(barCrawl) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else if selectedCategory == .barCrawls && filteredBarCrawls.isEmpty {
                    EmptyStateView(
                        title: "No Bar Crawls",
                        message: searchText.isEmpty ? 
                            "There are no bar crawls available right now." : 
                            "No bar crawls match your search criteria.",
                        icon: "wineglass"
                    )
                }
                
                // Create your own section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Get Started")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        CreateButton(
                            title: "Create Hunt",
                            icon: "map.fill",
                            color: .blue,
                            action: { navigationManager.presentSheet(.createHunt) }
                        )
                        
                        CreateButton(
                            title: "Create Bar Crawl",
                            icon: "wineglass.fill",
                            color: .purple,
                            action: { navigationManager.presentSheet(.createBarCrawl) }
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("Explore")
        .refreshable {
            // Add logic to refresh data if necessary
            print("Refresh triggered")
        }
    }
}

// MARK: - Support Views

struct CategoryButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct FeaturedEventCard: View {
    var title: String
    var description: String
    var date: String
    var location: String
    var type: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                ZStack(alignment: .bottomLeading) {
                    // Placeholder for image - in a real app, you'd use an actual image
                    Rectangle()
                        .fill(type == "Scavenger Hunt" ? Color.blue.opacity(0.6) : Color.purple.opacity(0.6))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: type == "Scavenger Hunt" ? "map.fill" : "wineglass.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white.opacity(0.3))
                                .frame(width: 60)
                                .offset(x: 50)
                        )
                    
                    VStack(alignment: .leading) {
                        Text(type)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(type == "Scavenger Hunt" ? Color.blue : Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .padding([.bottom], 8)
                        
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(date)
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "location.fill")
                            Text(location)
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Label("Share", systemImage: "square.and.arrow.up")
                        Spacer()
                        Label("Favorite", systemImage: "heart")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding()
            }
            .frame(width: 320)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventCard: View {
    var title: String
    var description: String
    var date: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                ZStack(alignment: .topTrailing) {
                    // Header with icon
                    Rectangle()
                        .fill(color.opacity(0.6))
                        .frame(height: 120)
                        .overlay(
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "heart")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Text(title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(date)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding()
                        )
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .frame(height: 50, alignment: .top)
                
                HStack {
                    Button(action: {}) {
                        Label("Join", systemImage: "person.badge.plus")
                            .font(.caption)
                            .foregroundColor(color)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(color)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .frame(width: 220)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CreateButton: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .cornerRadius(8)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ExploreView()
    }
    .modelContainer(PreviewContainer.previewContainer)
} 