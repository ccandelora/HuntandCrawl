import SwiftUI
import SwiftData
import MapKit // For map selection
import PhotosUI // For optional image upload
import _Concurrency
import CoreLocation

// Define the TaskVerificationMethod enum
enum TaskVerificationMethod: String, CaseIterable, Identifiable {
    case photo = "photo"
    case location = "location"
    case question = "question" 
    case manual = "manual"
    
    var id: String { self.rawValue }
}

// Define a helper class for photo loading
fileprivate class TaskCreatorPhotoLoader {
    func loadPhoto(from item: PhotosPickerItem, completion: @escaping (Data?) -> Void) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    completion(data)
                case .failure:
                    completion(nil)
                }
            }
        }
    }
}

struct TaskCreatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocationManager.self) private var locationManager
    
    // Task Properties
    @State private var name: String = "" // Changed from title
    @State private var descriptionText: String = "" 
    @State private var instructions: String = "" 
    @State private var points: Int = 10
    @State private var verificationMethod: TaskVerificationMethod = .photo
    @State private var radius: Double = 50 // Default radius for location tasks
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var hint: String = ""
    @State private var order: Int = 1
    
    // Location Selection
    @State private var selectedLocation: CLLocationCoordinate2D? = nil
    @State private var showingMapSheet = false

    // Photo Upload (Optional Image for Task, not for evidence)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var taskImageData: Data? = nil
    
    // Hunt association
    let hunt: Hunt // Passed in
    
    init(hunt: Hunt) {
        self.hunt = hunt
        // Initialize order based on existing tasks
        let maxOrder = hunt.tasks?.map { $0.order }.max() ?? 0
        self._order = State(initialValue: maxOrder + 1)
    }

    var isFormValid: Bool {
        !name.isEmpty && (
            verificationMethod != .location || selectedLocation != nil
        )
        // Add other checks, e.g., question/answer for question type
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Task Name", text: $name) // Changed label
                    TextField("Description", text: $descriptionText, axis: .vertical)
                    TextField("Instructions", text: $instructions, axis: .vertical)
                    Stepper("Points: \(points)", value: $points, in: 5...100, step: 5)
                    Stepper("Order in Hunt: \(order)", value: $order, in: 1...100)
                }
                
                Section("Verification") {
                    Picker("Method", selection: $verificationMethod) {
                        ForEach(TaskVerificationMethod.allCases) { method in
                            Text(method.rawValue.capitalized).tag(method)
                        }
                    }
                    
                    if verificationMethod == .location {
                        HStack {
                            Text("Radius (meters)")
                            Spacer()
                            TextField("50", value: $radius, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 80)
                        }
                        if let location = selectedLocation {
                            Text("Lat: \(location.latitude, specifier: "%.4f"), Lon: \(location.longitude, specifier: "%.4f")")
                        }
                        Button(selectedLocation == nil ? "Select Location" : "Change Location") {
                            showingMapSheet = true
                        }
                    } else if verificationMethod == .question {
                        TextField("Question", text: $question, axis: .vertical)
                        TextField("Correct Answer", text: $answer)
                    }
                }
                
                Section("Optional Details") {
                    TextField("Hint (Optional)", text: $hint, axis: .vertical)
                    // Optional Task Image Section
                     PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) { // Added library
                         Label(taskImageData == nil ? "Add Task Image" : "Change Image", systemImage: "photo")
                     }
                     if let imageData = taskImageData, let uiImage = UIImage(data: imageData) {
                         Image(uiImage: uiImage)
                             .resizable()
                             .scaledToFit()
                             .frame(maxHeight: 200)
                             .cornerRadius(8)
                     }
                }
            }
            .navigationTitle("Add New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveTask() }
                        .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingMapSheet) {
                LocationPicker(selectedCoordinate: $selectedLocation)
            }
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                 if let item = newValue {
                     let loader = TaskCreatorPhotoLoader()
                     loader.loadPhoto(from: item) { data in
                         if let data = data {
                             self.taskImageData = data
                         }
                     }
                 }
             }
        }
    }
    
    private func saveTask() {
        let latitude = verificationMethod == .location ? selectedLocation?.latitude : nil
        let longitude = verificationMethod == .location ? selectedLocation?.longitude : nil
        
        let newTask = Task(
            title: name,
            subtitle: nil,
            taskDescription: descriptionText.isEmpty ? nil : descriptionText,
            points: points,
            verificationMethod: mapVerificationMethod(verificationMethod),
            latitude: latitude,
            longitude: longitude,
            radius: verificationMethod == .location ? radius : nil,
            question: verificationMethod == .question ? question : nil,
            answer: verificationMethod == .question ? answer : nil,
            order: order
        )
        
        // Set hunt relationship
        newTask.hunt = hunt
        
        // Set other properties if they exist in your model
        // newTask.instructions = instructions.isEmpty ? nil : instructions
        // newTask.hint = hint.isEmpty ? nil : hint
        // newTask.taskImageData = self.taskImageData
        
        modelContext.insert(newTask)
        
        do {
            try modelContext.save()
            print("Task saved successfully!")
            dismiss()
        } catch {
            print("Failed to save task: \(error)")
            // Handle error
        }
    }
    
    // Helper method to convert app's TaskVerificationMethod to model's VerificationMethod
    private func mapVerificationMethod(_ method: TaskVerificationMethod) -> VerificationMethod {
        switch method {
        case .photo:
            return .photo
        case .location:
            return .location
        case .question:
            return .question
        case .manual:
            return .manual
        }
    }
}

// Simple Location Picker View (Needs to be implemented or use an existing one)
struct LocationPicker: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss
    
    // Default region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedMapItem: MKMapItem? = nil
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MapReader { reader in
                    Map(initialPosition: .region(region)) {
                        // Optional: Show existing bar stops from the crawl?
                        // Add marker for selection
                        if let coord = selectedCoordinate {
                             Marker("Selected Location", coordinate: coord)
                        }
                    }
                    .onTapGesture { screenCoord in
                        let mapCoord = reader.convert(screenCoord, from: .local)
                        if let mapCoord = mapCoord {
                            selectedCoordinate = mapCoord
                            selectedMapItem = MKMapItem(placemark: MKPlacemark(coordinate: mapCoord))
                        }
                    }
                }
                
                if let item = selectedMapItem {
                    VStack {
                        Text(item.name ?? "Selected Location")
                        Text("Lat: \(item.placemark.coordinate.latitude, specifier: "%.4f"), Lon: \(item.placemark.coordinate.longitude, specifier: "%.4f")")
                            .font(.caption)
                        Button("Confirm Location") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .padding()
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(10)
                    .padding()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button("Cancel") { selectedCoordinate = nil; dismiss() } // Clear selection on cancel
                 }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .disabled(selectedCoordinate == nil)
                }
            }
        }
    }
}

#Preview {
    let previewContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Task.self, Hunt.self, configurations: config)
        let context = container.mainContext
        let user = User(username: "Preview", displayName: "Preview")
        let hunt = Hunt(name: "Preview Hunt", huntDescription: "Desc", startTime: Date(), endTime: Date())
        context.insert(user)
        context.insert(hunt)
        return container
    }()

    // Find the hunt in the container for the view
    let huntForView: Hunt? = {
        let descriptor = FetchDescriptor<Hunt>()
        return try? previewContainer.mainContext.fetch(descriptor).first
    }()

    // Return the View
    if let hunt = huntForView {
        NavigationStack {
            TaskCreatorView(hunt: hunt)
                .modelContainer(previewContainer)
                .environment(LocationManager()) // Provide mock manager
        }
    } else {
        Text("Error creating preview hunt")
    }
} 