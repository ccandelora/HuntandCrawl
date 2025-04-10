import SwiftUI
import SwiftData
import MapKit
import Combine

// Define the TaskAnnotation struct
struct TaskAnnotation: Identifiable {
    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D
    let isCompleted: Bool
}

struct HuntDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingTaskCompletionSheet: HuntTask? = nil
    @State private var showingNewTaskSheet = false
    @State private var selectedTask: HuntTask? = nil
    @State private var isDeleting = false
    @State private var showingDeleteConfirmation = false
    @State private var mapRegion = MKCoordinateRegion()
    @State private var taskLocations: [TaskAnnotation] = []
    @Environment(NetworkMonitor.self) var networkMonitor
    @Environment(LocationManager.self) var locationManager
    
    @Query private var tasks: [HuntTask]
    
    let hunt: Hunt
    
    init(hunt: Hunt) {
        self.hunt = hunt
        
        // For SwiftData 1.0, we need a simpler predicate
        // Load all tasks and filter manually for now
        self._tasks = Query()
    }
    
    // Filter tasks to just those for this hunt
    var filteredTasks: [HuntTask] {
        tasks.filter { $0.hunt?.id == hunt.id }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text(hunt.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if let description = hunt.huntDescription, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Hunt Status Badge
                HStack {
                    if hunt.isCompleted {
                        Text("Completed")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else if hunt.isActive {
                        Text("Active")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("Upcoming")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal)
            
            // Offline Warning Banner
            if !networkMonitor.isConnected {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.white)
                    Text("You're offline. Task completions will sync later.")
                        .font(.footnote)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange)
            }
            
            List {
                // Map Section
                Section("Task Locations") {
                    HStack {
                        Spacer()
                        Map(coordinateRegion: $mapRegion, annotationItems: taskLocations) { location in
                            MapAnnotation(coordinate: location.coordinate) {
                                Image(systemName: location.isCompleted ? "checkmark.circle.fill" : "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(location.isCompleted ? .green : .red)
                                    .shadow(radius: 2)
                            }
                        }
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.vertical, 8)
                        Spacer()
                    }
                }
                
                // Ship Location Section - replaces Map Section
                Section("Task Locations") {
                    if filteredTasks.isEmpty {
                        Text("No task locations available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(filteredTasks.filter { $0.hasLocation }) { task in
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(task.isCompleted ? .green : .blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.headline)
                                    
                                    Text(task.locationDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if task.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Tasks Section
                Section("Tasks") {
                    if filteredTasks.isEmpty {
                        Text("No tasks available for this hunt.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(filteredTasks) { task in
                            taskRow(task: task)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingNewTaskSheet = true
                }) {
                    Label("Add Task", systemImage: "plus")
                }
            }
        }
        .sheet(item: $showingTaskCompletionSheet) { task in
            TaskCompletionView(task: task)
        }
        .sheet(isPresented: $showingNewTaskSheet) {
            TaskCreatorView(hunt: hunt)
        }
        .confirmationDialog(
            "Are you sure you want to delete this task?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let task = selectedTask {
                    deleteTask(task)
                }
            }
            Button("Cancel", role: .cancel) {
                selectedTask = nil
            }
        }
        .onAppear {
            updateMapRegion()
            updateTaskLocations()
        }
        .onChange(of: tasks) { _, _ in
            updateMapRegion()
            updateTaskLocations()
        }
        .onChange(of: hunt.id) { _, _ in
            updateMapRegion()
            updateTaskLocations()
        }
    }
    
    // MARK: - Task Row View
    
    private func taskRow(task: HuntTask) -> some View {
        ZStack {
            NavigationLink(destination: TaskDetailView(task: task)) {
                EmptyView()
            }
            .opacity(0)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let subtitle = task.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        // Points Badge
                        Text("\(task.points) pts")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        // Verification Method
                        Text(task.verificationMethod)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                Spacer()
                
                // Completion Status
                if isTaskCompleted(task) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Button(action: {
                        showingTaskCompletionSheet = task
                    }) {
                        Text("Complete")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button(action: {
                    selectedTask = task
                    showingDeleteConfirmation = true
                }) {
                    Label("Delete Task", systemImage: "trash")
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helper Functions
    
    private func isTaskCompleted(_ task: HuntTask) -> Bool {
        return task.isCompleted
    }
    
    private func deleteTask(_ task: HuntTask) {
        hunt.tasks?.removeAll(where: { $0.id == task.id })
        modelContext.delete(task)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
    
    private func updateMapRegion() {
        // Set a default region centered on the user's location
        if let userLocation = locationManager.state.userLocation {
            mapRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        } else {
            // Fallback to a default location
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }
    
    private func updateTaskLocations() {
        // Tasks no longer have direct latitude/longitude coordinates
        // We're using a deck-based location system now
        taskLocations = []
    }
}


#Preview {
    // Create a SwiftData preview container
    let container: ModelContainer = {
        let schema = Schema([
            Hunt.self,
            HuntTask.self,
            TaskCompletion.self,
            Team.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        // Create sample data
        let context = container.mainContext
        
        // Create a hunt
        let hunt = Hunt(
            name: "Downtown Adventure",
            huntDescription: "Explore downtown and discover hidden gems!",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600 * 24),
            isActive: true,
            creatorId: "user123"
        )
        
        // Add some tasks
        let task1 = HuntTask(
            title: "Visit Central Park",
            taskDescription: "Find the fountain in the center of the park",
            points: 100,
            verificationMethod: .photo,
            deckNumber: 5,
            locationOnShip: "Central Park area",
            section: "Midship",
            order: 1
        )
        
        let task2 = HuntTask(
            title: "Coffee Challenge",
            taskDescription: "Order the most complex coffee drink at the local cafe",
            points: 150,
            verificationMethod: .photo,
            deckNumber: 4,
            locationOnShip: "Cafe Promenade",
            section: "Forward",
            order: 2
        )
        
        let task3 = HuntTask(
            title: "History Quiz",
            taskDescription: "Answer questions about the city's history",
            points: 75,
            verificationMethod: .question,
            question: "What year was this ship launched?",
            answer: "2009",
            order: 3
        )
        
        hunt.tasks = [task1, task2, task3]
        context.insert(hunt)
        
        try? context.save()
        
        return container
    }()

    // Find the hunt in the container for the view
    let huntForView: Hunt? = {
        let descriptor = FetchDescriptor<Hunt>()
        return try? container.mainContext.fetch(descriptor).first
    }()

    // Use Group instead of explicit return
    Group {
        if let hunt = huntForView {
            NavigationStack {
                HuntDetailView(hunt: hunt)
                    .modelContainer(container)
                    .environment(NetworkMonitor())
                    .environment(LocationManager())
            }
        } else {
            Text("Error creating preview hunt")
        }
    }
} 