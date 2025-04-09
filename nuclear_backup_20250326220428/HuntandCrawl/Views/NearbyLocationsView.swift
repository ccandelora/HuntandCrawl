import SwiftUI
import MapKit

struct NearbyLocationsView: View {
    @EnvironmentObject private var geofencingManager: GeofencingManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLocation: GeofenceData?
    @State private var showNavigation = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showTaskDetail = false
    @State private var showBarStopDetail = false
    @State private var selectedFilter: LocationFilter = .all
    @State private var searchText = ""
    @State private var isSearching = false
    
    // Map settings
    @State private var mapStyle: MapStyle = .standard
    @State private var showUserLocation = true
    
    // Distance settings
    private let maxDisplayDistance: CLLocationDistance = 1000 // meters
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map
                Map(position: $cameraPosition) {
                    // User location
                    if showUserLocation, let userLocation = locationManager.location {
                        UserAnnotation()
                    }
                    
                    // Task markers
                    ForEach(filteredTasks) { task in
                        Marker(task.name, coordinate: CLLocationCoordinate2D(latitude: task.latitude, longitude: task.longitude))
                            .tint(.blue)
                    }
                    
                    // Bar stop markers
                    ForEach(filteredBarStops) { barStop in
                        Marker(barStop.name, coordinate: CLLocationCoordinate2D(latitude: barStop.latitude, longitude: barStop.longitude))
                            .tint(.purple)
                    }
                }
                .mapStyle(mapStyle)
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                    MapPitchToggle()
                }
                .onAppear {
                    centerOnUserLocation()
                }
                .onChange(of: locationManager.location) { oldValue, newValue in
                    if showUserLocation {
                        centerOnUserLocation()
                    }
                }
                .overlay(alignment: .top) {
                    // Search and filter bar
                    VStack(spacing: 0) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search locations", text: $searchText)
                                .onTapGesture {
                                    isSearching = true
                                }
                            
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
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Filter buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                FilterButton(
                                    title: "All",
                                    filter: .all,
                                    selectedFilter: $selectedFilter
                                )
                                
                                FilterButton(
                                    title: "Tasks",
                                    filter: .tasks,
                                    selectedFilter: $selectedFilter
                                )
                                
                                FilterButton(
                                    title: "Bar Stops",
                                    filter: .barStops,
                                    selectedFilter: $selectedFilter
                                )
                                
                                Divider()
                                    .frame(height: 20)
                                
                                FilterButton(
                                    title: "Nearest",
                                    filter: .nearest,
                                    selectedFilter: $selectedFilter
                                )
                                
                                FilterButton(
                                    title: "Within 100m",
                                    filter: .within100m,
                                    selectedFilter: $selectedFilter
                                )
                                
                                FilterButton(
                                    title: "Within 500m",
                                    filter: .within500m,
                                    selectedFilter: $selectedFilter
                                )
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .background(Color(UIColor.systemBackground).opacity(0.9))
                    }
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                    .shadow(radius: 2)
                }
                
                // Bottom card with location list
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(listTitle)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(filteredLocations.count) found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15, corners: [.topLeft, .topRight])
                    
                    // Location list
                    List {
                        ForEach(filteredLocations) { location in
                            Button(action: {
                                selectedLocation = location
                                if location.type == .task {
                                    showTaskDetail = true
                                } else {
                                    showBarStopDetail = true
                                }
                            }) {
                                LocationRow(location: location, userLocation: locationManager.location)
                            }
                            .listRowBackground(Color(UIColor.secondarySystemBackground))
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 300)
                    .background(Color(UIColor.secondarySystemBackground))
                }
                .shadow(radius: 5, y: -5)
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Nearby Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { mapStyle = .standard }) {
                            Label("Standard Map", systemImage: "map")
                        }
                        
                        Button(action: { mapStyle = .hybrid }) {
                            Label("Satellite Map", systemImage: "network")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            selectedFilter = .all
                            centerOnAllLocations()
                        }) {
                            Label("Show All Locations", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                        }
                        
                        Toggle("Follow My Location", isOn: $showUserLocation)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showTaskDetail) {
                if let location = selectedLocation, location.type == .task {
                    TaskDetailSheet(
                        location: location, 
                        onNavigate: {
                            showTaskDetail = false
                            showNavigation = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showBarStopDetail) {
                if let location = selectedLocation, location.type == .barStop {
                    BarStopDetailSheet(
                        location: location,
                        onNavigate: {
                            showBarStopDetail = false
                            showNavigation = true
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showNavigation) {
                if let location = selectedLocation {
                    NavigationView(
                        destinationName: location.name,
                        destinationLatitude: location.latitude,
                        destinationLongitude: location.longitude,
                        type: location.type == .task ? .hunt : .barCrawl
                    )
                }
            }
        }
    }
    
    // Title for the location list
    private var listTitle: String {
        switch selectedFilter {
        case .all:
            return "All Nearby Locations"
        case .tasks:
            return "Nearby Tasks"
        case .barStops:
            return "Nearby Bar Stops"
        case .nearest:
            return "Nearest Locations"
        case .within100m:
            return "Locations Within 100m"
        case .within500m:
            return "Locations Within 500m"
        }
    }
    
    // Filtered tasks based on current filter
    private var filteredTasks: [GeofenceData] {
        var tasks = geofencingManager.nearbyTasks
        
        // Apply search filter
        if !searchText.isEmpty {
            tasks = tasks.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply distance filter
        if let userLocation = locationManager.location {
            switch selectedFilter {
            case .within100m:
                tasks = tasks.filter { locationDistance(to: $0) <= 100 }
            case .within500m:
                tasks = tasks.filter { locationDistance(to: $0) <= 500 }
            default:
                tasks = tasks.filter { locationDistance(to: $0) <= maxDisplayDistance }
            }
        }
        
        return tasks
    }
    
    // Filtered bar stops based on current filter
    private var filteredBarStops: [GeofenceData] {
        var barStops = geofencingManager.nearbyBarStops
        
        // Apply search filter
        if !searchText.isEmpty {
            barStops = barStops.filter { location in
                location.name.localizedCaseInsensitiveContains(searchText) ||
                location.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply distance filter
        if let userLocation = locationManager.location {
            switch selectedFilter {
            case .within100m:
                barStops = barStops.filter { locationDistance(to: $0) <= 100 }
            case .within500m:
                barStops = barStops.filter { locationDistance(to: $0) <= 500 }
            default:
                barStops = barStops.filter { locationDistance(to: $0) <= maxDisplayDistance }
            }
        }
        
        return barStops
    }
    
    // Combined filtered locations for the list
    private var filteredLocations: [GeofenceData] {
        var locations: [GeofenceData] = []
        
        // Apply type filter
        switch selectedFilter {
        case .all, .nearest, .within100m, .within500m:
            locations = filteredTasks + filteredBarStops
        case .tasks:
            locations = filteredTasks
        case .barStops:
            locations = filteredBarStops
        }
        
        // Sort by distance if needed
        if let userLocation = locationManager.location {
            if selectedFilter == .nearest {
                locations.sort { locationDistance(to: $0) < locationDistance(to: $1) }
            }
        }
        
        return locations
    }
    
    // Calculate distance from current location to a geofence point
    private func locationDistance(to geofenceData: GeofenceData) -> CLLocationDistance {
        guard let location = locationManager.location else { return .infinity }
        
        let pointLocation = CLLocation(
            latitude: geofenceData.latitude, 
            longitude: geofenceData.longitude
        )
        
        return location.distance(from: pointLocation)
    }
    
    // Center map on user location
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    // Center map to show all locations
    private func centerOnAllLocations() {
        let locations = filteredLocations
        
        guard !locations.isEmpty else {
            centerOnUserLocation()
            return
        }
        
        // Find the bounding box for all locations
        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude
        
        // Include user location in the bounding box
        if let userLocation = locationManager.location {
            minLat = min(minLat, userLocation.coordinate.latitude)
            maxLat = max(maxLat, userLocation.coordinate.latitude)
            minLon = min(minLon, userLocation.coordinate.longitude)
            maxLon = max(maxLon, userLocation.coordinate.longitude)
        }
        
        for location in locations {
            minLat = min(minLat, location.latitude)
            maxLat = max(maxLat, location.latitude)
            minLon = min(minLon, location.longitude)
            maxLon = max(maxLon, location.longitude)
        }
        
        // Add padding
        let latPadding = (maxLat - minLat) * 0.2
        let lonPadding = (maxLon - minLon) * 0.2
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(0.01, (maxLat - minLat) + latPadding),
                longitudeDelta: max(0.01, (maxLon - minLon) + lonPadding)
            )
        )
        
        cameraPosition = .region(region)
    }
}

// MARK: - Supporting Views

struct LocationRow: View {
    let location: GeofenceData
    let userLocation: CLLocation?
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(location.type == .task ? Color.blue.opacity(0.2) : Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: location.type == .task ? "checkmark.circle" : "wineglass")
                    .foregroundColor(location.type == .task ? .blue : .purple)
            }
            
            // Location details
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                
                Text(location.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Distance
            if let userLocation = userLocation {
                let distance = userLocation.distance(from: CLLocation(
                    latitude: location.latitude,
                    longitude: location.longitude
                ))
                
                Text(formatDistance(distance))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        
        if distance < 1000 {
            return formatter.string(fromMeters: distance)
        } else {
            return formatter.string(fromKilometers: distance / 1000)
        }
    }
}

struct FilterButton: View {
    let title: String
    let filter: LocationFilter
    @Binding var selectedFilter: LocationFilter
    
    var body: some View {
        Button(action: {
            selectedFilter = filter
        }) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedFilter == filter ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(selectedFilter == filter ? .white : .primary)
                .cornerRadius(20)
                .font(.caption)
        }
    }
}

struct TaskDetailSheet: View {
    let location: GeofenceData
    let onNavigate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Task")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(location.name)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(location.description)
                        .font(.body)
                }
                
                // Location info
                if let userLocation = locationManager.location {
                    let taskLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    let distance = userLocation.distance(from: taskLocation)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            
                            Text(formatDistance(distance) + " away")
                                .font(.body)
                        }
                        
                        // Proximity hint
                        Text(locationManager.getProximityHint(to: taskLocation))
                            .font(.body)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        onNavigate()
                    }) {
                        Text("Navigate")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        
        if distance < 1000 {
            return formatter.string(fromMeters: distance)
        } else {
            return formatter.string(fromKilometers: distance / 1000)
        }
    }
}

