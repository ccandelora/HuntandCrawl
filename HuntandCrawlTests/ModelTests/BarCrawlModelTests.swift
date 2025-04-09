import XCTest
import SwiftData
@testable import HuntandCrawl

final class BarCrawlModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Set up an in-memory SwiftData container for testing
        let schema = Schema([
            BarCrawl.self,
            BarStop.self,
            User.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        // Clear any test data
        try modelContext.delete(model: BarCrawl.self)
        try modelContext.delete(model: BarStop.self)
        try modelContext.delete(model: User.self)
        modelContainer = nil
        modelContext = nil
    }
    
    func testCreateBarCrawl() throws {
        // Create a new bar crawl
        let barCrawl = BarCrawl(name: "Test Crawl", description: "Test Description", theme: "Tropical")
        modelContext.insert(barCrawl)
        
        // Try to save and verify no errors
        XCTAssertNoThrow(try modelContext.save())
        
        // Fetch the bar crawl and verify properties
        let descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Test Crawl" })
        let barCrawls = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(barCrawls.count, 1)
        XCTAssertEqual(barCrawls.first?.name, "Test Crawl")
        XCTAssertEqual(barCrawls.first?.description, "Test Description")
        XCTAssertEqual(barCrawls.first?.theme, "Tropical")
    }
    
    func testBarCrawlWithBarStops() throws {
        // Create a bar crawl with bar stops
        let barCrawl = BarCrawl(name: "Crawl with Stops", description: "Bar crawl with multiple stops", theme: "Pirate")
        
        // Add bar stops to the bar crawl
        let stop1 = BarStop(name: "Stop 1", description: "First stop", specialDrink: "Rum Runner", latitude: 25.0, longitude: -80.0)
        let stop2 = BarStop(name: "Stop 2", description: "Second stop", specialDrink: "Mai Tai", latitude: 25.1, longitude: -80.1)
        
        barCrawl.barStops = [stop1, stop2]
        
        // Save to context
        modelContext.insert(barCrawl)
        XCTAssertNoThrow(try modelContext.save())
        
        // Fetch and verify
        let descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Crawl with Stops" })
        let barCrawls = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(barCrawls.count, 1)
        XCTAssertEqual(barCrawls.first?.barStops?.count, 2)
        
        let stops = barCrawls.first?.barStops?.sorted { $0.name < $1.name }
        XCTAssertEqual(stops?.first?.name, "Stop 1")
        XCTAssertEqual(stops?.last?.name, "Stop 2")
        XCTAssertEqual(stops?.first?.specialDrink, "Rum Runner")
        XCTAssertEqual(stops?.last?.specialDrink, "Mai Tai")
    }
    
    func testDeleteBarCrawl() throws {
        // Create and save a bar crawl
        let barCrawl = BarCrawl(name: "Delete Test", description: "To be deleted", theme: "Beach")
        modelContext.insert(barCrawl)
        try modelContext.save()
        
        // Verify it was created
        var descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Delete Test" })
        var barCrawls = try modelContext.fetch(descriptor)
        XCTAssertEqual(barCrawls.count, 1)
        
        // Delete the bar crawl
        if let barCrawlToDelete = barCrawls.first {
            modelContext.delete(barCrawlToDelete)
            try modelContext.save()
        }
        
        // Verify it was deleted
        descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Delete Test" })
        barCrawls = try modelContext.fetch(descriptor)
        XCTAssertEqual(barCrawls.count, 0)
    }
    
    func testBarCrawlStartAndEndTime() throws {
        // Create a bar crawl with start and end times
        let startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        
        let barCrawl = BarCrawl(
            name: "Timed Crawl",
            description: "Crawl with time constraints",
            theme: "Caribbean",
            startTime: startDate,
            endTime: endDate
        )
        
        modelContext.insert(barCrawl)
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Timed Crawl" })
        let barCrawls = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(barCrawls.count, 1)
        XCTAssertEqual(barCrawls.first?.startTime, startDate)
        XCTAssertEqual(barCrawls.first?.endTime, endDate)
        
        // Test the isActive property
        let pastCrawl = BarCrawl(
            name: "Past Crawl",
            description: "Crawl that has ended",
            theme: "Tiki",
            startTime: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        
        let futureCrawl = BarCrawl(
            name: "Future Crawl",
            description: "Crawl that hasn't started",
            theme: "Nautical",
            startTime: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        )
        
        let currentCrawl = BarCrawl(
            name: "Current Crawl",
            description: "Crawl happening now",
            theme: "Island",
            startTime: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            endTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        
        XCTAssertFalse(pastCrawl.isActive)
        XCTAssertFalse(futureCrawl.isActive)
        XCTAssertTrue(currentCrawl.isActive)
    }
    
    func testBarCrawlCreatorAndParticipants() throws {
        // Create users
        let creator = User(username: "creator", displayName: "Creator")
        let participant1 = User(username: "user1", displayName: "User 1")
        let participant2 = User(username: "user2", displayName: "User 2")
        
        modelContext.insert(creator)
        modelContext.insert(participant1)
        modelContext.insert(participant2)
        
        // Create bar crawl with creator
        let barCrawl = BarCrawl(name: "Social Crawl", description: "Crawl with participants", theme: "Party")
        barCrawl.creatorId = creator.id
        
        // Add participants
        barCrawl.participantIds = [participant1.id, participant2.id]
        
        modelContext.insert(barCrawl)
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Social Crawl" })
        let barCrawls = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(barCrawls.count, 1)
        XCTAssertEqual(barCrawls.first?.creatorId, creator.id)
        XCTAssertEqual(barCrawls.first?.participantIds?.count, 2)
        XCTAssertTrue(barCrawls.first?.participantIds?.contains(participant1.id) ?? false)
        XCTAssertTrue(barCrawls.first?.participantIds?.contains(participant2.id) ?? false)
    }
    
    func testBarCrawlWithBarStopOrder() throws {
        // Create a bar crawl with ordered bar stops
        let barCrawl = BarCrawl(name: "Ordered Crawl", description: "Bar crawl with ordered stops", theme: "Pub")
        
        // Add bar stops to the bar crawl
        let stop1 = BarStop(name: "First Stop", description: "Start here", specialDrink: "Beer", latitude: 25.0, longitude: -80.0)
        let stop2 = BarStop(name: "Middle Stop", description: "Continue here", specialDrink: "Wine", latitude: 25.1, longitude: -80.1)
        let stop3 = BarStop(name: "Last Stop", description: "End here", specialDrink: "Whiskey", latitude: 25.2, longitude: -80.2)
        
        // Set order explicitly
        stop1.order = 1
        stop2.order = 2
        stop3.order = 3
        
        barCrawl.barStops = [stop3, stop1, stop2] // Adding in mixed order to test sorting
        
        // Save to context
        modelContext.insert(barCrawl)
        XCTAssertNoThrow(try modelContext.save())
        
        // Fetch and verify
        let descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Ordered Crawl" })
        let barCrawls = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(barCrawls.count, 1)
        XCTAssertEqual(barCrawls.first?.barStops?.count, 3)
        
        // Test that the stops are returned in correct order
        let stops = barCrawls.first?.barStops?.sorted { $0.order < $1.order }
        XCTAssertEqual(stops?[0].name, "First Stop")
        XCTAssertEqual(stops?[1].name, "Middle Stop")
        XCTAssertEqual(stops?[2].name, "Last Stop")
    }
    
    func testBarStopProperties() throws {
        // Create a bar stop with all properties
        let barStop = BarStop(
            name: "Complex Stop",
            description: "Stop with all properties",
            specialDrink: "Complex Cocktail",
            drinkPrice: 12.99,
            openingTime: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date())!,
            closingTime: Calendar.current.date(bySettingHour: 2, minute: 0, second: 0, of: Date())!,
            order: 1,
            latitude: 25.05,
            longitude: -80.05,
            isVIP: true
        )
        
        // Create a bar crawl and add the stop
        let barCrawl = BarCrawl(name: "Property Test Crawl", description: "Testing bar stop properties", theme: "Fancy")
        barCrawl.barStops = [barStop]
        
        // Save to context
        modelContext.insert(barCrawl)
        XCTAssertNoThrow(try modelContext.save())
        
        // Fetch and verify
        let descriptor = FetchDescriptor<BarCrawl>(predicate: #Predicate { $0.name == "Property Test Crawl" })
        let barCrawls = try modelContext.fetch(descriptor)
        let fetchedStop = barCrawls.first?.barStops?.first
        
        XCTAssertEqual(fetchedStop?.name, "Complex Stop")
        XCTAssertEqual(fetchedStop?.specialDrink, "Complex Cocktail")
        XCTAssertEqual(fetchedStop?.drinkPrice, 12.99)
        
        // Check opening/closing time hours (comparing full date objects can be tricky)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: fetchedStop?.openingTime ?? Date()), 16)
        
        // Check location
        XCTAssertEqual(fetchedStop?.latitude, 25.05)
        XCTAssertEqual(fetchedStop?.longitude, -80.05)
        
        // Check VIP status
        XCTAssertTrue(fetchedStop?.isVIP ?? false)
    }
} 