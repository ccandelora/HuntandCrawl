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
    @Query private var tasks: [HuntTask]
    
    @State private var selectedItemType: ItemType = .all
    @State private var selectedDistance: Double = 1.0 // in miles
    
    enum ItemType: String, CaseIterable, Identifiable {
        case all = "All"
        case barStops = "Bar Stops"
        case tasks = "Tasks"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        // Simplified to avoid compiler type-checking timeout
        VStack {
            // Filter controls
            filterControlsSection
            
            // Simplified Map without content for now
            Text("Map view temporarily simplified")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
            
            // Legend
            HStack {
                Circle().fill(Color.purple).frame(width: 12, height: 12)
                Text("Bar Stops").font(.caption)
                Circle().fill(Color.blue).frame(width: 12, height: 12)
                Text("Tasks").font(.caption)
                Circle().fill(Color.red).frame(width: 12, height: 12)
                Text("You").font(.caption)
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Nearby")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Filter controls broken out to simplify the body
    private var filterControlsSection: some View {
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
    }
}

// Simplified LegendItem view removed to reduce complexity

#Preview {
    NavigationStack {
        NearbyView()
            .modelContainer(PreviewContainer.previewContainer)
            .environment(LocationManager())
    }
} 