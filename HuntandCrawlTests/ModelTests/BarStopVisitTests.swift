import XCTest
import SwiftData
@testable import HuntandCrawl

class BarStopVisitTests: XCTestCase {
    var modelContainer: ModelContainer!
    
    override func setUpWithError() throws {
        // Set up an in-memory container for testing
        let schema = Schema([BarStopVisit.self, BarStop.self, BarCrawl.self, User.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDownWithError() throws {
        // Clean up
        modelContainer = nil
    }
    
    func testCreateBarStopVisit() throws {
        let context = modelContainer.mainContext
        
        // Create a user, bar crawl, and bar stop
        let user = User(name: "Jane", email: "jane@example.com")
        let barCrawl = BarCrawl(name: "Downtown Bars", barCrawlDescription: "Visit downtown bars", theme: "Urban")
        let barStop = BarStop(name: "The Tap Room", barStopDescription: "Craft beer bar", specialDrink: "IPA Flight")
        barStop.barCrawl = barCrawl
        
        // Create a bar stop visit
        let visit = BarStopVisit(
            barStop: barStop,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: false,
            verificationMethod: .location
        )
        
        // Insert into context
        context.insert(user)
        context.insert(barCrawl)
        context.insert(barStop)
        context.insert(visit)
        
        // Fetch the bar stop visit
        let descriptor = FetchDescriptor<BarStopVisit>()
        let visits = try context.fetch(descriptor)
        
        // Verify bar stop visit was created
        XCTAssertEqual(visits.count, 1)
        XCTAssertEqual(visits.first?.userId, user.id)
        XCTAssertEqual(visits.first?.barStop?.name, "The Tap Room")
        XCTAssertEqual(visits.first?.barCrawl?.name, "Downtown Bars")
        XCTAssertEqual(visits.first?.verificationMethod, .location)
        XCTAssertFalse(visits.first?.isVerified ?? true)
    }
    
    func testBarStopVisitVerification() throws {
        let context = modelContainer.mainContext
        
        // Create a user, bar crawl, and bar stop
        let user = User(name: "Sam", email: "sam@example.com")
        let barCrawl = BarCrawl(name: "Beach Bars", barCrawlDescription: "Visit beach bars", theme: "Tropical")
        let barStop = BarStop(name: "Sunset Bar", barStopDescription: "Beachfront bar", specialDrink: "Mai Tai")
        barStop.barCrawl = barCrawl
        
        // Create an unverified bar stop visit
        let visit = BarStopVisit(
            barStop: barStop,
            barCrawl: barCrawl, 
            userId: user.id,
            visitTime: Date(),
            isVerified: false,
            verificationMethod: .photo
        )
        
        // Insert into context
        context.insert(user)
        context.insert(barCrawl)
        context.insert(barStop)
        context.insert(visit)
        
        // Verify the visit
        visit.isVerified = true
        visit.verificationTime = Date()
        
        // Fetch the bar stop visit
        let descriptor = FetchDescriptor<BarStopVisit>()
        let visits = try context.fetch(descriptor)
        
        // Verify bar stop visit was verified
        XCTAssertEqual(visits.count, 1)
        XCTAssertTrue(visits.first?.isVerified ?? false)
        XCTAssertNotNil(visits.first?.verificationTime)
    }
    
    func testBarStopVisitWithEvidenceData() throws {
        let context = modelContainer.mainContext
        
        // Create a user, bar crawl, and bar stop
        let user = User(name: "Taylor", email: "taylor@example.com")
        let barCrawl = BarCrawl(name: "City Tour", barCrawlDescription: "Visit city bars", theme: "Metropolitan")
        let barStop = BarStop(name: "Sky Lounge", barStopDescription: "Rooftop bar", specialDrink: "Cosmopolitan")
        barStop.barCrawl = barCrawl
        
        // Create photo evidence data
        let photoData = "photo_evidence".data(using: .utf8)
        
        // Create a bar stop visit with evidence
        let visit = BarStopVisit(
            barStop: barStop,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: false,
            verificationMethod: .photo,
            evidenceData: photoData
        )
        
        // Insert into context
        context.insert(user)
        context.insert(barCrawl)
        context.insert(barStop)
        context.insert(visit)
        
        // Fetch the bar stop visit
        let descriptor = FetchDescriptor<BarStopVisit>()
        let visits = try context.fetch(descriptor)
        
        // Verify evidence data was saved
        XCTAssertEqual(visits.count, 1)
        
        if let savedEvidence = visits.first?.evidenceData,
           let evidenceString = String(data: savedEvidence, encoding: .utf8) {
            XCTAssertEqual(evidenceString, "photo_evidence")
        } else {
            XCTFail("Evidence data could not be converted back to string")
        }
    }
    
    func testUpdateBarStopVisit() throws {
        let context = modelContainer.mainContext
        
        // Create a user, bar crawl, and bar stop
        let user = User(name: "Alex", email: "alex@example.com")
        let barCrawl = BarCrawl(name: "Historic Pubs", barCrawlDescription: "Visit historic pubs", theme: "Classic")
        let barStop = BarStop(name: "The Old Tavern", barStopDescription: "18th century tavern", specialDrink: "Ale")
        barStop.barCrawl = barCrawl
        
        // Create a bar stop visit
        let visitTime = Date().addingTimeInterval(-3600) // 1 hour ago
        let visit = BarStopVisit(
            barStop: barStop,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: visitTime,
            isVerified: false,
            verificationMethod: .manual
        )
        
        // Insert into context
        context.insert(user)
        context.insert(barCrawl)
        context.insert(barStop)
        context.insert(visit)
        
        // Update the visit
        let updatedTime = Date()
        visit.visitTime = updatedTime
        visit.isVerified = true
        visit.verificationMethod = .location
        visit.drinkPurchased = "Aged Whiskey"
        visit.updatedAt = Date()
        
        // Fetch the bar stop visit
        let descriptor = FetchDescriptor<BarStopVisit>()
        let visits = try context.fetch(descriptor)
        
        // Verify bar stop visit was updated
        XCTAssertEqual(visits.count, 1)
        XCTAssertEqual(visits.first?.visitTime.timeIntervalSince1970, updatedTime.timeIntervalSince1970, accuracy: 1.0)
        XCTAssertTrue(visits.first?.isVerified ?? false)
        XCTAssertEqual(visits.first?.verificationMethod, .location)
        XCTAssertEqual(visits.first?.drinkPurchased, "Aged Whiskey")
    }
    
    func testDeleteBarStopVisit() throws {
        let context = modelContainer.mainContext
        
        // Create a user, bar crawl, and bar stop
        let user = User(name: "Morgan", email: "morgan@example.com")
        let barCrawl = BarCrawl(name: "Jazz Clubs", barCrawlDescription: "Visit jazz clubs", theme: "Musical")
        let barStop = BarStop(name: "Blue Note", barStopDescription: "Jazz club and bar", specialDrink: "Blue Martini")
        barStop.barCrawl = barCrawl
        
        // Create a bar stop visit
        let visit = BarStopVisit(
            barStop: barStop,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .photo
        )
        
        // Insert into context
        context.insert(user)
        context.insert(barCrawl)
        context.insert(barStop)
        context.insert(visit)
        
        // Verify it was inserted
        var descriptor = FetchDescriptor<BarStopVisit>()
        var visits = try context.fetch(descriptor)
        XCTAssertEqual(visits.count, 1)
        
        // Delete the visit
        context.delete(visit)
        
        // Verify it was deleted
        descriptor = FetchDescriptor<BarStopVisit>()
        visits = try context.fetch(descriptor)
        XCTAssertEqual(visits.count, 0)
    }
    
    func testFilterBarStopVisitsByVerificationStatus() throws {
        let context = modelContainer.mainContext
        
        // Create a user, bar crawl, and bar stops
        let user = User(name: "Riley", email: "riley@example.com")
        let barCrawl = BarCrawl(name: "Waterfront Tour", barCrawlDescription: "Visit waterfront bars", theme: "Nautical")
        
        let barStop1 = BarStop(name: "Harbor View", barStopDescription: "Bar with harbor view", specialDrink: "Sea Breeze")
        let barStop2 = BarStop(name: "Pier Pub", barStopDescription: "Pub on the pier", specialDrink: "Dark & Stormy")
        let barStop3 = BarStop(name: "Marina Bar", barStopDescription: "Bar by the marina", specialDrink: "Rum Runner")
        
        barStop1.barCrawl = barCrawl
        barStop2.barCrawl = barCrawl
        barStop3.barCrawl = barCrawl
        
        // Create bar stop visits with different verification statuses
        let visit1 = BarStopVisit(
            barStop: barStop1,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .location
        )
        
        let visit2 = BarStopVisit(
            barStop: barStop2,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: false,
            verificationMethod: .photo
        )
        
        let visit3 = BarStopVisit(
            barStop: barStop3,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .manual
        )
        
        // Insert into context
        context.insert(user)
        context.insert(barCrawl)
        context.insert(barStop1)
        context.insert(barStop2)
        context.insert(barStop3)
        context.insert(visit1)
        context.insert(visit2)
        context.insert(visit3)
        
        // Filter for verified visits
        let verifiedDescriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate { visit in
                visit.isVerified == true
            }
        )
        
        let verifiedVisits = try context.fetch(verifiedDescriptor)
        
        // Filter for unverified visits
        let unverifiedDescriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate { visit in
                visit.isVerified == false
            }
        )
        
        let unverifiedVisits = try context.fetch(unverifiedDescriptor)
        
        // Verify filtering works
        XCTAssertEqual(verifiedVisits.count, 2)
        XCTAssertEqual(unverifiedVisits.count, 1)
        
        // Verify correct items in each group
        let verifiedBarStopNames = verifiedVisits.compactMap { $0.barStop?.name }
        XCTAssertTrue(verifiedBarStopNames.contains("Harbor View"))
        XCTAssertTrue(verifiedBarStopNames.contains("Marina Bar"))
        
        let unverifiedBarStopNames = unverifiedVisits.compactMap { $0.barStop?.name }
        XCTAssertTrue(unverifiedBarStopNames.contains("Pier Pub"))
    }
    
    func testFilterBarStopVisitsByVerificationMethod() throws {
        let context = modelContainer.mainContext
        
        // Create a user, bar crawl, and bar stops
        let user = User(name: "Jordan", email: "jordan@example.com")
        let barCrawl = BarCrawl(name: "Wine Tour", barCrawlDescription: "Visit wine bars", theme: "Vineyard")
        
        let barStop1 = BarStop(name: "Reds", barStopDescription: "Red wine bar", specialDrink: "Cabernet Flight")
        let barStop2 = BarStop(name: "Whites", barStopDescription: "White wine bar", specialDrink: "Chardonnay Flight")
        let barStop3 = BarStop(name: "Blends", barStopDescription: "Mixed wine bar", specialDrink: "Blend Tasting")
        
        barStop1.barCrawl = barCrawl
        barStop2.barCrawl = barCrawl
        barStop3.barCrawl = barCrawl
        
        // Create bar stop visits with different verification methods
        let visit1 = BarStopVisit(
            barStop: barStop1,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .location
        )
        
        let visit2 = BarStopVisit(
            barStop: barStop2,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .photo
        )
        
        let visit3 = BarStopVisit(
            barStop: barStop3,
            barCrawl: barCrawl,
            userId: user.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .manual
        )
        
        // Insert into context
        context.insert(user)
        context.insert(barCrawl)
        context.insert(barStop1)
        context.insert(barStop2)
        context.insert(barStop3)
        context.insert(visit1)
        context.insert(visit2)
        context.insert(visit3)
        
        // Filter for location-verified visits
        let locationDescriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate { visit in
                visit.verificationMethod == .location
            }
        )
        
        let locationVisits = try context.fetch(locationDescriptor)
        
        // Filter for photo-verified visits
        let photoDescriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate { visit in
                visit.verificationMethod == .photo
            }
        )
        
