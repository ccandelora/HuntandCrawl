import SwiftUI
import SwiftData
import PhotosUI

struct TaskCompletionView: View {
    let task: Task
    let hunt: Hunt
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
                // Task Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: taskTypeIcon)
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text(task.description)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("\(task.points) points")
                            .font(.headline)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
                
                // Photo Evidence (if required)
                if task.imageRequired {
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
                                    .foregroundColor(.blue)
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
                    
                    Text(networkMonitor.isConnected ? "Online - Task will be synced immediately" : "Offline - Task will be synced when connection is restored")
                        .font(.caption)
                        .foregroundColor(networkMonitor.isConnected ? .green : .red)
                }
                .padding(.horizontal)
                
                // Submit Button
                Button(action: {
                    submitCompletion()
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        
                        Text("Mark as Completed")
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
        .navigationTitle("Complete Task")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if syncManager == nil {
                syncManager = SyncManager(modelContext: modelContext, networkMonitor: networkMonitor)
            }
        }
        .alert("Task Completed", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your task has been marked as completed" + (networkMonitor.isConnected ? "." : " and will be synced when connection is restored."))
        }
    }
    
    private var taskTypeIcon: String {
        switch task.type {
        case .photo:
            return "camera.fill"
        case .location:
            return "mappin.circle.fill"
        case .question:
            return "questionmark.circle.fill"
        case .item:
            return "cube.fill"
        case .activity:
            return "star.fill"
        }
    }
    
    private var isFormValid: Bool {
        // If image is required, ensure we have an image
        if task.imageRequired && evidenceImage == nil {
            return false
        }
        
        return true
    }
    
    private var buttonColor: Color {
        if !isFormValid || isSubmitting {
            return Color.gray
        }
        return Color.blue
    }
    
    private func submitCompletion() {
        guard let currentUser = currentUser, !isSubmitting else { return }
        
        isSubmitting = true
        
        // Create TaskCompletion object
        let completion = TaskCompletion(
            taskId: task.id,
            userId: currentUser.id,
            huntId: hunt.id,
            evidence: evidenceImage,
            points: task.points
        )
        
        // Set local task completion status
        task.isCompleted = true
        
        // Add to model context
        modelContext.insert(completion)
        
        // Create sync event for offline capability
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode([
                "taskId": completion.taskId.uuidString,
                "userId": completion.userId.uuidString,
                "huntId": completion.huntId.uuidString,
                "completedAt": completion.completedAt.ISO8601Format(),
                "points": completion.points,
                "notes": notes
            ])
            
            syncManager?.createSyncEvent(
                entityId: completion.id,
                entityType: .taskCompletion,
                action: .create,
                data: data
            )
            
            // Update user points
            currentUser.totalPoints += task.points
            
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
        TaskCompletionView(
            task: Task(title: "Take a photo of the main deck", description: "Find the main deck and take a photo of the view", points: 50, type: .photo, order: 1, imageRequired: true),
            hunt: Hunt(title: "Cruise Adventure", description: "Explore the cruise ship", location: "Norwegian Joy", createdBy: UUID())
        )
    }
    .modelContainer(for: [Task.self, Hunt.self, User.self, TaskCompletion.self, SyncEvent.self], inMemory: true)
    .environmentObject(NetworkMonitor())
} 