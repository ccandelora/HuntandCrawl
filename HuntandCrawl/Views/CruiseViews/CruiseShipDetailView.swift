import SwiftUI
import SwiftData

struct CruiseShipDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationManager: NavigationManager
    
    let ship: CruiseShip
    
    @State private var selectedSection: ShipDetailSection = .overview
    @State private var showBarFilters = false
    @State private var barTypeFilter = ""
    @State private var barAtmosphereFilter = ""
    @State private var barCostFilter = ""
    
    // Filtered bar stops
    var filteredBarStops: [CruiseBarStop] {
        guard let barStops = ship.barStops else { return [] }
        
        return barStops.filter { barStop in
            guard let bar = barStop.bar else { return false }
            
            let matchesType = barTypeFilter.isEmpty || bar.barType.localizedCaseInsensitiveContains(barTypeFilter)
            let matchesAtmosphere = barAtmosphereFilter.isEmpty || bar.atmosphere.localizedCaseInsensitiveContains(barAtmosphereFilter)
            let matchesCost = barCostFilter.isEmpty || bar.costCategory.localizedCaseInsensitiveContains(barCostFilter)
            
            return matchesType && matchesAtmosphere && matchesCost
        }
    }
    
    var availableBarTypes: [String] {
        let types = Set(ship.barStops?.compactMap { $0.bar?.barType } ?? [])
        return Array(types).sorted()
    }
    
    var availableAtmospheres: [String] {
        let atmospheres = Set(ship.barStops?.compactMap { $0.bar?.atmosphere } ?? [])
        return Array(atmospheres).sorted()
    }
    
    var availableCostCategories: [String] {
        let costs = Set(ship.barStops?.compactMap { $0.bar?.costCategory } ?? [])
        return Array(costs).sorted()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Ship header
                shipHeaderView
                
                // Section picker
                sectionPickerView
                
                // Content based on selected section
                switch selectedSection {
                case .overview:
                    shipOverviewView
                case .bars:
                    shipBarsView
                case .barCrawls:
                    shipBarCrawlsView
                }
            }
        }
        .navigationTitle(ship.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if selectedSection == .bars {
                    Button {
                        showBarFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showBarFilters) {
            barFiltersView
        }
    }
    
    // MARK: - Ship Header
    
    private var shipHeaderView: some View {
        VStack(spacing: 12) {
            // Ship image placeholder
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "ferry.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.white.opacity(0.3))
                    )
                
                // Ship info overlay
                VStack(alignment: .leading, spacing: 6) {
                    Text(ship.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(ship.shipClass) Class")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    if let cruiseLine = ship.cruiseLine {
                        HStack {
                            Text(cruiseLine.name)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Link(destination: URL(string: cruiseLine.website) ?? URL(string: "https://www.example.com")!) {
                                Label("Website", systemImage: "globe")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.4))
            }
            
            // Ship stats
            HStack(spacing: 20) {
                VStack {
                    Text("\(ship.yearBuilt)")
                        .font(.headline)
                    Text("Built")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 24)
                
                VStack {
                    Text("\(ship.passengerCapacity)")
                        .font(.headline)
                    Text("Passengers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 24)
                
                VStack {
                    Text("\(ship.numberOfBars)")
                        .font(.headline)
                    Text("Bars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let barCrawlRoutes = ship.barCrawlRoutes, !barCrawlRoutes.isEmpty {
                    Divider()
                        .frame(height: 24)
                    
                    VStack {
                        Text("\(barCrawlRoutes.count)")
                            .font(.headline)
                        Text("Bar Crawls")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Section Picker
    
    private var sectionPickerView: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(ShipDetailSection.allCases, id: \.self) { section in
                Text(section.title)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    // MARK: - Overview Section
    
    private var shipOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Basic ship information
            infoCard(title: "About This Ship") {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(icon: "calendar", title: "Year Built", value: "\(ship.yearBuilt)")
                    infoRow(icon: "person.2.fill", title: "Passenger Capacity", value: "\(ship.passengerCapacity)")
                    infoRow(icon: "wineglass", title: "Number of Bars", value: "\(ship.numberOfBars)")
                    infoRow(icon: "star", title: "Ship Class", value: ship.shipClass)
                    
                    if let cruiseLine = ship.cruiseLine {
                        infoRow(icon: "ferry", title: "Cruise Line", value: cruiseLine.name)
                    }
                }
            }
            
            // Bar statistics
            if let barStops = ship.barStops, !barStops.isEmpty {
                infoCard(title: "Bar Quick Facts") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Count bar types
                        let barTypes = Dictionary(grouping: barStops, by: { $0.bar?.barType ?? "Unknown" })
                            .mapValues { $0.count }
                            .sorted { $0.value > $1.value }
                        
                        if !barTypes.isEmpty {
                            Text("Bar Types:")
                                .font(.headline)
                            
                            ForEach(barTypes.prefix(3), id: \.key) { type, count in
                                infoRow(icon: "wineglass", title: type, value: "\(count)")
                            }
                        }
                        
                        Divider()
                        
                        // Count atmospheres
                        let atmospheres = Dictionary(grouping: barStops, by: { $0.bar?.atmosphere ?? "Unknown" })
                            .mapValues { $0.count }
                            .sorted { $0.value > $1.value }
                        
                        if !atmospheres.isEmpty {
                            Text("Popular Atmospheres:")
                                .font(.headline)
                            
                            ForEach(atmospheres.prefix(3), id: \.key) { atmosphere, count in
                                infoRow(icon: "sparkles", title: atmosphere, value: "\(count)")
                            }
                        }
                    }
                }
            }
            
            // Bar crawl statistics
            if let barCrawlRoutes = ship.barCrawlRoutes, !barCrawlRoutes.isEmpty {
                infoCard(title: "Bar Crawl Options") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Difficulty levels
                        let difficulties = Dictionary(grouping: barCrawlRoutes, by: { $0.difficultyLevel })
                            .mapValues { $0.count }
                            .sorted { $0.value > $1.value }
                        
                        Text("Difficulty Levels:")
                            .font(.headline)
                        
                        ForEach(difficulties, id: \.key) { difficulty, count in
                            infoRow(
                                icon: difficulty.lowercased() == "easy" ? "figure.walk" :
                                      difficulty.lowercased() == "moderate" ? "figure.hiking" : "figure.climbing",
                                title: difficulty,
                                value: "\(count)"
                            )
                        }
                        
                        Divider()
                        
                        // Duration ranges
                        Text("Duration Ranges:")
                            .font(.headline)
                        
                        ForEach(barCrawlRoutes.prefix(3)) { route in
                            infoRow(icon: "clock", title: route.name, value: route.estimatedDuration)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Bars Section
    
    private var shipBarsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if barTypeFilter.isEmpty && barAtmosphereFilter.isEmpty && barCostFilter.isEmpty {
                // No filters applied
                Text("All \(filteredBarStops.count) bars on \(ship.name)")
                    .font(.headline)
                    .padding(.horizontal)
            } else {
                // Filters applied
                HStack {
                    Text("Filtered: \(filteredBarStops.count) bars")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Clear Filters") {
                        barTypeFilter = ""
                        barAtmosphereFilter = ""
                        barCostFilter = ""
                    }
                }
                .padding(.horizontal)
                
                // Show active filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if !barTypeFilter.isEmpty {
                            filterChip(label: "Type: \(barTypeFilter)") {
                                barTypeFilter = ""
                            }
                        }
                        
                        if !barAtmosphereFilter.isEmpty {
                            filterChip(label: "Atmosphere: \(barAtmosphereFilter)") {
                                barAtmosphereFilter = ""
                            }
                        }
                        
                        if !barCostFilter.isEmpty {
                            filterChip(label: "Cost: \(barCostFilter)") {
                                barCostFilter = ""
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Bar list
            ForEach(filteredBarStops) { barStop in
                NavigationLink(destination: CruiseBarDetailView(barStop: barStop)) {
                    barCard(barStop)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical)
    }
    
    private func barCard(_ barStop: CruiseBarStop) -> some View {
        guard let bar = barStop.bar else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    // Bar icon/image placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorForBarType(bar.barType))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: iconForBarType(bar.barType))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bar.name)
                            .font(.headline)
                        
                        Text(bar.barType)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(barStop.locationOnShip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Cost indicator
                    Text(bar.costCategory)
                        .font(.caption2)
                        .padding(6)
                        .background(
                            bar.costCategory.contains("Premium") ?
                                Color.purple.opacity(0.2) :
                                (bar.costCategory.contains("Included") ?
                                    Color.green.opacity(0.2) :
                                    Color.orange.opacity(0.2))
                        )
                        .foregroundColor(
                            bar.costCategory.contains("Premium") ?
                                Color.purple :
                                (bar.costCategory.contains("Included") ?
                                    Color.green :
                                    Color.orange)
                        )
                        .cornerRadius(4)
                }
                
                // Bar description
                Text(bar.barDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Signature drinks
                if !bar.signatureDrinks.isEmpty {
                    Text("Signature Drinks: \(bar.signatureDrinks)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Special notes if available
                if !barStop.specialNotes.isEmpty {
                    Text("Note: \(barStop.specialNotes)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                }
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(bar.atmosphere.components(separatedBy: ", "), id: \.self) { atmosphere in
                            Text(atmosphere)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Text(bar.hours)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text(bar.dressCode)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
        )
    }
    
    // MARK: - Bar Crawl Routes Section
    
    private var shipBarCrawlsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let barCrawlRoutes = ship.barCrawlRoutes, !barCrawlRoutes.isEmpty {
                Text("\(barCrawlRoutes.count) Bar Crawl Routes on \(ship.name)")
                    .font(.headline)
                    .padding(.horizontal)
                
                // Routes list
                ForEach(barCrawlRoutes.sorted(by: { $0.name < $1.name })) { route in
                    NavigationLink(destination: CruiseBarCrawlRouteView(route: route)) {
                        barCrawlCard(route)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                Text("No bar crawl routes found for this ship")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(.vertical)
    }
    
    private func barCrawlCard(_ route: CruiseBarCrawlRoute) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(alignment: .top) {
                // Icon based on difficulty
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForDifficulty(route.difficultyLevel))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconForDifficulty(route.difficultyLevel))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                    
                    Text("\(route.numberOfStops) stops • \(route.estimatedDuration)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Difficulty indicator
                Text(route.difficultyLevel)
                    .font(.caption2)
                    .padding(6)
                    .background(colorForDifficulty(route.difficultyLevel).opacity(0.2))
                    .foregroundColor(colorForDifficulty(route.difficultyLevel))
                    .cornerRadius(4)
            }
            
            // Route description
            Text(route.routeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Bar stops preview
            if let stops = route.stops?.sorted(by: { $0.stopOrder < $1.stopOrder }), !stops.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stops include:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(stops.prefix(3)) { stop in
                            if let barStop = stop.barStop, let bar = barStop.bar {
                                Text(bar.name)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(colorForBarType(bar.barType).opacity(0.1))
                                    .foregroundColor(colorForBarType(bar.barType))
                                    .cornerRadius(4)
                            }
                        }
                        
                        if stops.count > 3 {
                            Text("+\(stops.count - 3) more")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.gray)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Bar Filters
    
    private var barFiltersView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bar Type")) {
                    Picker("Select Bar Type", selection: $barTypeFilter) {
                        Text("All Types").tag("")
                        ForEach(availableBarTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Atmosphere")) {
                    Picker("Select Atmosphere", selection: $barAtmosphereFilter) {
                        Text("All Atmospheres").tag("")
                        ForEach(availableAtmospheres, id: \.self) { atmosphere in
                            Text(atmosphere).tag(atmosphere)
                        }
                    }
                }
                
                Section(header: Text("Cost Category")) {
                    Picker("Select Cost Category", selection: $barCostFilter) {
                        Text("All Cost Categories").tag("")
                        ForEach(availableCostCategories, id: \.self) { cost in
                            Text(cost).tag(cost)
                        }
                    }
                }
            }
            .navigationTitle("Filter Bars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showBarFilters = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Helper Views
    
    private func infoCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.secondary)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    private func filterChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    
    private func iconForBarType(_ type: String) -> String {
        if type.lowercased().contains("cocktail") {
            return "wineglass"
        } else if type.lowercased().contains("beer") {
            return "mug"
        } else if type.lowercased().contains("pool") {
            return "waterbottle"
        } else if type.lowercased().contains("irish") {
            return "music.note"
        } else if type.lowercased().contains("whiskey") {
            return "wineglass.fill"
        } else if type.lowercased().contains("tropical") {
            return "leaf"
        } else if type.lowercased().contains("piano") {
            return "pianokeys"
        } else if type.lowercased().contains("ice") {
            return "snowflake"
        } else {
            return "wineglass"
        }
    }
    
    private func colorForBarType(_ type: String) -> Color {
        if type.lowercased().contains("cocktail") {
            return .purple
        } else if type.lowercased().contains("beer") {
            return .orange
        } else if type.lowercased().contains("pool") {
            return .blue
        } else if type.lowercased().contains("irish") {
            return .green
        } else if type.lowercased().contains("whiskey") {
            return .brown
        } else if type.lowercased().contains("tropical") {
            return .green
        } else if type.lowercased().contains("piano") {
            return .black
        } else if type.lowercased().contains("ice") {
            return .blue
        } else {
            return .indigo
        }
    }
    
    private func iconForDifficulty(_ difficulty: String) -> String {
        if difficulty.lowercased() == "easy" {
            return "figure.walk"
        } else if difficulty.lowercased() == "moderate" {
            return "figure.hiking"
        } else {
            return "figure.climbing"
        }
    }
    
    private func colorForDifficulty(_ difficulty: String) -> Color {
        if difficulty.lowercased() == "easy" {
            return .green
        } else if difficulty.lowercased() == "moderate" {
            return .orange
        } else {
            return .red
        }
    }
}

enum ShipDetailSection: String, CaseIterable {
    case overview, bars, barCrawls
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .bars: return "Bars"
        case .barCrawls: return "Bar Crawls"
        }
    }
}

#Preview {
    NavigationStack {
        CruiseShipDetailView(ship: previewCruiseShip())
    }
    .modelContainer(for: [
        CruiseLine.self,
        CruiseShip.self,
        CruiseBar.self,
        CruiseBarStop.self,
        CruiseBarDrink.self,
        CruiseBarCrawlRoute.self,
        CruiseBarCrawlStop.self
    ], inMemory: true)
    .environmentObject(NavigationManager())
}

func previewCruiseShip() -> CruiseShip {
    let ship = CruiseShip(
        name: "Carnival Celebration",
        shipClass: "Excel",
        yearBuilt: 2022,
        passengerCapacity: 5374,
        numberOfBars: 15,
        tonnage: 183521
    )
    return ship
}

// MARK: - CruiseBarCrawlRoute Detail View
struct CruiseBarCrawlRouteView: View {
    let route: CruiseBarCrawlRoute
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text(route.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(route.routeDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Divider()
                
                // Route info
                HStack(spacing: 20) {
                    VStack {
                        Text("Difficulty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(route.difficultyLevel)
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(route.estimatedDuration)
                            .font(.headline)
                    }
                    
                    VStack {
                        Text("Stops")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(route.numberOfStops)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Bar stops list
                Text("Bar Stops")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                if let stops = route.stops?.sorted(by: { $0.stopOrder < $1.stopOrder }), !stops.isEmpty {
                    ForEach(stops) { stop in
                        barStopCard(stop)
                    }
                } else {
                    Text("No stops available")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Bar Crawl Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func barStopCard(_ stop: CruiseBarCrawlStop) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(stop.stopOrder)")
                    .fontWeight(.bold)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.blue))
                    .foregroundColor(.white)
                
                if let barStop = stop.barStop, let bar = barStop.bar {
                    VStack(alignment: .leading) {
                        Text(bar.name)
                            .font(.headline)
                        
                        Text(bar.barType)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Unknown Bar")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let barStop = stop.barStop {
                    Text(barStop.locationOnShip)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !stop.recommendedDrink.isEmpty {
                Text("Recommended: \(stop.recommendedDrink)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 40)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
} 