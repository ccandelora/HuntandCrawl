import XCTest
import SwiftData
@testable import HuntandCrawl

final class HuntModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Set up an in-memory SwiftData container for testing
        let schema = Schema([
            Hunt.self,
            Task.self,
            User.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        // Clear any test data
        try modelContext.delete(model: Hunt.self)
        try modelContext.delete(model: Task.self)
        try modelContext.delete(model: User.self)
        modelContainer = nil
        modelContext = nil
    }
    
    func testCreateHunt() throws {
        // Create a new hunt
        let hunt = Hunt(title: "Test Hunt", description: "Test Description", location: "Test Location")
        modelContext.insert(hunt)
        
        // Try to save and verify no errors
        XCTAssertNoThrow(try modelContext.save())
        
        // Fetch the hunt and verify properties
        let descriptor = FetchDescriptor<Hunt>(predicate: #Predicate { $0.title == "Test Hunt" })
        let hunts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(hunts.count, 1)
        XCTAssertEqual(hunts.first?.title, "Test Hunt")
        XCTAssertEqual(hunts.first?.description, "Test Description")
        XCTAssertEqual(hunts.first?.location, "Test Location")
    }
    
    func testHuntWithTasks() throws {
        // Create a hunt with tasks
        let hunt = Hunt(title: "Hunt with Tasks", description: "Hunt with multiple tasks", location: "Ship Deck")
        
        // Add tasks to the hunt
        let task1 = Task(title: "Task 1", description: "First task", points: 10, latitude: 25.0, longitude: -80.0)
        let task2 = Task(title: "Task 2", description: "Second task", points: 20, latitude: 25.1, longitude: -80.1)
        
        hunt.tasks = [task1, task2]
        
        // Save to context
        modelContext.insert(hunt)
        XCTAssertNoThrow(try modelContext.save())
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Hunt>(predicate: #Predicate { $0.title == "Hunt with Tasks" })
        let hunts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(hunts.count, 1)
        XCTAssertEqual(hunts.first?.tasks?.count, 2)
        
        let tasks = hunts.first?.tasks?.sorted { $0.title < $1.title }
        XCTAssertEqual(tasks?.first?.title, "Task 1")
        XCTAssertEqual(tasks?.last?.title, "Task 2")
        XCTAssertEqual(tasks?.first?.points, 10)
        XCTAssertEqual(tasks?.last?.points, 20)
    }
    
    func testDeleteHunt() throws {
        // Create and save a hunt
        let hunt = Hunt(title: "Delete Test", description: "To be deleted", location: "Ship")
        modelContext.insert(hunt)
        try modelContext.save()
        
        // Verify it was created
        var descriptor = FetchDescriptor<Hunt>(predicate: #Predicate { $0.title == "Delete Test" })
        var hunts = try modelContext.fetch(descriptor)
        XCTAssertEqual(hunts.count, 1)
        
        // Delete the hunt
        if let huntToDelete = hunts.first {
            modelContext.delete(huntToDelete)
            try modelContext.save()
        }
        
        // Verify it was deleted
        descriptor = FetchDescriptor<Hunt>(predicate: #Predicate { $0.title == "Delete Test" })
        hunts = try modelContext.fetch(descriptor)
        XCTAssertEqual(hunts.count, 0)
    }
    
    func testHuntStartAndEndTime() throws {
        // Create a hunt with start and end times
        let startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        
        let hunt = Hunt(
            title: "Timed Hunt",
            description: "Hunt with time constraints",
            location: "Main Deck",
            startTime: startDate,
            endTime: endDate
        )
        
        modelContext.insert(hunt)
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Hunt>(predicate: #Predicate { $0.title == "Timed Hunt" })
        let hunts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(hunts.count, 1)
        XCTAssertEqual(hunts.first?.startTime, startDate)
        XCTAssertEqual(hunts.first?.endTime, endDate)
        
        // Test the isActive property
        let pastHunt = Hunt(
            title: "Past Hunt",
            description: "Hunt that has ended",
            location: "Pool Deck",
            startTime: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        
        let futureHunt = Hunt(
            title: "Future Hunt",
            description: "Hunt that hasn't started",
            location: "Casino",
            startTime: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        )
        
        let currentHunt = Hunt(
            title: "Current Hunt",
            description: "Hunt happening now",
            location: "Restaurant",
            startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        
        XCTAssertFalse(pastHunt.isActive)
        XCTAssertFalse(futureHunt.isActive)
        XCTAssertTrue(currentHunt.isActive)
    }
    
    func testHuntCreatorAndParticipants() throws {
        // Create users
        let creator = User(username: "creator", displayName: "Creator")
        let participant1 = User(username: "user1", displayName: "User 1")
        let participant2 = User(username: "user2", displayName: "User 2")
        
        modelContext.insert(creator)
        modelContext.insert(participant1)
        modelContext.insert(participant2)
        
        // Create hunt with creator
        let hunt = Hunt(title: "Social Hunt", description: "Hunt with participants", location: "All Decks")
        hunt.creatorId = creator.id
        
        // Add participants
        hunt.participantIds = [participant1.id, participant2.id]
        
        modelContext.insert(hunt)
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Hunt>(predicate: #Predicate { $0.title == "Social Hunt" })
        let hunts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(hunts.count, 1)
        XCTAssertEqual(hunts.first?.creatorId, creator.id)
        XCTAssertEqual(hunts.first?.participantIds?.count, 2)
        XCTAssertTrue(hunts.first?.participantIds?.contains(participant1.id) ?? false)
        XCTAssertTrue(hunts.first?.participantIds?.contains(participant2.id) ?? false)
    }
} 