import SwiftUI
import SwiftData
import MapKit

struct BarStopDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let barStop: BarStop
    @State private var showingConfirmationDialog = false
    @State private var showingVisitSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Bar Stop Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(barStop.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if barStop.isVisited {
                            VisitedBadge()
                        }
                    }
                    
                    if let barCrawl = barStop.barCrawl {
                        NavigationLink {
                            // Navigate to bar crawl detail
                        } label: {
                            Label(barCrawl.name, systemImage: "map")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    HStack {
                        StatusBadge(
                            isActive: barStop.isOpen,
                            activeText: "Open Now",
                            inactiveText: "Closed",
                            activeColor: .green,
                            inactiveColor: .red
                        )
                        
                        if let specialDrink = barStop.specialDrink, !specialDrink.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("Special: \(specialDrink)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        if let drinkPrice = barStop.drinkPrice, drinkPrice > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("$\(String(format: "%.2f", drinkPrice))")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Description Section
                if let description = barStop.barStopDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(description)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Location Section
                if barStop.hasLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                        
                        MapLocationPreview(
                            latitude: barStop.coordinate.latitude,
                            longitude: barStop.coordinate.longitude
                        )
                        .frame(height: 200)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Hours Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hours")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Opens")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formatTime(barStop.openTime))
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Closes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formatTime(barStop.closeTime))
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Visits Section
                if let visits = barStop.visits, !visits.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Visits")
                            .font(.headline)
                        
                        ForEach(visits) { visit in
                            VisitRow(visit: visit)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        showingVisitSheet = true
                    } label: {
                        Label("Record a Visit", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    // Only show if user is the creator or admin
                    Button {
                        showingConfirmationDialog = true
                    } label: {
                        Label("Delete Bar Stop", systemImage: "trash")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Bar Stop Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingVisitSheet) {
            // BarStopVisitView would go here
            Text("Record Visit Form")
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Are you sure you want to delete this bar stop?",
            isPresented: $showingConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteBarStop()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func deleteBarStop() {
        modelContext.delete(barStop)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "Not specified" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct VisitedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text("Visited")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.15))
        .cornerRadius(20)
    }
}

struct StatusBadge: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    let activeColor: Color
    let inactiveColor: Color
    
    var body: some View {
        Text(isActive ? activeText : inactiveText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? activeColor.opacity(0.15) : inactiveColor.opacity(0.15))
            .foregroundColor(isActive ? activeColor : inactiveColor)
            .cornerRadius(6)
    }
}

struct MapLocationPreview: View {
    let latitude: Double
    let longitude: Double
    
    var body: some View {
        // In a real app, this would be a MapKit snapshot or actual map
        ZStack {
            Color.gray.opacity(0.2)
            
            VStack {
                Image(systemName: "map.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue.opacity(0.7))
                
                Text("Map View")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("(\(latitude), \(longitude))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct VisitRow: View {
    let visit: BarStopVisit
    
    var body: some View {
        HStack(spacing: 12) {
            if let user = visit.user {
                if let profileImage = user.profileImage, let uiImage = UIImage(data: profileImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let visitDate = visit.visitedAt {
                        Text("Visited on \(formatDate(visitDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let drinkOrdered = visit.drinkOrdered, !drinkOrdered.isEmpty {
                        Text("Drink: \(drinkOrdered)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                
                Text("Unknown User")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let rating = visit.rating, rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(index <= rating ? .yellow : .gray)
                    }
                }
            }
            
            if visit.photoData != nil {
                Image(systemName: "photo.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        BarStopDetailView(barStop: BarStop.example)
    }
    .modelContainer(PreviewContainer.previewContainer)
}

extension BarStop {
    static var example: BarStop {
        let barStop = BarStop(name: "The Tipsy Tavern")
        barStop.barStopDescription = "A cozy pub known for its craft beer selection and friendly atmosphere."
        barStop.specialDrink = "House IPA"
        barStop.drinkPrice = 8.50
        barStop.latitude = 37.7749
        barStop.longitude = -122.4194
        barStop.openTime = Calendar.current.date(from: DateComponents(hour: 16, minute: 0))
        barStop.closeTime = Calendar.current.date(from: DateComponents(hour: 2, minute: 0))
        return barStop
    }
} 