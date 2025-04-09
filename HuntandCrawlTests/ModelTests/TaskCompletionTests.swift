import XCTest
import SwiftData
@testable import HuntandCrawl

class TaskCompletionTests: XCTestCase {
    var modelContainer: ModelContainer!
    
    override func setUpWithError() throws {
        // Set up an in-memory container for testing
        let schema = Schema([TaskCompletion.self, Task.self, Hunt.self, User.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDownWithError() throws {
        // Clean up
        modelContainer = nil
    }
    
    func testCreateTaskCompletion() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and task
        let user = User(name: "Alex", email: "alex@example.com")
        let hunt = Hunt(name: "City Explorer", huntDescription: "Explore the city", theme: "Urban")
        let task = Task(name: "Find the Statue", taskDescription: "Locate the famous statue", points: 10)
        task.hunt = hunt
        
        // Create a task completion
        let completion = TaskCompletion(
            task: task,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: false,
            verificationMethod: .photo
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task)
        context.insert(completion)
        
        // Fetch the task completion
        let descriptor = FetchDescriptor<TaskCompletion>()
        let completions = try context.fetch(descriptor)
        
        // Verify task completion was created
        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(completions.first?.userId, user.id)
        XCTAssertEqual(completions.first?.task?.name, "Find the Statue")
        XCTAssertEqual(completions.first?.hunt?.name, "City Explorer")
        XCTAssertEqual(completions.first?.verificationMethod, .photo)
        XCTAssertFalse(completions.first?.isVerified ?? true)
    }
    
    func testTaskCompletionVerification() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and task
        let user = User(name: "Jamie", email: "jamie@example.com")
        let hunt = Hunt(name: "Nature Hunt", huntDescription: "Hunt in the wilderness", theme: "Nature")
        let task = Task(name: "Find a Bird", taskDescription: "Spot and photograph a bird", points: 15)
        task.hunt = hunt
        
        // Create an unverified task completion
        let completion = TaskCompletion(
            task: task,
            hunt: hunt, 
            userId: user.id,
            completionTime: Date(),
            isVerified: false,
            verificationMethod: .photo
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task)
        context.insert(completion)
        
        // Verify the completion
        completion.isVerified = true
        completion.verificationTime = Date()
        
        // Fetch the task completion
        let descriptor = FetchDescriptor<TaskCompletion>()
        let completions = try context.fetch(descriptor)
        
        // Verify task completion was verified
        XCTAssertEqual(completions.count, 1)
        XCTAssertTrue(completions.first?.isVerified ?? false)
        XCTAssertNotNil(completions.first?.verificationTime)
    }
    
    func testTaskCompletionWithEvidenceData() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and task
        let user = User(name: "Morgan", email: "morgan@example.com")
        let hunt = Hunt(name: "Beach Hunt", huntDescription: "Hunt on the beach", theme: "Coastal")
        let task = Task(name: "Find a Shell", taskDescription: "Find a unique seashell", points: 5)
        task.hunt = hunt
        
        // Create photo evidence data
        let photoData = "photo_evidence".data(using: .utf8)
        
        // Create a task completion with evidence
        let completion = TaskCompletion(
            task: task,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: false,
            verificationMethod: .photo,
            evidenceData: photoData
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task)
        context.insert(completion)
        
        // Fetch the task completion
        let descriptor = FetchDescriptor<TaskCompletion>()
        let completions = try context.fetch(descriptor)
        
        // Verify evidence data was saved
        XCTAssertEqual(completions.count, 1)
        
        if let savedEvidence = completions.first?.evidenceData,
           let evidenceString = String(data: savedEvidence, encoding: .utf8) {
            XCTAssertEqual(evidenceString, "photo_evidence")
        } else {
            XCTFail("Evidence data could not be converted back to string")
        }
    }
    
    func testUpdateTaskCompletion() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and task
        let user = User(name: "Riley", email: "riley@example.com")
        let hunt = Hunt(name: "Historical Hunt", huntDescription: "Hunt for historical landmarks", theme: "Historical")
        let task = Task(name: "Find the Monument", taskDescription: "Locate the famous monument", points: 20)
        task.hunt = hunt
        
        // Create a task completion
        let completionTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let completion = TaskCompletion(
            task: task,
            hunt: hunt,
            userId: user.id,
            completionTime: completionTime,
            isVerified: false,
            verificationMethod: .manual
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task)
        context.insert(completion)
        
        // Update the completion
        let updatedTime = Date()
        completion.completionTime = updatedTime
        completion.isVerified = true
        completion.verificationMethod = .location
        completion.notes = "Found it near the entrance"
        completion.updatedAt = Date()
        
        // Fetch the task completion
        let descriptor = FetchDescriptor<TaskCompletion>()
        let completions = try context.fetch(descriptor)
        
