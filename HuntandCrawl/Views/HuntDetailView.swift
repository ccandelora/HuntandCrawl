import SwiftUI
import SwiftData
import MapKit

struct HuntDetailView: View {
    @Bindable var hunt: Hunt
    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var showingTaskCompletionSheet: Task? = nil
    
    // Map Region State
    @State private var position: MapCameraPosition
    
    init(hunt: Hunt) {
        self.hunt = hunt
        // Initialize map position centered on the first task or a default location
        let initialCoordinate: CLLocationCoordinate2D
        if let firstTask = hunt.tasks?.sorted(by: { $0.order < $1.order }).first {
            initialCoordinate = CLLocationCoordinate2D(
                latitude: firstTask.latitude ?? 34.0522, 
                longitude: firstTask.longitude ?? -118.2437
            )
        } else {
            initialCoordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437) // Default
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
                Image(systemName: "map.fill") // Placeholder
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipped()

                // Basic Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(hunt.name)
                        .font(.largeTitle).bold()

                    Text(hunt.huntDescription ?? "No description provided.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text("\(hunt.startTime?.formatted(.dateTime.day().month().year()) ?? "TBD") - \(hunt.endTime?.formatted(.dateTime.day().month().year()) ?? "TBD")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("\(totalPoints) total points") // Calculate total points
                        Spacer()
                        Image(systemName: "person.3.fill").foregroundColor(.secondary)
                        Text("\(participantCount) participants")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Offline Warning
                if !networkMonitor.isConnected {
                     HStack {
                         Image(systemName: "wifi.slash")
                         Text("You're offline. Task completions will sync later.")
                             .font(.caption)
                     }
                     .foregroundColor(.orange)
                     .padding(.horizontal)
                }

                Divider()

                // Map Section
                 Section("Task Locations") {
                     Map(position: $position) {
                         ForEach(hunt.tasks ?? []) { task in
                             Marker(task.title, coordinate: CLLocationCoordinate2D(
                                latitude: task.latitude ?? 34.0522, 
                                longitude: task.longitude ?? -118.2437
                             ))
                                 .tint(isTaskCompleted(task) ? .gray : .blue)
                         }
                     }
                     .frame(height: 300)
                 }
                 .padding(.horizontal)
                
                Divider()

                // Tasks Section
                Section("Tasks") {
                    if let tasks = hunt.tasks?.sorted(by: { $0.order < $1.order }), !tasks.isEmpty {
                        ForEach(tasks) { task in
                            taskRow(task: task)
                            Divider()
                        }
                    } else {
                        Text("No tasks added yet.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                 .padding(.leading) // Indent section
            }
        }
        .navigationTitle(hunt.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showingTaskCompletionSheet) { task in
             // Pass the necessary environment objects if TaskCompletionView requires them
             TaskCompletionView(task: task)
                 .presentationDetents([.medium, .large])
         }
        .environment(LocationManager())
    }

    // Task Row View
    @ViewBuilder
    private func taskRow(task: Task) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(task.order). \(task.title)")
                    .font(.headline)
                    .strikethrough(isTaskCompleted(task), color: .secondary)
                Text(task.taskDescription ?? "No description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text("Points: \(task.points)")
                    .font(.caption)
            }

            Spacer()

            Button {
                if !isTaskCompleted(task) {
                    showingTaskCompletionSheet = task
                }
            } label: {
                Image(systemName: isTaskCompleted(task) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isTaskCompleted(task) ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(isTaskCompleted(task))
        }
        .padding(.vertical, 8)
        .padding(.trailing)
    }
    
    // Calculate total points
    private var totalPoints: Int {
        hunt.tasks?.reduce(0) { $0 + $1.points } ?? 0
    }
    
    // Calculate participant count
    private var participantCount: Int {
        guard let tasks = hunt.tasks else { return 0 }
        
        // Estimate participants based on unique user IDs in completions
        var uniqueUserIds = Set<String>()
        
        for task in tasks {
            if let completions = task.completions {
                for completion in completions {
                    uniqueUserIds.insert(completion.userId)
                }
            }
        }
        
        // If no completions, return a default of 0
        return uniqueUserIds.count
    }
    
    // Check if a task is completed (placeholder)
    private func isTaskCompleted(_ task: Task) -> Bool {
        // Use a different approach without complex predicates
        do {
            // Get all completions
            let fetchDescriptor = FetchDescriptor<TaskCompletion>()
            let allCompletions = try modelContext.fetch(fetchDescriptor)
            
            // Filter manually
            return allCompletions.contains { completion in 
                return completion.task?.id == task.id && completion.isVerified
            }
        } catch {
            print("Error checking task completion: \(error)")
            return false
        }
    }
}


#Preview {
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Hunt.self, Task.self, User.self, TaskCompletion.self, configurations: config)
        let context = container.mainContext

        let user = User(username: "PreviewUser", displayName: "PreviewUser")
        let hunt = Hunt(name: "Preview Hunt", huntDescription: "A hunt description", startTime: Date(), endTime: Date().addingTimeInterval(3600*2))
        hunt.creator = user
        context.insert(user)
        context.insert(hunt)
        
        let task1 = Task(title: "Task 1", taskDescription: "First task desc", points: 20, verificationMethod: .photo, latitude: 34.05, longitude: -118.25, radius: 50, order: 1)
        let task2 = Task(title: "Task 2", taskDescription: "Second task desc", points: 30, verificationMethod: .location, latitude: 34.055, longitude: -118.255, radius: 50, order: 2)
        task1.hunt = hunt
        task2.hunt = hunt
        context.insert(task1)
        context.insert(task2)
        
        let completion1 = TaskCompletion(task: task1, userId: user.id, completedAt: Date(), verificationMethod: .photo, isVerified: true)
        context.insert(completion1)
        
        return container // Return the container
    }()

    // Find the hunt in the container for the view
    let huntForView: Hunt? = {
        let descriptor = FetchDescriptor<Hunt>()
        return try? previewContainer.mainContext.fetch(descriptor).first
    }()

    // Return the View
    if let hunt = huntForView {
        NavigationStack {
            HuntDetailView(hunt: hunt)
                .modelContainer(previewContainer) // Use the prepared container
                .environment(NetworkMonitor())
                .environment(LocationManager())
        }
    } else {
        Text("Error creating preview hunt")
    }
} 