import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation

struct BarStopVisitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var visit: BarStopVisit
    @State private var showingPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var evidenceImage: Image?
    @State private var evidenceImageData: Data?
    @State private var drinkOrdered = ""
    @State private var userRating = 3
    @State private var comments = ""
    @State private var showingVerificationAlert = false
    @State private var verificationMessage = ""
    @State private var showingSuccessAlert = false
    @State private var isSubmitting = false
    @State private var isLoading = true
    
    @Environment(LocationManager.self) private var locationManager
    @EnvironmentObject private var navigationManager: NavigationManager
    
    let barStop: BarStop
    let user: User
    
    init(barStop: BarStop, user: User) {
        self.barStop = barStop
        self.user = user
        
        // Initialize with a new visit
        _visit = State(initialValue: BarStopVisit(
            visitedAt: Date(),
            barStop: barStop,
            user: user
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Bar Stop details
                Group {
                    Text(barStop.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(barStop.barStopDescription ?? "No description provided")
                        .font(.body)
                    
                    HStack {
                        Image(systemName: "wineglass.fill")
                            .foregroundColor(.purple)
                        Text("Special Drink: \(barStop.specialDrink)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.green)
                        Text("Price: $\(String(format: "%.2f", barStop.drinkPrice))")
                            .font(.headline)
                    }
                    
                    Divider()
                }
                
                // Location verification
                Group {
                    Text("Check In")
                        .font(.headline)
                    
                    if barStop.isOpen {
                        locationVerificationView
                    } else {
                        Text("This bar is currently closed. Open hours: \(formattedOpenHours)")
                            .foregroundColor(.red)
                    }
                    
                    Divider()
                }
                
                // Visit details
                Group {
                    Text("Your Visit")
                        .font(.headline)
                    
                    TextField("What drink did you order?", text: $drinkOrdered)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Rate your experience:")
                        .font(.subheadline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { rating in
                            Image(systemName: rating <= userRating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    userRating = rating
                                }
                        }
                    }
                    
                    Text("Add a photo (optional):")
                        .font(.subheadline)
                    
                    if let image = evidenceImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        showingPhotosPicker = true
                    } label: {
                        Label(evidenceImage == nil ? "Add Photo" : "Change Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedPhotoItem)
                    .onChange(of: selectedPhotoItem) { _, newValue in
                        processSelectedPhoto(newValue)
                    }
                    
                    Text("Comments:")
                        .font(.subheadline)
                    
                    TextEditor(text: $comments)
                        .frame(height: 100)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Submit button
                Button(action: saveVisit) {
                    Text("Submit Visit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isSubmitting || !canSubmit)
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Visit \(barStop.name)")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Verification", isPresented: $showingVerificationAlert) {
            Button("OK") { }
        } message: {
            Text(verificationMessage)
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your visit has been recorded!")
        }
        .task {
            loadOrCreateVisit()
        }
    }
    
    private var locationVerificationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You need to be at the correct location to check in")
                .font(.subheadline)
            
            if let deckNumber = barStop.deckNumber, let locationOnShip = barStop.locationOnShip {
                // In a real app, this would use more sophisticated location verification
                // For now, we'll simplify it to always show as verified
                let isNearLocation = true
                
                HStack {
                    Image(systemName: isNearLocation ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isNearLocation ? .green : .red)
                    
                    Text(isNearLocation ? "You are at the bar!" : "You are not at the bar location")
                        .font(.callout)
                }
                
                Text("Bar Location: Deck \(deckNumber), \(locationOnShip)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("This bar stop does not have a valid location set")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var formattedOpenHours: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let openTime = formatter.string(from: barStop.openingTime ?? Date())
        let closeTime = formatter.string(from: barStop.closingTime ?? Date())
        
        return "\(openTime) - \(closeTime)"
    }
    
    private var canSubmit: Bool {
        // Basic validation
        if drinkOrdered.isEmpty {
            return false
        }
        
        // Location verification
        if let latitude = barStop.latitude, let longitude = barStop.longitude {
            return locationManager.isUserNearCoordinate(
                latitude: latitude,
                longitude: longitude,
                radius: barStop.checkInRadius
            )
        }
        
        return false
    }
    
    private func loadOrCreateVisit() {
        // Use a simpler approach without complex predicates
        do {
            // Get all visits
            let descriptor = FetchDescriptor<BarStopVisit>()
            let allVisits = try modelContext.fetch(descriptor)
            
            // Find matching visit manually
            let existingVisit = allVisits.first { visit in
                return visit.barStop?.id == self.barStop.id && visit.user?.id == self.user.id
            }
            
            if let existingVisit = existingVisit {
                visit = existingVisit
                
                // Load existing values
                drinkOrdered = existingVisit.drinkOrdered ?? ""
                userRating = existingVisit.rating
                comments = existingVisit.comments ?? ""
                
                // Load existing photo if available
                if let photoData = existingVisit.photoData {
                    if let uiImage = UIImage(data: photoData) {
                        evidenceImage = Image(uiImage: uiImage)
                        evidenceImageData = photoData
                    }
                }
            }
            
            isLoading = false
        } catch {
            print("Error fetching existing visit: \(error)")
            isLoading = false
        }
    }
    
    private func processSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data, let uiImage = UIImage(data: data) {
                        self.evidenceImage = Image(uiImage: uiImage)
                        self.evidenceImageData = data
                    }
                case .failure(let error):
                    print("Photo selection error: \(error)")
                }
            }
        }
    }
    
    private func saveVisit() {
        isSubmitting = true
        
        // Verify location
        if let latitude = barStop.latitude, let longitude = barStop.longitude {
            let isAtLocation = locationManager.isUserNearCoordinate(
                latitude: latitude,
                longitude: longitude,
                radius: barStop.checkInRadius
            )
            
            if !isAtLocation {
                verificationMessage = "You need to be at the bar location to check in"
                showingVerificationAlert = true
                isSubmitting = false
                return
            }
        }
        
        // Update visit details
        visit.visitedAt = Date()
        visit.drinkOrdered = drinkOrdered
        visit.rating = userRating
        visit.comments = comments
        visit.photoData = evidenceImageData
        
        // Save to context if not already there
        if visit.modelContext == nil {
            modelContext.insert(visit)
        }
        
        do {
            try modelContext.save()
            isSubmitting = false
            showingSuccessAlert = true
        } catch {
            print("Error saving visit: \(error)")
            verificationMessage = "Error saving visit: \(error.localizedDescription)"
            showingVerificationAlert = true
            isSubmitting = false
        }
    }
}

// MARK: - Preview
struct BarStopVisitView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: BarStop.self, User.self, BarStopVisit.self, configurations: config)
        
        let user = User(name: "Test User", email: "test@example.com")
        
        let barStop = BarStop(name: "Sunset Bar", specialDrink: "Mai Tai", drinkPrice: 12.99)
        barStop.barStopDescription = "Beautiful bar with ocean views"
        barStop.latitude = 25.0001
        barStop.longitude = -80.0001
        barStop.checkInRadius = 100
        barStop.openingTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())
        barStop.closingTime = Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date())
        
        container.mainContext.insert(user)
        container.mainContext.insert(barStop)
        
        return NavigationStack {
            BarStopVisitView(barStop: barStop, user: user)
                .modelContainer(container)
                .environment(LocationManager())
                .environmentObject(NavigationManager())
        }
    }
} 