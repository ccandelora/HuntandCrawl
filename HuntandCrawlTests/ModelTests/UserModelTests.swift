import XCTest
import SwiftData
@testable import HuntandCrawl

final class UserModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUpWithError() throws {
        let schema = Schema([
            User.self,
            Hunt.self,
            Task.self,
            TaskCompletion.self,
            BarCrawl.self,
            BarStop.self,
            BarStopVisit.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = ModelContext(container)
    }
    
    override func tearDownWithError() throws {
        clearAllData()
        container = nil
        context = nil
    }
    
    private func clearAllData() {
        // Delete all entities to avoid test interference
        do {
            try context.delete(model: User.self)
            try context.delete(model: Hunt.self)
            try context.delete(model: Task.self)
            try context.delete(model: TaskCompletion.self)
            try context.delete(model: BarCrawl.self)
            try context.delete(model: BarStop.self)
            try context.delete(model: BarStopVisit.self)
        } catch {
            XCTFail("Failed to clear data: \(error)")
        }
        
        try? context.save()
    }
    
    func testCreateUser() throws {
        // Create a user with basic properties
        let user = User(
            name: "John Doe",
            email: "john@example.com",
            avatar: Data("avatar".utf8),
            bio: "Test user bio",
            preferredThemes: ["Pirates", "Space"]
        )
        
        context.insert(user)
        try context.save()
        
        // Fetch the user and verify properties
        let fetchDescriptor = FetchDescriptor<User>()
        let fetchedUsers = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedUsers.count, 1)
        let fetchedUser = fetchedUsers.first!
        
        // Verify basic properties
        XCTAssertEqual(fetchedUser.id.count, 36) // UUID string length
        XCTAssertEqual(fetchedUser.name, "John Doe")
        XCTAssertEqual(fetchedUser.email, "john@example.com")
        XCTAssertEqual(fetchedUser.avatar, Data("avatar".utf8))
        XCTAssertEqual(fetchedUser.bio, "Test user bio")
        XCTAssertEqual(fetchedUser.preferredThemes, ["Pirates", "Space"])
        XCTAssertNotNil(fetchedUser.createdAt)
        
        // Verify default values
        XCTAssertEqual(fetchedUser.points, 0)
        XCTAssertEqual(fetchedUser.level, 1)
        XCTAssertTrue(fetchedUser.achievementIds.isEmpty)
    }
    
    func testUpdateUser() throws {
        // Create and insert initial user
        let user = User(name: "Jane Smith")
        context.insert(user)
        try context.save()
        
        // Fetch and update the user
        let fetchDescriptor = FetchDescriptor<User>()
        let fetchedUsers = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 1)
        
        let fetchedUser = fetchedUsers.first!
        fetchedUser.name = "Jane Wilson"
        fetchedUser.email = "jane@example.com"
        fetchedUser.bio = "Updated bio"
        fetchedUser.points = 100
        fetchedUser.level = 2
        fetchedUser.achievementIds = ["achievement1", "achievement2"]
        fetchedUser.preferredThemes = ["Fantasy", "Mystery"]
        fetchedUser.updatedAt = Date()
        
        try context.save()
        
        // Refetch to verify updates
        let updatedUsers = try context.fetch(fetchDescriptor)
        XCTAssertEqual(updatedUsers.count, 1)
        
