import SwiftUI
import SwiftData
import MapKit

// MARK: - Ship Visualization View
struct ShipVisualizationView: View {
    let barStops: [BarStop]
    
    // State for the selected deck
    @State private var selectedDeck: Int = 1
    
    var body: some View {
        VStack {
            // Simple deck selector
            Picker("Select Deck", selection: $selectedDeck) {
                ForEach(availableDecks, id: \.self) { deck in
                    Text("Deck \(deck)").tag(deck)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Deck visualization
            ZStack {
                // Ship outline
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                // Ship sections
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .overlay(
                            Text("Forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(-90))
                                .padding(.leading, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                        .frame(width: 30)
                    
                    Divider()
                    
                    // Main deck area
                    ZStack {
                        // Display stops for the selected deck
                        ForEach(stopsForSelectedDeck, id: \.id) { stop in
                            BarStopMarker(stop: stop)
                                .position(positionForStop(stop))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    Rectangle()
                        .fill(Color.clear)
                        .overlay(
                            Text("Aft")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(90))
                                .padding(.trailing, 4)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        )
                        .frame(width: 30)
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity)
            
            // Legend
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                
                Text("Bar Stops")
                    .font(.caption)
                
                Spacer()
                
                if let firstStop = barStops.first(where: { $0.order == 1 }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    
                    Text("Start (\(firstStop.name))")
                        .font(.caption)
                }
                
                Spacer()
                
                if let lastStop = barStops.max(by: { $0.order < $1.order }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text("End (\(lastStop.name))")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    // Get all available decks from bar stops
    private var availableDecks: [Int] {
        let decks = Set(barStops.compactMap { $0.deckNumber })
        return Array(decks).sorted()
    }
    
    // Filter stops for the selected deck
    private var stopsForSelectedDeck: [BarStop] {
        barStops.filter { $0.deckNumber == selectedDeck }
    }
    
    // Position the stop marker on the deck visualization
    private func positionForStop(_ stop: BarStop) -> CGPoint {
        // Default to center if section is not specified
        let xPct: CGFloat = 0.5
        let yPct: CGFloat = CGFloat(stop.order) / CGFloat(barStops.count + 1)
        
        // Adjust x based on section if available
        if let section = stop.section {
            if section == "Forward" {
                return CGPoint(x: 0.25, y: yPct)
            } else if section == "Midship" {
                return CGPoint(x: 0.5, y: yPct)
            } else if section == "Aft" {
                return CGPoint(x: 0.75, y: yPct)
            }
        }
        
        return CGPoint(x: xPct, y: yPct)
    }
}

// MARK: - Bar Stop Marker
struct BarStopMarker: View {
    let stop: BarStop
    
    var body: some View {
        ZStack {
            Circle()
                .fill(markerColor)
                .frame(width: 30, height: 30)
                .shadow(radius: 2)
            
            Text("\(stop.order)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .overlay(
            Text(stop.name)
                .font(.caption)
                .padding(4)
                .background(Color.white.opacity(0.9))
                .cornerRadius(4)
                .shadow(radius: 1)
                .offset(y: 25)
        )
    }
    
    private var markerColor: Color {
        if stop.order == 1 {
            return .green
        } else if stop.order == stop.barCrawl?.barStops?.count {
            return .red
        } else {
            return .blue
        }
    }
}

struct BarCrawlDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationManager: NavigationManager
    
    let barCrawl: BarCrawl
    
    @State private var showAddBarStopSheet = false
    @State private var showConfirmDeleteAlert = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedView = "List"
    
    private var barStops: [BarStop] {
        barCrawl.barStops?.sorted(by: { $0.order < $1.order }) ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                barCrawlHeaderView
                
                // Picker for list vs map view
                Picker("View", selection: $selectedView) {
                    Text("List").tag("List")
                    Text("Map").tag("Map")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected view
                if selectedView == "List" {
                    barStopsListView
                } else {
                    barStopsMapView
                }
                
                // Actions
                actionButtonsView
            }
        }
        .navigationTitle(barCrawl.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddBarStopSheet = true
                    } label: {
                        Label("Add Bar Stop", systemImage: "plus.circle")
                    }
                    
                    Button {
                        // Share bar crawl
                        let shareText = "Check out this bar crawl: \(barCrawl.name) with \(barStops.count) stops!"
                        let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showConfirmDeleteAlert = true
                    } label: {
                        Label("Delete Bar Crawl", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Bar Crawl?", isPresented: $showConfirmDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete bar crawl and navigate back
                modelContext.delete(barCrawl)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this bar crawl? This action cannot be undone.")
        }
        .sheet(isPresented: $showAddBarStopSheet) {
            addBarStopView
        }
        .onAppear {
            updateMapRegion()
        }
    }
    
    // MARK: - Header View
    
    private var barCrawlHeaderView: some View {
        VStack(spacing: 0) {
            // Bar crawl image or gradient
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.7), .purple.opacity(0.4)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "wineglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70)
                            .foregroundColor(.white.opacity(0.2))
                    )
                
                // Overlay with bar crawl info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(barCrawl.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if let difficulty = barCrawl.difficulty {
                            Text(difficulty)
                                .font(.caption)
                                .padding(6)
                                .background(
                                    difficultyColor(for: difficulty).opacity(0.3)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    HStack {
                        statsRow(
                            icon: "wineglass",
                            value: "\(barStops.count)",
                            label: "Bar Stops"
                        )
                        
                        Divider()
                            .frame(height: 20)
                            .background(Color.white.opacity(0.3))
                        
                        statsRow(
                            icon: "clock",
                            value: barCrawl.estimatedDuration ?? "Unknown",
                            label: "Duration"
                        )
                        
                        if let creator = barCrawl.creator {
                            Divider()
                                .frame(height: 20)
                                .background(Color.white.opacity(0.3))
                            
                            statsRow(
                                icon: "person",
                                value: creator.displayName,
                                label: "Created by"
                            )
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.4))
            }
            
            // Description section if available
            if let description = barCrawl.barCrawlDescription, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - List View
    
    private var barStopsListView: some View {
        VStack(spacing: 0) {
            if barStops.isEmpty {
                emptyStateView
            } else {
                ForEach(barStops, id: \.id) { barStop in
                    barStopRow(barStop)
                    
                    if barStops.last?.id != barStop.id {
                        Divider()
                            .padding(.leading, 65)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    private func barStopRow(_ barStop: BarStop) -> some View {
        NavigationLink {
            // Create a placeholder view to display bar stop details in a more compatible way
            BarStopDetailView(barStop: barStop)
        } label: {
            HStack(spacing: 15) {
                // Bar stop number
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text("\(barStop.order)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(barStop.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let specialDrink = barStop.specialDrink {
                        Text(specialDrink)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let description = barStop.barStopDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if barStop.drinkPrice > 0 {
                    Text("$\(String(format: "%.2f", barStop.drinkPrice))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .contextMenu {
            Button {
                // Move up in order
                moveBarStop(barStop, direction: .up)
            } label: {
                Label("Move Up", systemImage: "arrow.up")
            }
            .disabled(barStop.order <= 1)
            
            Button {
                // Move down in order
                moveBarStop(barStop, direction: .down)
            } label: {
                Label("Move Down", systemImage: "arrow.down")
            }
            .disabled(barStop.order >= barStops.count)
            
            Button(role: .destructive) {
                // Remove from bar crawl
                removeBarStop(barStop)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Map View
    
    private var barStopsMapView: some View {
        VStack {
            if barStops.isEmpty {
                emptyStateView
            } else {
                // Map view with annotations
                mapWithMarkers
                
                // List of stops under the map
                stopsList
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var mapWithMarkers: some View {
        VStack {
            Text("Bar Crawl Route")
                .font(.headline)
                .padding(.top)
            
            // Ship visualization with bar stops
            ShipVisualizationView(barStops: barStops)
                .frame(height: 300)
                .padding()
        }
    }
    
    private var stopsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stops")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(barStops, id: \.id) { stop in
                HStack {
                    Text("\(stop.order)")
                        .font(.callout)
                        .fontWeight(.bold)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.blue))
                        .foregroundColor(.white)
                    
                    Text(stop.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let desc = stop.barStopDescription {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wineglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Bar Stops Added Yet")
                .font(.headline)
            
            Text("Tap the + button to add bars to this crawl")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddBarStopSheet = true
            } label: {
                Text("Add Bar Stop")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            if !barStops.isEmpty {
                Button {
                    // Start bar crawl (in future could track progress, etc.)
                    // For now just display an alert
                } label: {
                    Text("Start Bar Crawl")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Add Bar Stop Sheet
    
    private var addBarStopView: some View {
        NavigationStack {
            // Sample list of bars to add
            List {
                Section(header: Text("Available Bars")) {
                    ForEach(mockAvailableBars(), id: \.name) { bar in
                        Button {
                            // Add this bar to the bar crawl
                            addBarToCrawl(bar)
                            showAddBarStopSheet = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bar.name)
                                        .foregroundColor(.primary)
                                    
                                    Text(bar.type)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(bar.location)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Bar Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        showAddBarStopSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func statsRow(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy":
            return .green
        case "moderate":
            return .orange
        case "challenging":
            return .red
        default:
            return .blue
        }
    }
    
    private func updateMapRegion() {
        // For ship-based navigation, we don't need to update a map region
        // We're using our own visualization based on deck numbers
        
        // Set a default region just in case it's needed somewhere
        mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
    
    enum MoveDirection {
        case up, down
    }
    
    private func moveBarStop(_ barStop: BarStop, direction: MoveDirection) {
        let currentOrder = barStop.order
        
        if direction == .up && currentOrder > 1 {
            // Find the bar stop above this one
            if let aboveStop = barStops.first(where: { $0.order == currentOrder - 1 }) {
                // Swap orders
                aboveStop.order = currentOrder
                barStop.order = currentOrder - 1
            }
        } else if direction == .down && currentOrder < barStops.count {
            // Find the bar stop below this one
            if let belowStop = barStops.first(where: { $0.order == currentOrder + 1 }) {
                // Swap orders
                belowStop.order = currentOrder
                barStop.order = currentOrder + 1
            }
        }
    }
    
    private func removeBarStop(_ barStop: BarStop) {
        if let index = barStops.firstIndex(where: { $0.id == barStop.id }) {
            modelContext.delete(barStop)
            
            // Reorder remaining stops
            for (offset, stop) in barStops.enumerated() where offset >= index && stop.id != barStop.id {
                stop.order -= 1
            }
        }
    }
    
    private func addBarToCrawl(_ bar: (name: String, type: String, location: String, deckNumber: Int, section: String)) {
        let nextOrder = (barStops.map { $0.order }.max() ?? 0) + 1
        
        let barStop = BarStop(
            name: bar.name,
            specialDrink: "House Special",
            drinkPrice: Double.random(in: 8...15),
            barStopDescription: "\(bar.type) bar on \(bar.location)",
            checkInRadius: 50.0,
            deckNumber: bar.deckNumber,
            locationOnShip: bar.location,
            section: bar.section,
            openingTime: Date().addingTimeInterval(-3600), // 1 hour ago
            closingTime: Date().addingTimeInterval(3600 * 5), // 5 hours from now
            order: nextOrder,
            isVIP: false
        )
        
        barStop.barCrawl = barCrawl
        modelContext.insert(barStop)
    }
    
    // MARK: - Mock Data
    
    private func mockAvailableBars() -> [(name: String, type: String, location: String, deckNumber: Int, section: String)] {
        return [
            (name: "Schooner Bar", type: "Piano Bar", location: "Deck 5, Midship", deckNumber: 5, section: "Midship"),
            (name: "Bionic Bar", type: "Robot Bar", location: "Deck 5, Forward", deckNumber: 5, section: "Forward"),
            (name: "Pool Bar", type: "Casual", location: "Deck 15, Aft", deckNumber: 15, section: "Aft"),
            (name: "Viking Crown Lounge", type: "Classy", location: "Deck 14, Forward", deckNumber: 14, section: "Forward"),
            (name: "English Pub", type: "Traditional", location: "Deck 4, Midship", deckNumber: 4, section: "Midship")
        ]
    }
    
    // MARK: - Preview Helpers

    private func exampleBarCrawl() -> BarCrawl {
        let barCrawl = BarCrawl(
            id: "example-bar-crawl",
            name: "Miami Party Crawl",
            barCrawlDescription: "Experience the best bars in Miami",
            theme: "Tropical",
            difficulty: "Moderate",
            estimatedDuration: "4-5 hours"
        )
        
        let stop1 = BarStop(
            name: "Sunshine Bar",
            specialDrink: "Miami Sunrise",
            drinkPrice: 12.99,
            barStopDescription: "Beach-front tiki bar with amazing views",
            checkInRadius: 50.0,
            deckNumber: 15,
            locationOnShip: "Pool Deck",
            section: "Aft",
            openingTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
            closingTime: Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!,
            order: 1,
            isVIP: false
        )
        
        let stop2 = BarStop(
            name: "Sky Lounge",
            specialDrink: "Blue Horizon",
            drinkPrice: 15.99,
            barStopDescription: "Elegant rooftop bar with panoramic views",
            checkInRadius: 50.0,
            deckNumber: 16,
            locationOnShip: "Observation Deck",
            section: "Forward",
            openingTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!,
            closingTime: Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date())!,
            order: 2,
            isVIP: true
        )
        
        let stop3 = BarStop(
            name: "Jazz Club",
            specialDrink: "Smooth Saxophone",
            drinkPrice: 14.99,
            barStopDescription: "Live music venue with craft cocktails",
            checkInRadius: 50.0,
            deckNumber: 4,
            locationOnShip: "Entertainment Deck",
            section: "Midship",
            openingTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!,
            closingTime: Calendar.current.date(bySettingHour: 3, minute: 0, second: 0, of: Date())!,
            order: 3,
            isVIP: false
        )
        
        // These would normally be done with proper relationships
        stop1.barCrawl = barCrawl
        stop2.barCrawl = barCrawl
        stop3.barCrawl = barCrawl
        
        return barCrawl
    }
}

#Preview {
    NavigationStack {
        BarCrawlDetailView(barCrawl: previewBarCrawl())
    }
    .modelContainer(for: [
        BarCrawl.self,
        User.self,
        BarStop.self,
        CruiseBar.self
    ], inMemory: true)
    .environmentObject(NavigationManager())
}

func previewBarCrawl() -> BarCrawl {
    let barCrawl = BarCrawl(
        name: "Evening Cocktail Tour",
        barCrawlDescription: "Tour the best cocktail bars on the ship, from casual to premium lounges",
        theme: "Cocktails",
        difficulty: "Moderate",
        estimatedDuration: "3-4 hours"
    )
    
    let creator = User(
        name: "cruiselover",
        email: "cruise@example.com",
        displayName: "Cruise Lover"
    )
    barCrawl.creator = creator
    
    // Create some bar stops
    var barStops: [BarStop] = []
    
    // Stop 1
    let bar1 = CruiseBar(
        name: "The Alchemy Bar",
        barDescription: "Cocktail bar with signature mixology",
        barType: "Cocktail Bar",
        signatureDrinks: "Cucumber Sunrise, Blueberry Mojito",
        atmosphere: "Upscale",
        dressCode: "Smart Casual",
        hours: "4:00 PM - 1:00 AM",
        costCategory: "Premium Package"
    )
    
    let stop1 = BarStop(
        name: "The Alchemy Bar",
        specialDrink: "Cucumber Sunrise",
        drinkPrice: 12.99,
        barStopDescription: "Cocktail bar with signature mixology",
        checkInRadius: 50,
        deckNumber: 8,
        locationOnShip: "Plaza Deck",
        section: "Forward",
        openingTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!,
        closingTime: Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date())!,
        order: 1,
        isVIP: true
    )
    barStops.append(stop1)
    
    // Stop 2
    let bar2 = CruiseBar(
        name: "RedFrog Rum Bar",
        barDescription: "Tropical bar with rum specialties",
        barType: "Tropical Bar",
        signatureDrinks: "RedFrog Rum Punch, Bahama Mama",
        atmosphere: "Casual, Tropical",
        dressCode: "Resort Casual",
        hours: "10:00 AM - 12:00 AM",
        costCategory: "Included in Package"
    )
    
    let stop2 = BarStop(
        name: "RedFrog Rum Bar",
        specialDrink: "RedFrog Rum Punch",
        drinkPrice: 9.99,
        barStopDescription: "Tropical bar with rum specialties",
        checkInRadius: 50,
        deckNumber: 10,
        locationOnShip: "Lido Deck",
        section: "Midship",
        openingTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!,
        closingTime: Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!,
        order: 2,
        isVIP: false
    )
    barStops.append(stop2)
    
    // Stop 3
    let bar3 = CruiseBar(
        name: "Piano Bar",
        barDescription: "Entertainment bar with live piano music",
        barType: "Entertainment Bar",
        signatureDrinks: "Classic Martini, Manhattan",
        atmosphere: "Lively, Musical",
        dressCode: "Smart Casual",
        hours: "8:00 PM - 2:00 AM",
        costCategory: "Included in Package"
    )
    
    let stop3 = BarStop(
        name: "Piano Bar",
        specialDrink: "Classic Martini",
        drinkPrice: 11.50,
        barStopDescription: "Entertainment bar with live piano music",
        checkInRadius: 50,
        deckNumber: 5,
        locationOnShip: "Promenade Deck",
        section: "Aft",
        openingTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!,
        closingTime: Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date())!,
        order: 3,
        isVIP: false
    )
    barStops.append(stop3)
    
    barCrawl.barStops = barStops
    
    return barCrawl
} 