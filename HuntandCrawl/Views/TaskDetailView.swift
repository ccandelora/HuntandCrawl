import SwiftUI
import SwiftData
import MapKit

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let task: HuntTask
    
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
                       task.hasLocation {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ShipLocationView(task: task)
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

struct ShipLocationView: View {
    let task: HuntTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.locationDescription)
                        .font(.headline)
                    
                    if let proximityRange = task.proximityRange {
                        Text("Need to be within \(proximityRange) feet/meters of this location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Visual representation of ship deck (simplified)
            ShipDeckView(deckNumber: task.deckNumber ?? 0, section: task.section)
                .frame(height: 150)
                .cornerRadius(12)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ShipDeckView: View {
    let deckNumber: Int
    let section: String?
    
    var body: some View {
        ZStack {
            // Ship outline
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
            
            // Ship sections
            HStack(spacing: 0) {
                Rectangle()
                    .fill(section == "Forward" ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                    .overlay(
                        Text("Forward")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
                
                Rectangle()
                    .fill(section == "Midship" ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                    .overlay(
                        Text("Midship")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
                
                Rectangle()
                    .fill(section == "Aft" ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                    .overlay(
                        Text("Aft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }
            .padding(20)
            
            // Deck label
            VStack {
                Spacer()
                Text("Deck \(deckNumber)")
                    .font(.headline)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
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
        TaskDetailView(task: HuntTask.example)
    }
    .modelContainer(PreviewContainer.previewContainer)
}

extension HuntTask {
    static var example: HuntTask {
        let task = HuntTask(
            title: "Find the secret mural", 
            taskDescription: "Locate the hidden mural in the downtown area and take a photo as proof. The mural was painted by a local artist in 2022.",
            points: 150,
            verificationMethod: .photo,
            deckNumber: 8,
            locationOnShip: "Promenade Deck",
            section: "Forward",
            proximityRange: 50
        )
        return task
    }
} 