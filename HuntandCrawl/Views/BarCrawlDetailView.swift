import SwiftUI
import SwiftData
import MapKit

struct BarCrawlDetailView: View {
    @Bindable var barCrawl: BarCrawl
    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var showingCheckInSheet: BarStop? = nil
    
    // Map Region State
    @State private var position: MapCameraPosition
    
    init(barCrawl: BarCrawl) {
        self.barCrawl = barCrawl
        // Initialize map position centered on the first bar stop or a default location
        let initialCoordinate: CLLocationCoordinate2D
        if let firstStop = barCrawl.barStops?.sorted(by: { $0.order < $1.order }).first,
           let latitude = firstStop.latitude,
           let longitude = firstStop.longitude {
            initialCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            initialCoordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437) // Default (e.g., LA)
        }
        self._position = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Image (Optional)
                // TODO: Add image loading if barCrawl has an image property
                Image(systemName: "figure.walk.motion") // Placeholder
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipped()

                // Basic Info Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(barCrawl.name)
                        .font(.largeTitle).bold()
                    
                    if let theme = barCrawl.theme, !theme.isEmpty {
                         Text("Theme: \(theme)")
                             .font(.headline)
                             .foregroundColor(.secondary)
                    }

                    Text(barCrawl.barCrawlDescription ?? "No description provided.") // Fixed to use barCrawlDescription
                        .font(.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Image(systemName: "calendar")
                        // Safely format dates
                        if let startTime = barCrawl.startTime, let endTime = barCrawl.endTime {
                            Text("\(startTime.formatted(.dateTime.day().month().year())) - \(endTime.formatted(.dateTime.day().month().year()))")
                        } else {
                            Text("Dates not specified")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Divider()

                // Map Section
                Section("Route") {
                    Map(position: $position) {
                        ForEach(barCrawl.barStops?.sorted(by: { $0.order < $1.order }) ?? []) { stop in
                            if let latitude = stop.latitude, let longitude = stop.longitude {
                                Marker(stop.name, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                            }
                        }
                    }
                    .frame(height: 300)
                }
                .padding(.horizontal)
                
                Divider()

                // Bar Stops Section
                Section("Stops") {
                    if let stops = barCrawl.barStops?.sorted(by: { $0.order < $1.order }), !stops.isEmpty {
                        ForEach(stops) { stop in
                            barStopRow(stop: stop)
                            Divider()
                        }
                    } else {
                        Text("No stops added yet.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                 .padding(.leading) // Indent section content slightly
            }
        }
        .navigationTitle(barCrawl.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showingCheckInSheet) { stop in
             // Pass the necessary environment objects if CheckInView requires them
             CheckInView(barStop: stop)
                 .presentationDetents([.medium, .large])
         }
    }

    // Bar Stop Row View
    @ViewBuilder
    private func barStopRow(stop: BarStop) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(stop.order). \(stop.name)")
                    .font(.headline)
                Text(stop.barStopDescription ?? "No description") // Use barStopDescription
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                if let drink = stop.specialDrink, !drink.isEmpty {
                    Text("Special: \(drink)")
                        .font(.caption)
                        .italic()
                }
            }

            Spacer()

            // Check-in button
            Button {
                showingCheckInSheet = stop
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(hasVisited(stop: stop) ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.trailing) // Add padding to the right of the HStack
    }
    
    // Check if a stop has been visited (placeholder logic)
    private func hasVisited(stop: BarStop) -> Bool {
        // Implement logic to check if a BarStopVisit exists for this stop
        // Example: Query BarStopVisit where barStopId == stop.id
        // For now, return false
        if let visits = stop.visits, !visits.isEmpty {
            return true
        }
        return false
    }
}

// Check-In View (Simplified Placeholder)
struct CheckInView: View {
    @Bindable var barStop: BarStop
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // Assuming BarStopVisit needs these parameters based on previous context
    // Define state variables for potential inputs
    @State private var notes: String = ""
    @State private var rating: Int = 3 // Default rating
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Check in at \(barStop.name)")
                    .font(.title)
                // Add check-in UI elements (e.g., photo, notes, rating)
                TextEditor(text: $notes)
                    .border(Color.gray)
                    .frame(height: 100)
                
                Stepper("Rating: \(rating)", value: $rating, in: 1...5)
                
                Spacer()
                
                Button("Confirm Check-In") {
                    confirmCheckIn()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Check In")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
    
    private func confirmCheckIn() {
        // Create and insert BarStopVisit using the correct model parameters
        let visit = BarStopVisit(
            id: UUID().uuidString,
            userId: "currentUser", // Replace with actual user logic
            visitedAt: Date(),
            drinkOrdered: notes, // Using notes as drinkOrdered for simplicity
            rating: rating,
            comments: nil,
            photoData: nil
        )
        
        // Set relationships
        visit.barStop = barStop
        
        modelContext.insert(visit)
        print("Checked in at \(barStop.name) (Placeholder in DetailView)")
    }
}

// MARK: - Preview Provider
struct BarCrawlDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContent()
    }
    
    // Create a simple struct to act as a container for our preview setup
    struct PreviewContent: View {
        static let container: ModelContainer = {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(
                for: BarCrawl.self, BarStop.self, BarStopVisit.self, User.self, 
                configurations: config
            )
            let context = container.mainContext

            let sampleUser = User(username: "PreviewUser", displayName: "PreviewUser")
            let crawl = BarCrawl(
                name: "Preview Crawl", 
                barCrawlDescription: "A fun crawl", 
                theme: "Cocktails",
                startTime: Date(), 
                endTime: Date().addingTimeInterval(3600*3),
                isActive: true
            )
            crawl.creator = sampleUser
            context.insert(sampleUser)
            context.insert(crawl)
            
            let stop1 = BarStop(
                name: "Stop 1", 
                specialDrink: "Drink 1", 
                drinkPrice: 12.99,
                barStopDescription: "First stop desc", 
                latitude: 34.05, 
                longitude: -118.25, 
                order: 1
            )
            let stop2 = BarStop(
                name: "Stop 2", 
                specialDrink: "Drink 2", 
                drinkPrice: 14.99,
                barStopDescription: "Second stop desc", 
                latitude: 34.055, 
                longitude: -118.255, 
                order: 2
            )
            stop1.barCrawl = crawl
            stop2.barCrawl = crawl
            context.insert(stop1)
            context.insert(stop2)
            
            let visit1 = BarStopVisit(
                id: UUID().uuidString,
                userId: sampleUser.id,
                visitedAt: Date(),
                drinkOrdered: "Margarita",
                rating: 5,
                comments: nil,
                photoData: nil
            )
            visit1.barStop = stop1
            context.insert(visit1)
            
            return container
        }()
        
        var body: some View {
            // Simple, clean final expression - no branching logic in the actual preview
            let descriptor = FetchDescriptor<BarCrawl>()
            let crawls = try? PreviewContent.container.mainContext.fetch(descriptor)
            
            if let crawl = crawls?.first {
                NavigationStack {
                    BarCrawlDetailView(barCrawl: crawl)
                        .modelContainer(PreviewContent.container)
                        .environment(NetworkMonitor())
                        .environment(LocationManager())
                }
            } else {
                Text("Preview data loading failed")
            }
        }
    }
} 