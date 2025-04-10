import SwiftUI
import SwiftData
import PhotosUI
import CoreLocation
import _Concurrency

// Simple class with a callback approach
class TaskPhotoLoader {
    func loadPhoto(from item: PhotosPickerItem, completion: @escaping (Data?) -> Void) {
        // Use callback API directly
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                completion(data)
            case .failure:
                completion(nil)
            }
        }
    }
}

// Define our own PhotoProcessor class here to make the above code valid
fileprivate class PhotoProcessor {
    func process(item: PhotosPickerItem, completion: @escaping (Data?) -> Void) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                completion(data)
            case .failure:
                completion(nil)
            }
        }
    }
}

struct TaskCompletionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(LocationManager.self) private var locationManager

    let task: HuntTask
    @State private var completion: TaskCompletion? // Store the fetched/created completion

    // State for evidence
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var evidenceImageData: Data? = nil
    @State private var typedAnswer: String = ""
    @State private var showingLocationVerification = false
    @State private var verificationStatusMessage: String? = nil
    @State private var isSaving = false
    @State private var alreadyCompletedMessage: String? = nil

    // Add these state variables
    @State private var currentDeck: Int = 1
    @State private var currentLocation: String = ""
    @State private var currentSection: String = ""

    private let photoLoader = TaskPhotoLoader()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let message = alreadyCompletedMessage {
                    Text(message)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                if let message = verificationStatusMessage {
                    Text(message)
                        .foregroundColor(message.contains("Error") ? .red : .primary)
                        .padding()
                        .background(message.contains("Error") ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Task Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(task.points) points")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    if let description = task.taskDescription {
                        Text(description)
                            .padding(.top, 4)
                    }
                }
                .padding()
                
                Divider()
                    .padding(.horizontal)
                
                // Verification Method
                completionMethodView
                    .padding()
            }
        }
        .navigationTitle("Complete Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if alreadyCompletedMessage == nil { // Only show Save if not already completed
                    Button("Save Completion") {
                         saveCompletion()
                    }
                    .disabled(isSaveButtonDisabled() || isSaving)
                }
            }
        }
        .onAppear(perform: loadOrCreateCompletion)
        .onChange(of: selectedPhotoItem) { // Corrected onChange usage
             if let photoItem = selectedPhotoItem {
                 photoLoader.loadPhoto(from: photoItem) { data in
                     if let data = data {
                         evidenceImageData = data
                         // Immediately try to save if photo is the only requirement
                         if task.verificationMethod == VerificationMethod.photo.rawValue {
                             saveCompletion()
                         }
                     }
                 }
             }
         }
    }

    @ViewBuilder
    private var completionMethodView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verification Method: \(task.verificationMethod.capitalized)")
                .font(.headline)

            if isPhotoVerification {
                photoEvidenceView
            } else if isLocationVerification {
                locationEvidenceView
            } else if isQuestionVerification {
                questionEvidenceView
            } else {
                 Text("This task requires manual verification by an organizer.")
                 Button("Mark as Ready for Review") { saveCompletion(isVerified: false) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var photoEvidenceView: some View {
        VStack {
            if let imageData = evidenceImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                Button("Change Photo") {
                    selectedPhotoItem = nil // Allow re-selection
                    evidenceImageData = nil
                }
                .padding(.top, 5)
            } else {
                 PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                     Label("Upload Photo Evidence", systemImage: "camera")
                 }
                 .buttonStyle(.bordered)
                 .padding(.top)
            }
        }
    }

    @ViewBuilder
    private var locationEvidenceView: some View {
        VStack(alignment: .leading) {
            if let proximityRange = task.proximityRange {
                Text("You need to be at: \(task.locationDescription)")
                
                if let deckNumber = task.deckNumber, 
                   let locationOnShip = task.locationOnShip {
                    Text("Verify your location by selecting the correct deck and location:")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Current deck selection
                        Picker("Current Deck", selection: $currentDeck) {
                            ForEach(1...20, id: \.self) { deck in
                                Text("Deck \(deck)").tag(deck)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        // Current location input
                        TextField("Current Location (e.g., Main Dining)", text: $currentLocation)
                            .textFieldStyle(.roundedBorder)
                        
                        // Current section selection
                        Picker("Section", selection: $currentSection) {
                            Text("Forward").tag("Forward")
                            Text("Midship").tag("Midship")
                            Text("Aft").tag("Aft")
                            Text("Not specified").tag("")
                        }
                        .pickerStyle(.segmented)
                        
                        Button("Verify Location Now") {
                            verifyLocation()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                } else {
                    Text("Error: Task location not properly configured.")
                        .foregroundColor(.red)
                }
            } else {
                Text("Location details not available for this task.")
                    .foregroundColor(.orange)
            }
        }
    }

    @ViewBuilder
    private var questionEvidenceView: some View {
        VStack(alignment: .leading) {
            if let question = task.question, !question.isEmpty {
                Text("Question: \(question)")
                TextField("Your Answer", text: $typedAnswer)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                 Button("Submit Answer") {
                     verifyAnswer()
                 }
                 .buttonStyle(.borderedProminent)
                 .disabled(typedAnswer.isEmpty)
                 .padding(.top)
            } else {
                Text("Error: No question found for this task.")
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Logic

    private func loadOrCreateCompletion() {
        // Find current user - in a real app, you'd get this from UserManager or similar
        let currentUserId = "currentUser" // Replace with actual user ID or fetch from user service
        
        // Use a simpler approach without complex predicates
        do {
            // Get all completions
            let fetchDescriptor = FetchDescriptor<TaskCompletion>()
            let allCompletions = try modelContext.fetch(fetchDescriptor)
            
            // Filter manually
            if let existingCompletion = allCompletions.first(where: { 
                $0.task?.id == task.id && $0.userId == currentUserId
            }) {
                self.completion = existingCompletion
                // Check if already verified to show message
                if existingCompletion.isVerified {
                    if let completedDate = existingCompletion.completedAt {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        let dateString = formatter.string(from: completedDate)
                        alreadyCompletedMessage = "You have already successfully completed this task on \(dateString)."
                    } else {
                        alreadyCompletedMessage = "You have already successfully completed this task."
                    }
                } else {
                    // Populate state if verification was attempted but not finalized
                    self.evidenceImageData = existingCompletion.evidenceData
                    self.typedAnswer = existingCompletion.answer ?? ""
                }
            } else {
                // Create a new completion instance but don't insert yet
                let verificationMethodEnum = getVerificationMethodEnum(from: task.verificationMethod)
                
                self.completion = TaskCompletion(
                    task: task,
                    userId: currentUserId,
                    completedAt: Date(),
                    verificationMethod: verificationMethodEnum,
                    isVerified: false
                )
            }
        } catch {
            print("Error fetching TaskCompletion: \(error)")
            verificationStatusMessage = "Error loading completion status."
            // Create a new one if fetching fails
            let verificationMethodEnum = getVerificationMethodEnum(from: task.verificationMethod)
            
            self.completion = TaskCompletion(
                task: task,
                userId: currentUserId,
                completedAt: Date(),
                verificationMethod: verificationMethodEnum,
                isVerified: false
            )
        }
    }
    
    // Helper function to convert from String to VerificationMethod enum
    private func getVerificationMethodEnum(from string: String) -> VerificationMethod {
        switch string {
        case VerificationMethod.photo.rawValue:
            return .photo
        case VerificationMethod.location.rawValue:
            return .location
        case VerificationMethod.question.rawValue:
            return .question
        default:
            return .manual
        }
    }

    private func verifyLocation() {
        guard let taskDeck = task.deckNumber,
              let taskLocation = task.locationOnShip,
              let proximityRange = task.proximityRange else {
            verificationStatusMessage = "Error: Task location not set correctly."
            return
        }
        
        // Basic match logic - we can expand this to be more flexible
        let deckMatch = currentDeck == taskDeck
        
        // Simple fuzzy match for location (contains)
        let locationMatch = currentLocation.lowercased().contains(taskLocation.lowercased()) || 
                            taskLocation.lowercased().contains(currentLocation.lowercased())
        
        // Optional section match
        let sectionMatch = task.section == nil || 
                          task.section?.isEmpty == true || 
                          currentSection == task.section
        
        if deckMatch && locationMatch && sectionMatch {
            // Success - verify the task
            saveCompletion(isVerified: true)
        } else {
            // Failed verification
            if !deckMatch {
                verificationStatusMessage = "Wrong deck. Please verify you're on deck \(taskDeck)."
            } else if !locationMatch {
                verificationStatusMessage = "Location doesn't match. Please check you're at \(taskLocation)."
            } else if !sectionMatch {
                verificationStatusMessage = "Wrong section. The task is in the \(task.section ?? "unknown") section."
            } else {
                verificationStatusMessage = "Location verification failed. Please try again."
            }
        }
    }

    private func verifyAnswer() {
        guard let correctAnswer = task.answer else {
            verificationStatusMessage = "Error: No answer defined for this task."
            return
        }
        
        // Case-insensitive comparison
        if typedAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
           correctAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
            saveCompletion(isVerified: true)
        } else {
            verificationStatusMessage = "Incorrect answer. Please try again."
        }
    }

    private func isSaveButtonDisabled() -> Bool {
        if isPhotoVerification {
            return evidenceImageData == nil
        } else if isLocationVerification {
            // Location verification is done through the Verify button
            return false
        } else if isQuestionVerification {
            return typedAnswer.isEmpty
        } else {
            // Manual verification just needs to be submitted
            return false
        }
    }

    private func saveCompletion(isVerified: Bool = true) {
        isSaving = true
        // Create or update the completion
        if completion == nil {
            completion = TaskCompletion(
                task: task,
                userId: "currentUser", // Replace with actual user ID
                completedAt: Date(),
                isVerified: false // Will be set based on verification
            )
            
            // Add evidence based on verification method
            if isPhotoVerification {
                completion?.evidenceData = evidenceImageData
            } else if isQuestionVerification {
                completion?.answer = typedAnswer
            }
            
            // Set verified state based on method and evidence
            if let comp = completion {
                // If auto-verified by the system
                if isVerified {
                    comp.isVerified = true
                    comp.verifiedAt = Date()
                    verificationStatusMessage = "Success! Task completed and verified."
                } else {
                    verificationStatusMessage = "Task completion recorded. Awaiting verification."
                }
                
                modelContext.insert(comp)
                try? modelContext.save()
            }
        } else if let comp = completion {
            // Update existing completion
            if isPhotoVerification {
                comp.evidenceData = evidenceImageData
            } else if isQuestionVerification {
                comp.answer = typedAnswer
            }
            
            if isVerified && !comp.isVerified {
                comp.isVerified = true
                comp.verifiedAt = Date()
                verificationStatusMessage = "Success! Task completed and verified."
            }
            
            try? modelContext.save()
        }
        
        // Auto dismiss after short delay for feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
        
        isSaving = false
    }

    // Helper computed properties for verification types
    private var isPhotoVerification: Bool {
        return task.verificationMethod == VerificationMethod.photo.rawValue
    }
    
    private var isLocationVerification: Bool {
        return task.verificationMethod == VerificationMethod.location.rawValue
    }
    
    private var isQuestionVerification: Bool {
        return task.verificationMethod == VerificationMethod.question.rawValue
    }
    
    private var isManualVerification: Bool {
        return task.verificationMethod == VerificationMethod.manual.rawValue
    }
}

#Preview {
    NavigationStack {
        TaskCompletionView(task: HuntTask(
            title: "Sample Task",
            points: 10,
            verificationMethod: .photo
        ))
        .modelContainer(PreviewContainer.previewContainer)
        .environment(LocationManager())
    }
} 