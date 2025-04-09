import SwiftUI
import SwiftData

struct ExploreView: View {
    @Query private var hunts: [Hunt]
    @Query private var barCrawls: [BarCrawl]
    @State private var searchText = ""
    @State private var selectedFilter: EventFilter = .all
    
    enum EventFilter {
        case all, hunts, barCrawls
    }
    
    var filteredEvents: [String: [Any]] {
        var result: [String: [Any]] = [:]
        
        let filteredHunts = hunts.filter { hunt in
            (searchText.isEmpty || hunt.title.localizedCaseInsensitiveContains(searchText)) &&
            (selectedFilter == .all || selectedFilter == .hunts)
        }
        
        let filteredBarCrawls = barCrawls.filter { barCrawl in
            (searchText.isEmpty || barCrawl.title.localizedCaseInsensitiveContains(searchText)) &&
            (selectedFilter == .all || selectedFilter == .barCrawls)
        }
        
        if !filteredHunts.isEmpty {
            result["Scavenger Hunts"] = filteredHunts
        }
        
        if !filteredBarCrawls.isEmpty {
            result["Bar Crawls"] = filteredBarCrawls
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Search and Filter
                        SearchAndFilterView(searchText: $searchText, selectedFilter: $selectedFilter)
                        
                        // Events Grid
                        ForEach(Array(filteredEvents.keys), id: \.self) { key in
                            VStack(alignment: .leading) {
                                Text(key)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        if key == "Scavenger Hunts", let hunts = filteredEvents[key] as? [Hunt] {
                                            ForEach(hunts) { hunt in
                                                NavigationLink(destination: HuntDetailView(hunt: hunt)) {
                                                    EventCard(title: hunt.title, description: hunt.description, imageName: "map")
                                                }
                                            }
                                        } else if key == "Bar Crawls", let barCrawls = filteredEvents[key] as? [BarCrawl] {
                                            ForEach(barCrawls) { barCrawl in
                                                NavigationLink(destination: BarCrawlDetailView(barCrawl: barCrawl)) {
                                                    EventCard(title: barCrawl.title, description: barCrawl.description, imageName: "wineglass")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        if filteredEvents.isEmpty {
                            VStack {
                                Text("No events found")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("Try changing your search or create a new event")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 50)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Explore")
            .navigationBarItems(trailing: Button(action: {
                // Refresh action
            }) {
                Image(systemName: "arrow.clockwise")
            })
        }
    }
}

struct SearchAndFilterView: View {
    @Binding var searchText: String
    @Binding var selectedFilter: ExploreView.EventFilter
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search events...", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(ExploreView.EventFilter.all)
                Text("Hunts").tag(ExploreView.EventFilter.hunts)
                Text("Bar Crawls").tag(ExploreView.EventFilter.barCrawls)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
    }
}

struct EventCard: View {
    var title: String
    var description: String
    var imageName: String
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .bottomLeading) {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 280, height: 180)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 80)
                .cornerRadius(12)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(12)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(width: 280, alignment: .leading)
                .padding(.horizontal, 4)
            
            HStack {
                Image(systemName: "person.2")
                Text("Join")
                Spacer()
                Image(systemName: "heart")
                Text("Favorite")
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
        .frame(width: 280)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ExploreView()
        .modelContainer(for: [Hunt.self, BarCrawl.self], inMemory: true)
} 