import SwiftUI
import SwiftData
import MapKit

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let task: Task
    
    @State private var showingCompleteTaskSheet = false
    @State private var showingConfirmationDialog = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        PointsBadge(points: task.points)
                    }
                    
                    if let subtitle = task.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                
                // Description Section
                if let description = task.taskDescription, !description.isEmpty {
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
                
                // Verification Method Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Method")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        VerificationMethodBadge(
                            isEnabled: task.verificationMethod == VerificationMethod.photo.rawValue,
                            systemImage: "camera.fill",
                            label: "Photo"
                        )
                        
                        VerificationMethodBadge(
                            isEnabled: task.verificationMethod == VerificationMethod.location.rawValue,
                            systemImage: "location.fill",
                            label: "Location"
                        )
                        
                        VerificationMethodBadge(
                            isEnabled: task.verificationMethod == VerificationMethod.question.rawValue,
                            systemImage: "questionmark.circle.fill",
                            label: "Answer"
                        )
                    }
                    
                    if task.verificationMethod == VerificationMethod.question.rawValue, 
                       let question = task.question, !question.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Question")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(question)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    
                    if task.verificationMethod == VerificationMethod.location.rawValue, 
                       let latitude = task.latitude, let longitude = task.longitude {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            MapSnapshotView(latitude: latitude, longitude: longitude)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .padding(.top, 4)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Completions Section
                if let completions = task.completions, !completions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Completions")
                            .font(.headline)
                        
                        ForEach(completions) { completion in
                            CompletionRow(completion: completion)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        showingCompleteTaskSheet = true
                    } label: {
                        Label("Complete This Task", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    // Only show if user is the creator or admin
                    Button {
                        showingConfirmationDialog = true
                    } label: {
                        Label("Delete Task", systemImage: "trash")
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
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCompleteTaskSheet) {
            // TaskCompletionView would go here
            Text("Task Completion Form")
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Are you sure you want to delete this task?",
            isPresented: $showingConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteTask()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func deleteTask() {
        modelContext.delete(task)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct PointsBadge: View {
    let points: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            
            Text("\(points) pts")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.yellow.opacity(0.15))
        .cornerRadius(20)
    }
}

struct VerificationMethodBadge: View {
    let isEnabled: Bool
    let systemImage: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(isEnabled ? .blue : .gray)
            
            Text(label)
                .font(.caption)
                .foregroundColor(isEnabled ? .primary : .secondary)
        }
        .frame(width: 80, height: 80)
        .background(isEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MapSnapshotView: View {
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

struct CompletionRow: View {
    let completion: TaskCompletion
    
    var body: some View {
        HStack(spacing: 12) {
            if let user = completion.user {
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
                    
                    if let completedDate = completion.completedAt {
                        Text("Completed on \(formatDate(completedDate))")
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
            
            if completion.hasPhoto {
                Image(systemName: "photo.fill")
                    .foregroundColor(.blue)
            }
            
            if completion.hasLocation {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
            }
            
            if completion.hasAnswer {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(.purple)
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

extension TaskCompletion {
    var hasPhoto: Bool {
        return evidenceData != nil
    }
    
    var hasLocation: Bool {
        // We can only check if the verification method is location-based
        return verificationMethod == .location
    }
    
    var hasAnswer: Bool {
        return answer != nil && !answer!.isEmpty
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(task: Task.example)
    }
    .modelContainer(PreviewContainer.previewContainer)
}

extension Task {
    static var example: Task {
        let task = Task(
            title: "Find the secret mural", 
            taskDescription: "Locate the hidden mural in the downtown area and take a photo as proof. The mural was painted by a local artist in 2022.",
            points: 150,
            verificationMethod: .photo,
            latitude: 37.7749,
            longitude: -122.4194
        )
        return task
    }
} 