        // Verify task completion was updated
        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(completions.first?.completionTime.timeIntervalSince1970, updatedTime.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertTrue(completions.first?.isVerified ?? false)
        XCTAssertEqual(completions.first?.verificationMethod, .location)
        XCTAssertEqual(completions.first?.notes, "Found it near the entrance")
    }
    
    func testDeleteTaskCompletion() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and task
        let user = User(name: "Casey", email: "casey@example.com")
        let hunt = Hunt(name: "Night Hunt", huntDescription: "Hunt after dark", theme: "Nocturnal")
        let task = Task(name: "Find a Star", taskDescription: "Identify a constellation", points: 25)
        task.hunt = hunt
        
        // Create a task completion
        let completion = TaskCompletion(
            task: task,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .question
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task)
        context.insert(completion)
        
        // Verify it was inserted
        var descriptor = FetchDescriptor<TaskCompletion>()
        var completions = try context.fetch(descriptor)
        XCTAssertEqual(completions.count, 1)
        
        // Delete the completion
        context.delete(completion)
        
        // Verify it was deleted
        descriptor = FetchDescriptor<TaskCompletion>()
        completions = try context.fetch(descriptor)
        XCTAssertEqual(completions.count, 0)
    }
    
    func testFilterTaskCompletionsByVerificationStatus() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and tasks
        let user = User(name: "Taylor", email: "taylor@example.com")
        let hunt = Hunt(name: "Museum Hunt", huntDescription: "Hunt in the museum", theme: "Cultural")
        
        let task1 = Task(name: "Find the Painting", taskDescription: "Locate the famous painting", points: 10)
        let task2 = Task(name: "Find the Sculpture", taskDescription: "Locate the marble sculpture", points: 15)
        let task3 = Task(name: "Find the Artifact", taskDescription: "Locate the ancient artifact", points: 20)
        
        task1.hunt = hunt
        task2.hunt = hunt
        task3.hunt = hunt
        
        // Create task completions with different verification statuses
        let completion1 = TaskCompletion(
            task: task1,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .location
        )
        
        let completion2 = TaskCompletion(
            task: task2,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: false,
            verificationMethod: .photo
        )
        
        let completion3 = TaskCompletion(
            task: task3,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .manual
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        context.insert(completion1)
        context.insert(completion2)
        context.insert(completion3)
        
        // Filter for verified completions
        let verifiedDescriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.isVerified == true
            }
        )
        
        let verifiedCompletions = try context.fetch(verifiedDescriptor)
        
        // Filter for unverified completions
        let unverifiedDescriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.isVerified == false
            }
        )
        
        let unverifiedCompletions = try context.fetch(unverifiedDescriptor)
        
        // Verify filtering works
        XCTAssertEqual(verifiedCompletions.count, 2)
        XCTAssertEqual(unverifiedCompletions.count, 1)
        
        // Verify correct items in each group
        let verifiedTaskNames = verifiedCompletions.compactMap { $0.task?.name }
        XCTAssertTrue(verifiedTaskNames.contains("Find the Painting"))
        XCTAssertTrue(verifiedTaskNames.contains("Find the Artifact"))
        
        let unverifiedTaskNames = unverifiedCompletions.compactMap { $0.task?.name }
        XCTAssertTrue(unverifiedTaskNames.contains("Find the Sculpture"))
    }
    
    func testFilterTaskCompletionsByVerificationMethod() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and tasks
        let user = User(name: "Jordan", email: "jordan@example.com")
        let hunt = Hunt(name: "City Landmarks", huntDescription: "Find famous landmarks", theme: "Urban")
        
        let task1 = Task(name: "Find the Tower", taskDescription: "Locate the clock tower", points: 10)
        let task2 = Task(name: "Find the Fountain", taskDescription: "Locate the central fountain", points: 15)
        let task3 = Task(name: "Find the Statue", taskDescription: "Locate the bronze statue", points: 20)
        let task4 = Task(name: "Find the Bridge", taskDescription: "Locate the stone bridge", points: 25)
        
        task1.hunt = hunt
        task2.hunt = hunt
        task3.hunt = hunt
        task4.hunt = hunt
        
        // Create task completions with different verification methods
        let completion1 = TaskCompletion(
            task: task1,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .location
        )
        
        let completion2 = TaskCompletion(
            task: task2,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .photo
        )
        
        let completion3 = TaskCompletion(
            task: task3,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .question
        )
        
        let completion4 = TaskCompletion(
            task: task4,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .manual
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        context.insert(task4)
        context.insert(completion1)
        context.insert(completion2)
        context.insert(completion3)
        context.insert(completion4)
        
        // Filter for location-verified completions
        let locationDescriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.verificationMethod == .location
            }
        )
        
        let locationCompletions = try context.fetch(locationDescriptor)
        
        // Filter for photo-verified completions
        let photoDescriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.verificationMethod == .photo
            }
        )
        
        let photoCompletions = try context.fetch(photoDescriptor)
        
        // Filter for question-verified completions
        let questionDescriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.verificationMethod == .question
            }
        )
        
        let questionCompletions = try context.fetch(questionDescriptor)
        
        // Filter for manually-verified completions
        let manualDescriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.verificationMethod == .manual
            }
        )
        
        let manualCompletions = try context.fetch(manualDescriptor)
        
        // Verify filtering works
        XCTAssertEqual(locationCompletions.count, 1)
        XCTAssertEqual(photoCompletions.count, 1)
        XCTAssertEqual(questionCompletions.count, 1)
        XCTAssertEqual(manualCompletions.count, 1)
        
        // Verify correct items in each group
        XCTAssertEqual(locationCompletions.first?.task?.name, "Find the Tower")
        XCTAssertEqual(photoCompletions.first?.task?.name, "Find the Fountain")
        XCTAssertEqual(questionCompletions.first?.task?.name, "Find the Statue")
        XCTAssertEqual(manualCompletions.first?.task?.name, "Find the Bridge")
    }
    
    func testFilterTaskCompletionsByUser() throws {
        let context = modelContainer.mainContext
        
        // Create users, hunt, and task
        let user1 = User(name: "Sam", email: "sam@example.com")
        let user2 = User(name: "Drew", email: "drew@example.com")
        
        let hunt = Hunt(name: "Park Adventure", huntDescription: "Explore the park", theme: "Nature")
        let task = Task(name: "Find the Oak Tree", taskDescription: "Locate the ancient oak tree", points: 15)
        task.hunt = hunt
        
        // Create task completions for different users
        let completion1 = TaskCompletion(
            task: task,
            hunt: hunt,
            userId: user1.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .location
        )
        
        let completion2 = TaskCompletion(
            task: task,
            hunt: hunt,
            userId: user2.id,
            completionTime: Date(),
            isVerified: true,
            verificationMethod: .photo
        )
        
        // Insert into context
        context.insert(user1)
        context.insert(user2)
        context.insert(hunt)
        context.insert(task)
        context.insert(completion1)
        context.insert(completion2)
        
        // Filter for user1's completions
        let user1Descriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.userId == user1.id
            }
        )
        
        let user1Completions = try context.fetch(user1Descriptor)
        
        // Filter for user2's completions
        let user2Descriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.userId == user2.id
            }
        )
        
        let user2Completions = try context.fetch(user2Descriptor)
        
        // Verify filtering works
        XCTAssertEqual(user1Completions.count, 1)
        XCTAssertEqual(user2Completions.count, 1)
        
        // Verify correct user IDs
        XCTAssertEqual(user1Completions.first?.userId, user1.id)
        XCTAssertEqual(user2Completions.first?.userId, user2.id)
    }
    
    func testTaskCompletionPointsCalculation() throws {
        let context = modelContainer.mainContext
        
        // Create a user, hunt, and tasks with different point values
        let user = User(name: "Alex", email: "alex@example.com")
        let hunt = Hunt(name: "City Explorer", huntDescription: "Explore the city", theme: "Urban")
        
        let task1 = Task(name: "Easy Task", taskDescription: "An easy task", points: 5)
        let task2 = Task(name: "Medium Task", taskDescription: "A medium task", points: 10)
        let task3 = Task(name: "Hard Task", taskDescription: "A hard task", points: 20)
        
        task1.hunt = hunt
        task2.hunt = hunt
        task3.hunt = hunt
        
        // Create task completions
        let completion1 = TaskCompletion(
            task: task1,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true
        )
        
        let completion2 = TaskCompletion(
            task: task2,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true
        )
        
        let completion3 = TaskCompletion(
            task: task3,
            hunt: hunt,
            userId: user.id,
            completionTime: Date(),
            isVerified: true
        )
        
        // Insert into context
        context.insert(user)
        context.insert(hunt)
        context.insert(task1)
        context.insert(task2)
        context.insert(task3)
        context.insert(completion1)
        context.insert(completion2)
        context.insert(completion3)
        
        // Fetch all completions
        let descriptor = FetchDescriptor<TaskCompletion>(
            predicate: #Predicate { completion in
                completion.userId == user.id && completion.isVerified
            }
        )
        
        let completions = try context.fetch(descriptor)
        
        // Calculate total points
        let totalPoints = completions.reduce(0) { sum, completion in
            sum + (completion.task?.points ?? 0)
        }
        
        // Verify total points calculation
        XCTAssertEqual(totalPoints, 35) // 5 + 10 + 20
    }
} 