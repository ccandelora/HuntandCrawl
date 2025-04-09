import SwiftUI
import SwiftData
import PhotosUI

struct BarStopVisitView: View {
    let barStop: BarStop
    let barCrawl: BarCrawl
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var evidenceImage: Data?
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var syncManager: SyncManager?
    
    var currentUser: User? {
        return users.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Bar Stop Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("#\(barStop.order)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.purple)
                            .cornerRadius(20)
                        
                        Text(barStop.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text(barStop.description)
                        .foregroundColor(.secondary)
                    
                    Text("Location: \(barStop.location)")
                        .font(.subheadline)
                        .padding(.top, 4)
                    
                    if let deckNumber = barStop.deckNumber {
                        Text("Deck: \(deckNumber)")
                            .font(.subheadline)
                    }
                    
                    if let specialDrink = barStop.specialDrink {
                        HStack {
                            Image(systemName: "wineglass")
                                .foregroundColor(.purple)
                            Text("Special: \(specialDrink)")
                                .font(.subheadline)
                                .foregroundColor(.purple)
                        }
                        .padding(.top, 4)
                    }
                    
                    if let activity = barStop.activity {
                        HStack {
                            Image(systemName: "figure.wave")
                                .foregroundColor(.orange)
                            Text("Activity: \(activity)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
                
                // Photo Evidence (if required)
                if barStop.imageRequired {
                    VStack(spacing: 12) {
                        Text("Photo Evidence")
                            .font(.headline)
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let evidenceImage = evidenceImage, let uiImage = UIImage(data: evidenceImage) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .padding(8),
                                        alignment: .bottomTrailing
                                    )
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)
                                    
                                    VStack {
                                        Image(systemName: "camera")
                                            .font(.largeTitle)
                                        
                                        Text("Take Photo")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.purple)
                                }
                            }
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    evidenceImage = data
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.headline)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
                
                // Connection Status
                HStack {
                    Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .foregroundColor(networkMonitor.isConnected ? .green : .red)
                    
                    Text(networkMonitor.isConnected ? "Online - Check-in will be synced immediately" : "Offline - Check-in will be synced when connection is restored")
                        .font(.caption)
                        .foregroundColor(networkMonitor.isConnected ? .green : .red)
                }
                .padding(.horizontal)
                
                // Submit Button
                Button(action: {
                    submitVisit()
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        
                        Text("Check In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || isSubmitting)
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("Check In at \(barStop.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if syncManager == nil {
                syncManager = SyncManager(modelContext: modelContext, networkMonitor: networkMonitor)
            }
        }
        .alert("Check-In Complete", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                barStop.isVisited = true
                dismiss()
            }
        } message: {
            Text("You've checked in at \(barStop.name)" + (networkMonitor.isConnected ? "." : " and it will be synced when connection is restored."))
        }
    }
    
    private var isFormValid: Bool {
        // If image is required, ensure we have an image
        if barStop.imageRequired && evidenceImage == nil {
            return false
        }
        
        return true
    }
    
    private var buttonColor: Color {
        if !isFormValid || isSubmitting {
            return Color.gray
        }
        return Color.purple
    }
    
    private func submitVisit() {
        guard let currentUser = currentUser, !isSubmitting else { return }
        
        isSubmitting = true
        
        // Create BarStopVisit object
        let visit = BarStopVisit(
            barStopId: barStop.id,
            userId: currentUser.id,
            barCrawlId: barCrawl.id,
            evidence: evidenceImage,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Add to model context
        modelContext.insert(visit)
        
        // Create sync event for offline capability
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode([
                "barStopId": visit.barStopId.uuidString,
                "userId": visit.userId.uuidString,
                "barCrawlId": visit.barCrawlId.uuidString,
                "visitedAt": visit.visitedAt.ISO8601Format(),
                "notes": visit.notes ?? ""
            ])
            
            syncManager?.createSyncEvent(
                entityId: visit.id,
                entityType: .barStop,
                action: .update,
                data: data
            )
            
            // Show success alert
            isSubmitting = false
            showSuccessAlert = true
        } catch {
            isSubmitting = false
            print("Failed to create sync event: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        BarStopVisitView(
            barStop: BarStop(name: "Martini Bar", description: "Elegant bar featuring craft martinis and cocktails", location: "Deck 5, Midship", order: 2),
            barCrawl: BarCrawl(title: "Mixology Tour", description: "Experience the best cocktails on the ship", cruiseShip: "Norwegian Joy", createdBy: UUID())
        )
    }
    .modelContainer(for: [BarStop.self, BarCrawl.self, User.self, BarStopVisit.self, SyncEvent.self], inMemory: true)
    .environmentObject(NetworkMonitor())
} 