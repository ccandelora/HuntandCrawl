import XCTest
import SwiftData
@testable import HuntandCrawl

final class BarStopVisitModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Set up an in-memory SwiftData container for testing
        let schema = Schema([
            BarStopVisit.self,
            BarStop.self,
            BarCrawl.self,
            User.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        // Clear all test data
        try clearAllData()
        modelContainer = nil
        modelContext = nil
    }
    
    private func clearAllData() throws {
        try modelContext.delete(model: BarStopVisit.self)
        try modelContext.delete(model: BarStop.self)
        try modelContext.delete(model: BarCrawl.self)
        try modelContext.delete(model: User.self)
    }
    
    // Helper function to create test objects
    private func createTestObjects() throws -> (user: User, barCrawl: BarCrawl, barStop: BarStop) {
        // Create a user
        let user = User(username: "testuser", displayName: "Test User")
        modelContext.insert(user)
        
        // Create a bar crawl
        let barCrawl = BarCrawl(name: "Test Crawl", description: "Test description", theme: "Tropical")
        modelContext.insert(barCrawl)
        
        // Create a bar stop
        let barStop = BarStop(
            name: "Test Bar",
            specialDrink: "Test Cocktail",
            drinkPrice: 9.99,
            barStopDescription: "A test bar",
            latitude: 25.0,
            longitude: -80.0
        )
        barStop.barCrawl = barCrawl
        modelContext.insert(barStop)
        
        try modelContext.save()
        return (user, barCrawl, barStop)
    }
    
    func testCreateBarStopVisit() throws {
        // Set up prerequisite objects
        let (user, _, barStop) = try createTestObjects()
        
        // Create a visit
        let visit = BarStopVisit(
            barStop: barStop,
            user: user,
            visitedAt: Date(),
            drinkOrdered: "Margarita",
            rating: 5,
            comments: "Great place!"
        )
        modelContext.insert(visit)
        
        // Try to save and verify no errors
        XCTAssertNoThrow(try modelContext.save())
        
        // Fetch the visit and verify properties
        let descriptor = FetchDescriptor<BarStopVisit>(predicate: #Predicate { $0.userId == user.id })
        let visits = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(visits.count, 1)
        let fetchedVisit = visits.first!
        
        XCTAssertEqual(fetchedVisit.userId, user.id)
        XCTAssertEqual(fetchedVisit.drinkOrdered, "Margarita")
        XCTAssertEqual(fetchedVisit.rating, 5)
        XCTAssertEqual(fetchedVisit.comments, "Great place!")
        XCTAssertNotNil(fetchedVisit.visitedAt)
        XCTAssertEqual(fetchedVisit.barStop?.id, barStop.id)
        XCTAssertEqual(fetchedVisit.user?.id, user.id)
    }
    
    func testUpdateBarStopVisit() throws {
        // Set up prerequisite objects
        let (user, _, barStop) = try createTestObjects()
        
        // Create a visit
        let visit = BarStopVisit(
            barStop: barStop,
            user: user,
            visitedAt: Date(),
            drinkOrdered: "Margarita",
            rating: 3,
            comments: "Okay place"
        )
        modelContext.insert(visit)
        try modelContext.save()
        
        // Update the visit
        visit.drinkOrdered = "Piña Colada"
        visit.rating = 5
        visit.comments = "Much better after trying their specialty!"
        
        // Save changes
        try modelContext.save()
        
        // Fetch and verify the updated visit
        let descriptor = FetchDescriptor<BarStopVisit>(predicate: #Predicate { $0.id == visit.id })
        let visits = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(visits.count, 1)
        let updatedVisit = visits.first!
        
        XCTAssertEqual(updatedVisit.drinkOrdered, "Piña Colada")
        XCTAssertEqual(updatedVisit.rating, 5)
        XCTAssertEqual(updatedVisit.comments, "Much better after trying their specialty!")
    }
    
    func testDeleteBarStopVisit() throws {
        // Set up prerequisite objects
        let (user, _, barStop) = try createTestObjects()
        
        // Create a visit
        let visit = BarStopVisit(
            barStop: barStop,
            user: user,
            visitedAt: Date()
        )
        modelContext.insert(visit)
        try modelContext.save()
        
        // Verify visit exists
        var descriptor = FetchDescriptor<BarStopVisit>()
        var visits = try modelContext.fetch(descriptor)
        XCTAssertEqual(visits.count, 1)
        
        // Delete the visit
        modelContext.delete(visit)
        try modelContext.save()
        
        // Verify visit is deleted
        visits = try modelContext.fetch(descriptor)
        XCTAssertEqual(visits.count, 0)
        
        // Verify bar stop and user still exist
        let barStopDescriptor = FetchDescriptor<BarStop>(predicate: #Predicate { $0.id == barStop.id })
        let barStops = try modelContext.fetch(barStopDescriptor)
        XCTAssertEqual(barStops.count, 1)
        
        let userDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == user.id })
        let users = try modelContext.fetch(userDescriptor)
        XCTAssertEqual(users.count, 1)
    }
    
    func testPhotoData() throws {
        // Set up prerequisite objects
        let (user, _, barStop) = try createTestObjects()
        
        // Create test photo data
        let testImage = UIImage(systemName: "star.fill")!
        let testData = testImage.pngData()!
        
        // Create a visit with photo data
        let visit = BarStopVisit(
            barStop: barStop,
            user: user,
            visitedAt: Date(),
            photoData: testData
        )
        modelContext.insert(visit)
        try modelContext.save()
        
        // Fetch and verify photo data
        let descriptor = FetchDescriptor<BarStopVisit>(predicate: #Predicate { $0.id == visit.id })
        let visits = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(visits.count, 1)
        let fetchedVisit = visits.first!
        
        XCTAssertNotNil(fetchedVisit.photoData)
        XCTAssertEqual(fetchedVisit.photoData, testData)
    }
    
    func testUserVisits() throws {
        // Set up prerequisite objects
        let (user, _, barStop) = try createTestObjects()
        
        // Create multiple visits for the user
        let visit1 = BarStopVisit(
            barStop: barStop,
            user: user,
            visitedAt: Date(),
            drinkOrdered: "Mojito",
            rating: 4
        )
        
        let visit2 = BarStopVisit(
            barStop: barStop,
            user: user,
            visitedAt: Date().addingTimeInterval(3600), // 1 hour later
            drinkOrdered: "Daiquiri",
            rating: 5
        )
        
        modelContext.insert(visit1)
        modelContext.insert(visit2)
        try modelContext.save()
        
        // Fetch visits by user
        let userVisitsPredicate = #Predicate<BarStopVisit> { visit in
            visit.userId == user.id
        }
        
        let descriptor = FetchDescriptor<BarStopVisit>(predicate: userVisitsPredicate)
        let visits = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(visits.count, 2)
        
        // Verify each visit belongs to the user
        for visit in visits {
            XCTAssertEqual(visit.userId, user.id)
            XCTAssertEqual(visit.user?.id, user.id)
        }
    }
    
    func testBarStopMultipleVisits() throws {
        // Set up prerequisite objects
        let (user1, _, barStop) = try createTestObjects()
        
        // Create a second user
        let user2 = User(username: "user2", displayName: "Second User")
        modelContext.insert(user2)
        
        // Create visits for different users
        let visit1 = BarStopVisit(
            barStop: barStop,
            user: user1,
            visitedAt: Date(),
            rating: 4
        )
        
        let visit2 = BarStopVisit(
            barStop: barStop,
            user: user2,
            visitedAt: Date(),
            rating: 5
        )
        
        modelContext.insert(visit1)
        modelContext.insert(visit2)
        try modelContext.save()
        
        // Fetch the bar stop and check its visits
        let barStopDescriptor = FetchDescriptor<BarStop>(predicate: #Predicate { $0.id == barStop.id })
        let barStops = try modelContext.fetch(barStopDescriptor)
        
        XCTAssertEqual(barStops.count, 1)
        let fetchedBarStop = barStops.first!
        
        XCTAssertNotNil(fetchedBarStop.visits)
        XCTAssertEqual(fetchedBarStop.visits?.count, 2)
        
        // Verify the bar stop is "visited" according to extension
        XCTAssertTrue(fetchedBarStop.isVisited)
    }
    
    func testCascadeDeleteWhenBarStopDeleted() throws {
        // Set up prerequisite objects
        let (user, _, barStop) = try createTestObjects()
        
        // Create a visit
        let visit = BarStopVisit(
            barStop: barStop,
            user: user,
            visitedAt: Date()
        )
        modelContext.insert(visit)
        try modelContext.save()
        
        // Verify visit exists
        var visitDescriptor = FetchDescriptor<BarStopVisit>()
        var visits = try modelContext.fetch(visitDescriptor)
        XCTAssertEqual(visits.count, 1)
        
        // Delete the bar stop (should cascade delete the visit)
        modelContext.delete(barStop)
        try modelContext.save()
        
        // Verify bar stop is deleted
        let barStopDescriptor = FetchDescriptor<BarStop>(predicate: #Predicate { $0.id == barStop.id })
        let barStops = try modelContext.fetch(barStopDescriptor)
        XCTAssertEqual(barStops.count, 0)
        
        // Verify visit is also deleted (cascade)
        visits = try modelContext.fetch(visitDescriptor)
        XCTAssertEqual(visits.count, 0)
        
        // Verify user still exists (no cascade)
        let userDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == user.id })
        let users = try modelContext.fetch(userDescriptor)
        XCTAssertEqual(users.count, 1)
    }
} 