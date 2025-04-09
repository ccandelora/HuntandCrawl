import SwiftUI
import MapKit
import SwiftData

struct NearbyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationManager.self) private var locationManager
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Query private var barStops: [BarStop]
    @Query private var tasks: [Task]
    
    @State private var selectedItemType: ItemType = .all
    @State private var selectedDistance: Double = 1.0 // in miles
    
    enum ItemType: String, CaseIterable, Identifiable {
        case all = "All"
        case barStops = "Bar Stops"
        case tasks = "Tasks"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter controls
            VStack {
                HStack {
                    Text("Show:")
                        .font(.subheadline)
                    
                    Picker("Filter", selection: $selectedItemType) {
                        ForEach(ItemType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                HStack {
                    Text("Distance: \(String(format: "%.1f", selectedDistance)) miles")
                        .font(.subheadline)
                    
                    Slider(value: $selectedDistance, in: 0.1...5.0, step: 0.1)
                }
            }
            .padding()
            .background(Color.white)
            
            // Map
            Map(initialPosition: .region(mapRegion)) {
                // Bar Stops
                if selectedItemType == .all || selectedItemType == .barStops {
                    ForEach(barStops) { barStop in
                        if let latitude = barStop.latitude, let longitude = barStop.longitude,
                           isWithinDistance(latitude: latitude, longitude: longitude) {
                            Marker(barStop.name, coordinate: CLLocationCoordinate2D(
                                latitude: latitude, longitude: longitude
                            ))
                            .tint(.purple)
                        }
                    }
                }
                
                // Tasks
                if selectedItemType == .all || selectedItemType == .tasks {
                    ForEach(tasks) { task in
                        if let latitude = task.latitude, let longitude = task.longitude,
                           isWithinDistance(latitude: latitude, longitude: longitude) {
                            Marker(task.title, coordinate: CLLocationCoordinate2D(
                                latitude: latitude, longitude: longitude
                            ))
                            .tint(.blue)
                        }
                    }
                }
                
                // User's current location
                if let location = locationManager.location {
                    Marker("You are here", coordinate: location.coordinate)
                        .tint(.red)
                }
            }
            
            // Legend
            HStack {
                if selectedItemType == .all || selectedItemType == .barStops {
                    LegendItem(color: .purple, label: "Bar Stops")
                }
                
                if selectedItemType == .all || selectedItemType == .tasks {
                    LegendItem(color: .blue, label: "Tasks")
                }
                
                LegendItem(color: .red, label: "You")
            }
            .padding()
            .background(Color.white)
        }
        .onAppear {
            if let location = locationManager.location {
                mapRegion.center = location.coordinate
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let newLocation = newLocation {
                mapRegion.center = newLocation.coordinate
            }
        }
        .navigationTitle("Nearby")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func isWithinDistance(latitude: Double, longitude: Double) -> Bool {
        guard let userLocation = locationManager.location else { return true }
        
        let itemLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distanceInMeters = userLocation.distance(from: itemLocation)
        let distanceInMiles = distanceInMeters / 1609.34 // Convert meters to miles
        
        return distanceInMiles <= selectedDistance
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    NavigationStack {
        NearbyView()
            .modelContainer(PreviewContainer.previewContainer)
            .environment(LocationManager())
    }
} 