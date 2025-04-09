import SwiftUI
import MapKit
import Combine

// Mock or ensure LocationManager and NavigationManager conform to Observable
@Observable
class MockLocationManager {
    var currentLocation: CLLocation? = CLLocation(latitude: 34.05, longitude: -118.25)
}

@Observable
class MockNavigationManager {
    var route: MKRoute? = nil
    var navigationDirections: String = "Turn left at the next junction."
    var currentNavigationStep: String = "Proceed 50m"
    var isNavigating: Bool = false
    var remainingDistance: Double = 120.0 // meters
    var estimatedTime: TimeInterval = 60 // seconds

    func startNavigation(to destination: CLLocationCoordinate2D) { isNavigating = true }
    func stopNavigation() { isNavigating = false }
}

struct NavigationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var locationManager
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // Destination information
    let destinationName: String
    let destinationCoordinate: CLLocationCoordinate2D
    let type: NavigationType
    
    // View state
    @State private var cameraPosition: MapCameraPosition
    @State private var mapStyle: MapStyle = .standard
    @State private var showFullDirections = false
    
    init(
        destinationName: String,
        destinationLatitude: Double,
        destinationLongitude: Double,
        type: NavigationType
    ) {
        self.destinationName = destinationName
        self.destinationCoordinate = CLLocationCoordinate2D(
            latitude: destinationLatitude,
            longitude: destinationLongitude
        )
        self.type = type
        
        // Initialize camera position
        _cameraPosition = State(initialValue: .automatic)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map view
            Map(position: $cameraPosition, selection: .constant(nil)) {
                // Current user location
                if let userLocation = locationManager.userLocation {
                    Marker("My Location", coordinate: userLocation.coordinate)
                        .tint(.blue)
                }
                
                // Destination marker
                if let destinationCoordinate = navigationManager.currentDestinationCoordinate {
                    Marker(destinationName, coordinate: destinationCoordinate)
                        .tint(type.markerColor)
                }
                
                // Route line if available
                if let route = navigationManager.route {
                    MapPolyline(route.polyline)
                        .stroke(type.routeColor, lineWidth: 5)
                }
            }
            .mapStyle(mapStyle)
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
            }
            .onAppear {
                startNavigation()
            }
            .onChange(of: locationManager.location) { oldValue, newValue in
                updateCamera()
            }
            
            // Bottom navigation card
            navigationCard
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    stopNavigation()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Stop")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { mapStyle = .standard }) {
                        Label("Standard", systemImage: "map")
                    }
                    
                    Button(action: { mapStyle = .hybrid }) {
                        Label("Satellite", systemImage: "network")
                    }
                    
                    Divider()
                    
                    Button(action: centerOnUserLocation) {
                        Label("Center on Me", systemImage: "location")
                    }
                    
                    Button(action: showFullRoute) {
                        Label("View Full Route", systemImage: "arrow.triangle.swap")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showFullDirections) {
            NavigationStack {
                directionsListView
                    .navigationTitle("Turn-by-Turn Directions")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showFullDirections = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Navigation Card
    private var navigationCard: some View {
        VStack(spacing: 0) {
            // Current direction
            if locationManager.isNavigating, let currentStep = getCurrentNavigationStep() {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Next Step")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(currentStep)
                            .font(.headline)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if let distance = locationManager.distance {
                        VStack(alignment: .trailing) {
                            Text(formatDistance(distance))
                                .font(.headline)
                            
                            if let time = locationManager.expectedTravelTime {
                                Text(formatTime(time))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .shadow(radius: 2)
            }
            
            // Bottom card
            VStack(spacing: 12) {
                // Destination info
                HStack(spacing: 12) {
                    type.icon
                        .font(.system(size: 36))
                        .foregroundColor(type.iconColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destinationName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let distance = locationManager.distance(to: CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)) {
                            Text("Distance: \(formatDistance(distance))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Navigation status
                Group {
                    if locationManager.isNavigating {
                        // Navigation buttons
                        HStack(spacing: 16) {
                            Button(action: centerOnUserLocation) {
                                Label("Center", systemImage: "location")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            
                            Button(action: { showFullDirections = true }) {
                                Label("Directions", systemImage: "list.bullet")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.purple.opacity(0.2))
                            .foregroundColor(.purple)
                            
                            Button(action: {
                                stopNavigation()
                                dismiss()
                            }) {
                                Label("Stop", systemImage: "xmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                        }
                    } else {
                        // Start navigation button
                        Button(action: startNavigation) {
                            Text("Start Navigation")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(type.mainColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
    }
    
    // MARK: - Directions List View
    private var directionsListView: some View {
        List {
            Section {
                HStack {
                    type.icon
                        .font(.title3)
                        .foregroundColor(type.iconColor)
                    
                    Text(destinationName)
                        .font(.headline)
                    
                    Spacer()
                    
                    if let distance = locationManager.distance {
                        Text(formatDistance(distance))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Turn-by-Turn Directions") {
                ForEach(Array(locationManager.navigationDirections.enumerated()), id: \.offset) { index, instruction in
                    HStack {
                        if index == locationManager.currentNavigationStep {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        } else {
                            Circle()
                                .strokeBorder(Color.gray, lineWidth: 1)
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(instruction)
                            .foregroundColor(index == locationManager.currentNavigationStep ? .primary : .secondary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startNavigation() {
        let destination = CLLocation(latitude: destinationCoordinate.latitude, longitude: destinationCoordinate.longitude)
        locationManager.startNavigation(to: destination)
        updateCamera()
    }
    
    private func stopNavigation() {
        locationManager.stopNavigation()
    }
    
    private func updateCamera() {
        // Set camera to follow user location with heading
        if let userLocation = locationManager.location {
            // If we have a heading, use it for camera rotation
            if let heading = locationManager.heading {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: userLocation.coordinate,
                        distance: 300, // meters
                        heading: heading.trueHeading,
                        pitch: 45 // degrees
                    )
                )
            } else {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: userLocation.coordinate,
                        distance: 300 // meters
                    )
                )
            }
        }
    }
    
    private func centerOnUserLocation() {
        updateCamera()
    }
    
    private func showFullRoute() {
        if let route = locationManager.route {
            // Create a region that encompasses the entire route
            let rect = route.polyline.boundingMapRect
            cameraPosition = .rect(MKMapRect(
                x: rect.origin.x - rect.size.width * 0.1,
                y: rect.origin.y - rect.size.height * 0.1,
                width: rect.size.width * 1.2,
                height: rect.size.height * 1.2
            ))
        }
    }
    
    private func getCurrentNavigationStep() -> String? {
        guard locationManager.isNavigating, 
              !locationManager.navigationDirections.isEmpty,
              locationManager.currentNavigationStep < locationManager.navigationDirections.count else {
            return nil
        }
        
        return locationManager.navigationDirections[locationManager.currentNavigationStep]
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        
        if distance < 1000 {
            return formatter.string(fromMeters: distance)
        } else {
            return formatter.string(fromMeters: distance)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: time) ?? "Unknown"
    }
}

// MARK: - Navigation Type
enum NavigationType {
    case hunt
    case barCrawl
    case teamMember
    
    var icon: Image {
        switch self {
        case .hunt:
            return Image(systemName: "map.fill")
        case .barCrawl:
            return Image(systemName: "wineglass.fill")
        case .teamMember:
            return Image(systemName: "person.fill")
        }
    }
    
    var iconColor: Color {
        switch self {
        case .hunt:
            return .blue
        case .barCrawl:
            return .purple
        case .teamMember:
            return .green
        }
    }
    
    var markerColor: Color {
        switch self {
        case .hunt:
            return .blue
        case .barCrawl:
            return .purple
        case .teamMember:
            return .green
        }
    }
    
    var routeColor: Color {
        switch self {
        case .hunt:
            return .blue
        case .barCrawl:
            return .purple
        case .teamMember:
            return .green
        }
    }
    
    var mainColor: Color {
        switch self {
        case .hunt:
            return .blue
        case .barCrawl:
            return .purple
        case .teamMember:
            return .green
        }
    }
}

// MARK: - Custom Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        let locationManager = LocationManager()
        let navigationManager = NavigationManager()
        
        return NavigationStack {
            NavigationView(
                destinationName: "Sample Task Location",
                destinationLatitude: 25.01,
                destinationLongitude: -80.01,
                type: .hunt
            )
            .environment(locationManager)
            .environmentObject(navigationManager)
        }
    }
} 