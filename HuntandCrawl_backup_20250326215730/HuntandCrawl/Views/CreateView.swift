import SwiftUI
import SwiftData
import PhotosUI

struct CreateView: View {
    @State private var selectedEventType: EventType = .hunt
    @State private var selectedTab = 0
    
    enum EventType: String, CaseIterable {
        case hunt = "Scavenger Hunt"
        case barCrawl = "Bar Crawl"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Event Type Picker
                Picker("Event Type", selection: $selectedEventType) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Divider()
                
                // Create Form
                TabView(selection: $selectedTab) {
                    CreateHuntView()
                        .tag(0)
                    
                    CreateBarCrawlView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: selectedEventType) { _, newValue in
                    selectedTab = newValue == .hunt ? 0 : 1
                }
                .onChange(of: selectedTab) { _, newValue in
                    selectedEventType = newValue == 0 ? .hunt : .barCrawl
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CreateHuntView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var maxParticipants: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600 * 2) // 2 hours later
    @State private var isPublic = false
    @State private var theme = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var coverImage: Data?
    @State private var isShowingTaskCreator = false
    @State private var tasks: [Task] = []
    @State private var isShowingSummary = false
    
    var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !location.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cover Image Selector
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let coverImage = coverImage, let uiImage = UIImage(data: coverImage) {
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
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                
                                Text("Add Cover Image")
                                    .font(.headline)
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
                .onChange(of: selectedPhoto) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            coverImage = data
                        }
                    }
                }
                
                // Basic Info Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Hunt Details")
                        .font(.headline)
                    
                    TextField("Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Location (Ship/Venue)", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Max Participants (Optional)", text: $maxParticipants)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    TextField("Theme (Optional)", text: $theme)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Toggle("Make Public", isOn: $isPublic)
                        .padding(.vertical, 4)
                }
                
                // Date and Time Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Schedule")
                        .font(.headline)
                    
                    DatePicker("Start Time", selection: $startDate)
                    
                    DatePicker("End Time", selection: $endDate)
                }
                
                // Tasks
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Tasks")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingTaskCreator = true
                        }) {
                            Label("Add Task", systemImage: "plus.circle")
                        }
                    }
                    
                    if tasks.isEmpty {
                        Text("No tasks added yet")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        ForEach(tasks.indices, id: \.self) { index in
                            HStack {
                                Image(systemName: tasks[index].type == .photo ? "camera.fill" : 
                                                  tasks[index].type == .location ? "mappin.circle.fill" : 
                                                  tasks[index].type == .question ? "questionmark.circle.fill" : 
                                                  tasks[index].type == .item ? "cube.fill" : "star.fill")
                                    .foregroundColor(.blue)
                                
                                Text(tasks[index].title)
                                
                                Spacer()
                                
                                Text("\(tasks[index].points) pts")
                                    .foregroundColor(.blue)
                                
                                Button(action: {
                                    tasks.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Save Button
                Button(action: {
                    createHunt()
                    isShowingSummary = true
                }) {
                    Text("Create Hunt")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $isShowingTaskCreator) {
            TaskCreatorView(onSave: { task in
                tasks.append(task)
            })
        }
        .alert("Hunt Created", isPresented: $isShowingSummary) {
            Button("OK", role: .cancel) {
                resetForm()
            }
        } message: {
            Text("Your hunt has been created successfully!")
        }
    }
    
    private func createHunt() {
        let hunt = Hunt(title: title, description: description, location: location, createdBy: UUID(), isPublic: isPublic)
        
        if let maxPart = Int(maxParticipants) {
            hunt.maxParticipants = maxPart
        }
        
        hunt.theme = theme.isEmpty ? nil : theme
        hunt.startTime = startDate
        hunt.endTime = endDate
        hunt.coverImage = coverImage
        hunt.tasks = tasks
        
        modelContext.insert(hunt)
    }
    
    private func resetForm() {
        title = ""
        description = ""
        location = ""
        maxParticipants = ""
        theme = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(3600 * 2)
        isPublic = false
        coverImage = nil
        selectedPhoto = nil
        tasks = []
    }
}

struct CreateBarCrawlView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var description = ""
    @State private var cruiseShip = ""
    @State private var maxParticipants: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600 * 3) // 3 hours later
    @State private var isPublic = false
    @State private var theme = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var coverImage: Data?
    @State private var isShowingStopCreator = false
    @State private var stops: [BarStop] = []
    @State private var isShowingSummary = false
    
    var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !cruiseShip.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cover Image Selector
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let coverImage = coverImage, let uiImage = UIImage(data: coverImage) {
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
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                
                                Text("Add Cover Image")
                                    .font(.headline)
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
                .onChange(of: selectedPhoto) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            coverImage = data
                        }
                    }
                }
                
                // Basic Info Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bar Crawl Details")
                        .font(.headline)
                    
                    TextField("Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Cruise Ship", text: $cruiseShip)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Max Participants (Optional)", text: $maxParticipants)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    TextField("Theme (Optional)", text: $theme)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Toggle("Make Public", isOn: $isPublic)
                        .padding(.vertical, 4)
                }
                
                // Date and Time Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Schedule")
                        .font(.headline)
                    
                    DatePicker("Start Time", selection: $startDate)
                    
                    DatePicker("End Time", selection: $endDate)
                }
                
                // Stops
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Bar Stops")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingStopCreator = true
                        }) {
                            Label("Add Stop", systemImage: "plus.circle")
                        }
                    }
                    
                    if stops.isEmpty {
                        Text("No stops added yet")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        ForEach(stops.sorted(by: { $0.order < $1.order })) { stop in
                            HStack {
                                Text("#\(stop.order)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Color.purple)
                                    .cornerRadius(15)
                                
                                VStack(alignment: .leading) {
                                    Text(stop.name)
                                        .font(.headline)
                                    
                                    Text(stop.location)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if let index = stops.firstIndex(where: { $0.id == stop.id }) {
                                        stops.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Save Button
                Button(action: {
                    createBarCrawl()
                    isShowingSummary = true
                }) {
                    Text("Create Bar Crawl")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $isShowingStopCreator) {
            BarStopCreatorView(onSave: { stop in
                stops.append(stop)
            }, nextOrder: stops.count + 1)
        }
        .alert("Bar Crawl Created", isPresented: $isShowingSummary) {
            Button("OK", role: .cancel) {
                resetForm()
            }
        } message: {
            Text("Your bar crawl has been created successfully!")
        }
    }
    
    private func createBarCrawl() {
        let barCrawl = BarCrawl(title: title, description: description, cruiseShip: cruiseShip, createdBy: UUID(), isPublic: isPublic)
        
        if let maxPart = Int(maxParticipants) {
            barCrawl.maxParticipants = maxPart
        }
        
        barCrawl.theme = theme.isEmpty ? nil : theme
        barCrawl.startTime = startDate
        barCrawl.endTime = endDate
        barCrawl.coverImage = coverImage
        barCrawl.stops = stops
        
        modelContext.insert(barCrawl)
    }
    
    private func resetForm() {
        title = ""
        description = ""
        cruiseShip = ""
        maxParticipants = ""
        theme = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(3600 * 3)
        isPublic = false
        coverImage = nil
        selectedPhoto = nil
        stops = []
    }
}

#Preview {
    CreateView()
        .modelContainer(for: [Hunt.self, BarCrawl.self, Task.self, BarStop.self], inMemory: true)
} 