        let updatedUser = updatedUsers.first!
        XCTAssertEqual(updatedUser.name, "Jane Wilson")
        XCTAssertEqual(updatedUser.email, "jane@example.com")
        XCTAssertEqual(updatedUser.bio, "Updated bio")
        XCTAssertEqual(updatedUser.points, 100)
        XCTAssertEqual(updatedUser.level, 2)
        XCTAssertEqual(updatedUser.achievementIds, ["achievement1", "achievement2"])
        XCTAssertEqual(updatedUser.preferredThemes, ["Fantasy", "Mystery"])
        XCTAssertNotNil(updatedUser.updatedAt)
    }
    
    func testDeleteUser() throws {
        // Create a user
        let user = User(name: "Delete Test User")
        context.insert(user)
        try context.save()
        
        // Verify user exists
        let fetchDescriptor = FetchDescriptor<User>()
        var fetchedUsers = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 1)
        
        // Delete the user
        context.delete(fetchedUsers.first!)
        try context.save()
        
        // Verify user is deleted
        fetchedUsers = try context.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedUsers.count, 0)
    }
    
    func testUserWithCreatedHunts() throws {
        // Create a user
        let user = User(name: "Hunt Creator")
        context.insert(user)
        
        // Create hunts created by the user
        let hunt1 = Hunt(
            name: "Pirate Hunt",
            huntDescription: "Find pirate treasures",
            creatorId: user.id
        )
        
        let hunt2 = Hunt(
            name: "Space Hunt",
            huntDescription: "Explore the stars",
            creatorId: user.id
        )
        
        context.insert(hunt1)
        context.insert(hunt2)
        
        try context.save()
        
        // Fetch hunts created by the user
        let huntPredicate = #Predicate<Hunt> { hunt in
            hunt.creatorId == user.id
        }
        
        let huntDescriptor = FetchDescriptor<Hunt>(predicate: huntPredicate)
        let hunts = try context.fetch(huntDescriptor)
        
        XCTAssertEqual(hunts.count, 2)
        XCTAssertTrue(hunts.contains(where: { $0.name == "Pirate Hunt" }))
        XCTAssertTrue(hunts.contains(where: { $0.name == "Space Hunt" }))
    }
    
    func testUserWithCreatedBarCrawls() throws {
        // Create a user
        let user = User(name: "Bar Crawl Creator")
        context.insert(user)
        
        // Create bar crawls created by the user
        let barCrawl1 = BarCrawl(
            name: "Beach Bars",
            barCrawlDescription: "Explore beach bars",
            creatorId: user.id
        )
        
        let barCrawl2 = BarCrawl(
            name: "Downtown Crawl",
            barCrawlDescription: "Explore downtown",
            creatorId: user.id
        )
        
        context.insert(barCrawl1)
        context.insert(barCrawl2)
        
        try context.save()
        
        // Fetch bar crawls created by the user
        let barCrawlPredicate = #Predicate<BarCrawl> { barCrawl in
            barCrawl.creatorId == user.id
        }
        
        let barCrawlDescriptor = FetchDescriptor<BarCrawl>(predicate: barCrawlPredicate)
        let barCrawls = try context.fetch(barCrawlDescriptor)
        
        XCTAssertEqual(barCrawls.count, 2)
        XCTAssertTrue(barCrawls.contains(where: { $0.name == "Beach Bars" }))
        XCTAssertTrue(barCrawls.contains(where: { $0.name == "Downtown Crawl" }))
    }
    
    func testUserParticipatingInHunts() throws {
        // Create users
        let creator = User(name: "Creator")
        let participant1 = User(name: "Participant 1")
        let participant2 = User(name: "Participant 2")
        
        context.insert(creator)
        context.insert(participant1)
        context.insert(participant2)
        
        // Create a hunt
        let hunt = Hunt(
            name: "Group Hunt",
            huntDescription: "Team adventure",
            creatorId: creator.id
        )
        
        // Add participants
        hunt.participantIds = [participant1.id, participant2.id]
        context.insert(hunt)
        
        try context.save()
        
        // Test that hunt has both participants
        XCTAssertEqual(hunt.participantIds.count, 2)
        XCTAssertTrue(hunt.participantIds.contains(participant1.id))
        XCTAssertTrue(hunt.participantIds.contains(participant2.id))
        
        // Fetch hunts for participant1
        let huntPredicate = #Predicate<Hunt> { hunt in
            hunt.participantIds.contains(participant1.id)
        }
        
        let huntDescriptor = FetchDescriptor<Hunt>(predicate: huntPredicate)
        let hunts = try context.fetch(huntDescriptor)
        
        XCTAssertEqual(hunts.count, 1)
        XCTAssertEqual(hunts.first?.name, "Group Hunt")
    }
    
    func testUserWithTaskCompletions() throws {
        // Create a user
        let user = User(name: "Task Completer")
        context.insert(user)
        
        // Create a hunt and tasks
        let hunt = Hunt(name: "Completion Hunt")
        context.insert(hunt)
        
        let task1 = Task(
            title: "Task 1",
            taskDescription: "First task",
            points: 10,
            verificationMethod: .photo
        )
        task1.hunt = hunt
        
        let task2 = Task(
            title: "Task 2",
            taskDescription: "Second task",
            points: 20,
            verificationMethod: .location
        )
        task2.hunt = hunt
        
        context.insert(task1)
        context.insert(task2)
        
        // Create task completions
        let completion1 = TaskCompletion(
            taskId: task1.id,
            userId: user.id,
            completedAt: Date(),
            verificationMethod: .photo,
            evidenceData: Data("photo evidence".utf8),
            isVerified: true
        )
        
        let completion2 = TaskCompletion(
            taskId: task2.id,
            userId: user.id,
            completedAt: Date(),
            verificationMethod: .location,
            evidenceData: Data("location evidence".utf8),
            isVerified: true
        )
        
        context.insert(completion1)
        context.insert(completion2)
        
        try context.save()
        
        // Fetch task completions by user
        let completionPredicate = #Predicate<TaskCompletion> { completion in
            completion.userId == user.id
        }
        
        let completionDescriptor = FetchDescriptor<TaskCompletion>(predicate: completionPredicate)
        let completions = try context.fetch(completionDescriptor)
        
        XCTAssertEqual(completions.count, 2)
        
        // Verify total points from completions
        let totalPoints = completions.reduce(0) { sum, completion in
            // In a real app, we would fetch the task and get its points
            // For testing, we'll use a simple mapping
            let taskPoints = completion.taskId == task1.id ? 10 : 20
            return sum + taskPoints
        }
        
        XCTAssertEqual(totalPoints, 30)
    }
    
    func testUserWithBarStopVisits() throws {
        // Create a user
        let user = User(name: "Bar Crawler")
        context.insert(user)
        
        // Create a bar crawl and bar stops
        let barCrawl = BarCrawl(name: "Visit Crawl")
        context.insert(barCrawl)
        
        let barStop1 = BarStop(
            name: "Bar 1",
            specialDrink: "Special 1",
            order: 1
        )
        barStop1.barCrawl = barCrawl
        
        let barStop2 = BarStop(
            name: "Bar 2",
            specialDrink: "Special 2",
            order: 2
        )
        barStop2.barCrawl = barCrawl
        
        context.insert(barStop1)
        context.insert(barStop2)
        
        // Create bar stop visits
        let visit1 = BarStopVisit(
            checkInTime: Date().addingTimeInterval(-3600),
            specialDrinkOrdered: true,
            rating: 4
        )
        visit1.barStop = barStop1
        visit1.user = user
        
        let visit2 = BarStopVisit(
            checkInTime: Date(),
            specialDrinkOrdered: true,
            rating: 5
        )
        visit2.barStop = barStop2
        visit2.user = user
        
        context.insert(visit1)
        context.insert(visit2)
        
        try context.save()
        
        // Fetch bar stop visits by user
        let visitPredicate = #Predicate<BarStopVisit> { visit in
            visit.user?.id == user.id
        }
        
        let visitDescriptor = FetchDescriptor<BarStopVisit>(predicate: visitPredicate)
        let visits = try context.fetch(visitDescriptor)
        
        XCTAssertEqual(visits.count, 2)
        
        // Check unique bar stops visited
        let barStopsVisited = Set(visits.compactMap { $0.barStop?.id })
        XCTAssertEqual(barStopsVisited.count, 2)
    }
    
    func testUserPointsAndLevel() throws {
        // Create a user
        let user = User(name: "Leveling User")
        context.insert(user)
        
        // Initial state
        XCTAssertEqual(user.points, 0)
        XCTAssertEqual(user.level, 1)
        
        // Update points
        user.points = 150
        
        // In a real app, we might have a method to recalculate level based on points
        // Here we'll manually update level for testing
        user.level = 3
        
        try context.save()
        
        // Fetch and verify
        let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == user.id })
        let fetchedUsers = try context.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedUsers.count, 1)
        let fetchedUser = fetchedUsers.first!
        
        XCTAssertEqual(fetchedUser.points, 150)
        XCTAssertEqual(fetchedUser.level, 3)
    }
} 