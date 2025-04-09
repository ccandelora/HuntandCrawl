import SwiftUI
import SwiftData

struct BarCrawlDetailView: View {
    var barCrawl: BarCrawl
    @State private var showJoinConfirmation = false
    @State private var showCheckIn = false
    @State private var selectedStop: BarStop?
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.modelContext) private var modelContext
    @Query private var barStopVisits: [BarStopVisit]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Image
                ZStack(alignment: .bottomLeading) {
                    if let coverImage = barCrawl.coverImage, let uiImage = UIImage(data: coverImage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    } else {
                        Image(systemName: "wineglass.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .background(Color.purple.opacity(0.3))
                    }
                    
                    VStack(alignment: .leading) {
                        Text(barCrawl.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let theme = barCrawl.theme {
                            Text(theme)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
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
                
                // Offline Status Indicator
                if !networkMonitor.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.orange)
                        
                        Text("You're offline. You can still check in at stops and they'll sync when you're back online.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        showJoinConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Join Crawl")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Favorite action
                    }) {
                        HStack {
                            Image(systemName: "heart")
                            Text("Favorite")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this Bar Crawl")
                        .font(.headline)
                    
                    Text(barCrawl.description)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "ship.fill", title: "Ship", value: barCrawl.cruiseShip)
                    
                    if let startTime = barCrawl.startTime {
                        DetailRow(icon: "clock.fill", title: "Start Time", value: startTime.formatted(date: .long, time: .shortened))
                    }
                    
                    if let endTime = barCrawl.endTime {
                        DetailRow(icon: "clock", title: "End Time", value: endTime.formatted(date: .long, time: .shortened))
                    }
                    
                    DetailRow(icon: "person.3.fill", title: "Max Participants", value: barCrawl.maxParticipants != nil ? "\(barCrawl.maxParticipants!)" : "Unlimited")
                    
                    if let stops = barCrawl.stops {
                        DetailRow(icon: "location.fill", title: "Number of Stops", value: "\(stops.count)")
                    }
                }
                .padding(.horizontal)
                
                // Bar Stops
                if let stops = barCrawl.stops, !stops.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Bar Stops")
                                .font(.headline)
                            
                            Spacer()
                            
                            // Progress text
                            Text("\(stops.filter { isStopVisited($0) }.count)/\(stops.count) visited")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Progress bar
                        let progress = calculateProgress(stops: stops)
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .padding(.horizontal)
                        
                        ForEach(stops.sorted(by: { $0.order < $1.order })) { stop in
                            Button(action: {
                                selectedStop = stop
                                showCheckIn = true
                            }) {
                                BarStopRowWithCheckIn(stop: stop, isVisited: isStopVisited(stop))
                            }
                            .disabled(isStopVisited(stop))
                        }
                    }
                }
                
                // Tips and Safety
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips & Safety")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TipRow(icon: "drop.fill", text: "Remember to drink water between stops")
                        TipRow(icon: "person.2.fill", text: "Stay with your group at all times")
                        TipRow(icon: "creditcard.fill", text: "Bring your cruise card for purchases")
                        TipRow(icon: "hand.raised.fill", text: "Drink responsibly and know your limits")
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .alert("Join this Bar Crawl?", isPresented: $showJoinConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                // Join bar crawl action
            }
        } message: {
            Text("You'll be added to this bar crawl and receive notifications for the event.")
        }
        .sheet(isPresented: $showCheckIn, onDismiss: {
            selectedStop = nil
        }) {
            if let stop = selectedStop {
                BarStopVisitView(barStop: stop, barCrawl: barCrawl)
            }
        }
    }
    
    private func isStopVisited(_ stop: BarStop) -> Bool {
        if stop.isVisited {
            return true
        }
        
        // Check if there's a visit record
        return barStopVisits.contains { visit in
            visit.barStopId == stop.id && visit.barCrawlId == barCrawl.id
        }
    }
    
    private func calculateProgress(stops: [BarStop]) -> Double {
        let visitedCount = stops.filter { isStopVisited($0) }.count
        return Double(visitedCount) / Double(stops.count)
    }
}

struct BarStopRowWithCheckIn: View {
    var stop: BarStop
    var isVisited: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("#\(stop.order)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(isVisited ? Color.green : Color.purple)
                    .cornerRadius(20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(stop.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let deckNumber = stop.deckNumber {
                        Text("Deck \(deckNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isVisited ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isVisited ? .green : .gray)
                    .font(.title3)
            }
            
            if let specialDrink = stop.specialDrink {
                Text("Special: \(specialDrink)")
                    .font(.caption)
                    .padding(6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(4)
            }
            
            if let activity = stop.activity {
                Text("Activity: \(activity)")
                    .font(.caption)
                    .padding(6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
            
            if isVisited {
                Text("You've checked in here!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 4)
            } else {
                Text("Tap to check in")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
        .padding(.horizontal)
        .opacity(isVisited ? 0.8 : 1.0)
    }
}

struct TipRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24, height: 24)
            
            Text(text)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        BarCrawlDetailView(barCrawl: BarCrawl(title: "Ultimate Cocktail Tour", description: "Experience the best cocktails from 5 unique bars across the ship. Each stop features a special drink and fun activity!", cruiseShip: "Norwegian Joy", createdBy: UUID()))
    }
    .modelContainer(for: [BarCrawl.self, BarStop.self, BarStopVisit.self], inMemory: true)
    .environmentObject(NetworkMonitor())
} 