        let photoVisits = try context.fetch(photoDescriptor)
        
        // Filter for manually-verified visits
        let manualDescriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate { visit in
                visit.verificationMethod == .manual
            }
        )
        
        let manualVisits = try context.fetch(manualDescriptor)
        
        // Verify filtering works
        XCTAssertEqual(locationVisits.count, 1)
        XCTAssertEqual(photoVisits.count, 1)
        XCTAssertEqual(manualVisits.count, 1)
        
        // Verify correct items in each group
        XCTAssertEqual(locationVisits.first?.barStop?.name, "Reds")
        XCTAssertEqual(photoVisits.first?.barStop?.name, "Whites")
        XCTAssertEqual(manualVisits.first?.barStop?.name, "Blends")
    }
    
    func testFilterBarStopVisitsByUser() throws {
        let context = modelContainer.mainContext
        
        // Create users, bar crawl, and bar stop
        let user1 = User(name: "Casey", email: "casey@example.com")
        let user2 = User(name: "Drew", email: "drew@example.com")
        
        let barCrawl = BarCrawl(name: "Craft Beer Tour", barCrawlDescription: "Visit craft breweries", theme: "Brewing")
        let barStop = BarStop(name: "Hopworks", barStopDescription: "Local brewery", specialDrink: "IPA Sampler")
        barStop.barCrawl = barCrawl
        
        // Create bar stop visits for different users
        let visit1 = BarStopVisit(
            barStop: barStop,
            barCrawl: barCrawl,
            userId: user1.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .location
        )
        
        let visit2 = BarStopVisit(
            barStop: barStop,
            barCrawl: barCrawl,
            userId: user2.id,
            visitTime: Date(),
            isVerified: true,
            verificationMethod: .photo
        )
        
        // Insert into context
        context.insert(user1)
        context.insert(user2)
        context.insert(barCrawl)
        context.insert(barStop)
        context.insert(visit1)
        context.insert(visit2)
        
        // Filter for user1's visits
        let user1Descriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate { visit in
                visit.userId == user1.id
            }
        )
        
        let user1Visits = try context.fetch(user1Descriptor)
        
        // Filter for user2's visits
        let user2Descriptor = FetchDescriptor<BarStopVisit>(
            predicate: #Predicate { visit in
                visit.userId == user2.id
            }
        )
        
        let user2Visits = try context.fetch(user2Descriptor)
        
        // Verify filtering works
        XCTAssertEqual(user1Visits.count, 1)
        XCTAssertEqual(user2Visits.count, 1)
        
        // Verify correct user IDs
        XCTAssertEqual(user1Visits.first?.userId, user1.id)
        XCTAssertEqual(user2Visits.first?.userId, user2.id)
    }
} 