struct BarStopDetailSheet: View {
    let location: GeofenceData
    let onNavigate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bar Stop")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(location.name)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(location.description)
                        .font(.body)
                }
                
                // Location info
                if let userLocation = locationManager.location {
                    let barLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    let distance = userLocation.distance(from: barLocation)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.purple)
                            
                            Text(formatDistance(distance) + " away")
                                .font(.body)
                        }
                        
                        // Check-in information
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                            
                            Text("You must be at the location to check in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        onNavigate()
                    }) {
                        Text("Navigate")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("Bar Stop Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        
        if distance < 1000 {
            return formatter.string(fromMeters: distance)
        } else {
            return formatter.string(fromKilometers: distance / 1000)
        }
    }
}

// MARK: - Supporting Types
enum LocationFilter {
    case all
    case tasks
    case barStops
    case nearest
    case within100m
    case within500m
}

struct NearbyLocationsView_Previews: PreviewProvider {
    static var previews: some View {
        let locationManager = LocationManager()
        let geofencingManager = GeofencingManager(
            locationManager: locationManager,
            modelContext: ModelContainer(for: GeofenceData.self).mainContext
        )
        
        // Add some sample data for preview
        let task1 = GeofenceData(
            id: UUID(),
            huntId: UUID(),
            type: .task,
            name: "Find the pirate statue",
            description: "Located near the main pool on deck 12",
            latitude: 25.01,
            longitude: -80.01
        )
        
        let task2 = GeofenceData(
            id: UUID(),
            huntId: UUID(),
            type: .task,
            name: "Take a photo at the bow",
            description: "Channel your inner Jack and Rose from Titanic",
            latitude: 25.02,
            longitude: -80.02
        )
        
        let barStop1 = GeofenceData(
            id: UUID(),
            barCrawlId: UUID(),
            type: .barStop,
            name: "Coconut Club",
            description: "Tropical drinks with an ocean view",
            latitude: 25.015,
            longitude: -80.015
        )
        
        geofencingManager.nearbyTasks = [task1, task2]
        geofencingManager.nearbyBarStops = [barStop1]
        
        return NavigationStack {
            NearbyLocationsView()
                .environmentObject(geofencingManager)
                .environmentObject(locationManager)
        }
    }
} 