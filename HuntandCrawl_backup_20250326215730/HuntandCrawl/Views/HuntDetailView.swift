import SwiftUI
import SwiftData

struct HuntDetailView: View {
    var hunt: Hunt
    @State private var showJoinConfirmation = false
    @State private var showTaskCompletion = false
    @State private var selectedTask: Task?
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.modelContext) private var modelContext
    @Query private var completions: [TaskCompletion]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Image
                ZStack(alignment: .bottomLeading) {
                    if let coverImage = hunt.coverImage, let uiImage = UIImage(data: coverImage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    } else {
                        Image(systemName: "map.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .background(Color.indigo.opacity(0.3))
                    }
                    
                    VStack(alignment: .leading) {
                        Text(hunt.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let theme = hunt.theme {
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
                        
                        Text("You're offline. You can still complete tasks and they'll sync when you're back online.")
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
                            Text("Join Hunt")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
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
                    Text("About this Hunt")
                        .font(.headline)
                    
                    Text(hunt.description)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "mappin.circle.fill", title: "Location", value: hunt.location)
                    
                    if let startTime = hunt.startTime {
                        DetailRow(icon: "clock.fill", title: "Start Time", value: startTime.formatted(date: .long, time: .shortened))
                    }
                    
                    if let endTime = hunt.endTime {
                        DetailRow(icon: "clock", title: "End Time", value: endTime.formatted(date: .long, time: .shortened))
                    }
                    
                    DetailRow(icon: "person.3.fill", title: "Max Participants", value: hunt.maxParticipants != nil ? "\(hunt.maxParticipants!)" : "Unlimited")
                }
                .padding(.horizontal)
                
                // Tasks
                if let tasks = hunt.tasks, !tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tasks")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(tasks) { task in
                            Button(action: {
                                selectedTask = task
                                showTaskCompletion = true
                            }) {
                                TaskRowView(task: task, isCompleted: isTaskCompleted(task))
                            }
                        }
                        
                        // Progress Bar
                        let progress = calculateProgress(tasks: tasks)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Progress")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                
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
        .alert("Join this Scavenger Hunt?", isPresented: $showJoinConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                // Join hunt action
            }
        } message: {
            Text("You'll be added to this hunt and can start completing tasks.")
        }
        .sheet(isPresented: $showTaskCompletion, onDismiss: {
            selectedTask = nil
        }) {
            if let task = selectedTask {
                TaskCompletionView(task: task, hunt: hunt)
            }
        }
    }
    
    private func isTaskCompleted(_ task: Task) -> Bool {
        if task.isCompleted {
            return true
        }
        
        // Check in completions
        return completions.contains { completion in
            completion.taskId == task.id && completion.huntId == hunt.id
        }
    }
    
    private func calculateProgress(tasks: [Task]) -> Double {
        let completedCount = tasks.filter { isTaskCompleted($0) }.count
        return Double(completedCount) / Double(tasks.count)
    }
}

struct DetailRow: View {
    var icon: String
    var title: String
    var value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.title3)
            
            Image(systemName: task.type == .photo ? "camera.fill" :
                              task.type == .location ? "mappin.circle.fill" :
                              task.type == .question ? "questionmark.circle.fill" :
                              task.type == .item ? "cube.fill" : "star.fill")
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(task.points) points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .opacity(isCompleted ? 0.6 : 1.0)
    }
}

#Preview {
    NavigationView {
        HuntDetailView(hunt: Hunt(title: "Pirate's Treasure", description: "Search the ship for hidden treasures and solve puzzles to win!", location: "Norwegian Joy", createdBy: UUID()))
    }
    .modelContainer(for: [Hunt.self, Task.self, TaskCompletion.self], inMemory: true)
    .environmentObject(NetworkMonitor())
} 