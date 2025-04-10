import XCTest
import SwiftData
import CoreLocation
@testable import HuntandCrawl

final class DynamicChallengeTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var locationManager: MockLocationManager!
    var dynamicChallengeManager: DynamicChallengeManager!
    
    override func setUpWithError() throws {
        // Set up an in-memory SwiftData container for testing
        let schema = Schema([
            Hunt.self,
            HuntTask.self,
            User.self,
            Team.self,
            SyncEvent.self,
            TaskCompletion.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // Set up mock location manager
        locationManager = MockLocationManager()
        
        // Initialize dynamic challenge manager
        dynamicChallengeManager = DynamicChallengeManager(
            modelContext: modelContext,
            locationManager: locationManager
        )
    }
    
    override func tearDownWithError() throws {
        // Clear any test data
        try modelContext.delete(model: HuntTask.self)
        try modelContext.delete(model: Hunt.self)
        try modelContext.delete(model: User.self)
        try modelContext.delete(model: Team.self)
        try modelContext.delete(model: TaskCompletion.self)
        try modelContext.delete(model: SyncEvent.self)
        
        dynamicChallengeManager = nil
        locationManager = nil
        modelContext = nil
        modelContainer = nil
    }
    
    func testDynamicChallengeGeneration() throws {
        // Create a user and team
        let user = User(id: UUID(), username: "testuser", displayName: "Test User")
        let team = Team(name: "Test Team", creatorId: user.id)
        team.members = [user]
        modelContext.insert(user)
        modelContext.insert(team)
        
        // Create a hunt with no dynamic challenges yet
        let hunt = Hunt(title: "Test Hunt", description: "Test Description", location: "Test Location")
        modelContext.insert(hunt)
        
        // Set a mock location
        locationManager.mockLocation = CLLocation(latitude: 25.123, longitude: -80.456)
        
        // Trigger dynamic challenge generation
        let expectation = self.expectation(description: "Dynamic challenge generation")
        
        dynamicChallengeManager.generateTeamChallenge(for: hunt, teamId: team.id)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Failed to generate dynamic challenge: \(error)")
                }
                expectation.fulfill()
            }, receiveValue: { challenge in
                // Verify that a challenge was created
                XCTAssertNotNil(challenge)
                XCTAssertEqual(challenge.hunt?.id, hunt.id)
                
                // Verify challenge properties
                XCTAssertTrue(challenge.title.contains("Team Challenge"))
                XCTAssertTrue(challenge.subtitle?.contains("Team ID: \(team.id)") ?? false)
                
                // Verify that the challenge was added to the hunt
                XCTAssertTrue(hunt.tasks?.contains(where: { $0.id == challenge.id }) ?? false)
                
                // Verify location data is set
                XCTAssertNotNil(challenge.deckNumber)
                XCTAssertNotNil(challenge.locationOnShip)
                XCTAssertNotNil(challenge.section)
            })
            .store(in: &dynamicChallengeManager.cancellables)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testChallengeCompletionEligibility() throws {
        // Create a user and team
        let user = User(id: UUID(), username: "testuser", displayName: "Test User")
        let team = Team(name: "Test Team", creatorId: user.id)
        modelContext.insert(user)
        modelContext.insert(team)
        
        // Create a hunt
        let hunt = Hunt(title: "Test Hunt", description: "Test Description", location: "Test Location")
        modelContext.insert(hunt)
        
        // Format dates the same way the challenge manager would
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        // Create an active challenge
        let activeMetadata = """
        Team Challenge:
        - Team ID: \(team.id)
        - Generated: \(formatter.string(from: Date()))
        - Expires: \(formatter.string(from: Date().addingTimeInterval(3600)))
        - Requires 2 team members
        """
        
        let activeTask = HuntTask(
            title: "Team Challenge: Test",
            subtitle: activeMetadata,
            taskDescription: "A test challenge",
            points: 100,
            verificationMethod: .photo,
            order: 1
        )
        activeTask.hunt = hunt
        
        // Create an expired challenge
        let expiredMetadata = """
        Team Challenge:
        - Team ID: \(team.id)
        - Generated: \(formatter.string(from: Date().addingTimeInterval(-7200)))
        - Expires: \(formatter.string(from: Date().addingTimeInterval(-3600)))
        - Requires 2 team members
        """
        
        let expiredTask = HuntTask(
            title: "Team Challenge: Expired",
            subtitle: expiredMetadata,
            taskDescription: "An expired challenge",
            points: 100,
            verificationMethod: .photo,
            order: 2
        )
        expiredTask.hunt = hunt
        
        hunt.tasks = [activeTask, expiredTask]
        modelContext.insert(activeTask)
        modelContext.insert(expiredTask)
        
        // Check eligibility
        XCTAssertTrue(dynamicChallengeManager.isEligibleForCompletion(task: activeTask))
        XCTAssertFalse(dynamicChallengeManager.isEligibleForCompletion(task: expiredTask))
    }
    
    func testFetchActiveChallengesForTeam() throws {
        // Create a user and team
        let user = User(id: UUID(), username: "testuser", displayName: "Test User")
        let team = Team(name: "Test Team", creatorId: user.id)
        modelContext.insert(user)
        modelContext.insert(team)
        
        // Create a hunt
        let hunt = Hunt(title: "Test Hunt", description: "Test Description", location: "Test Location")
        modelContext.insert(hunt)
        
        // Format dates the same way the challenge manager would
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        // Create an active challenge
        let activeMetadata = """
        Team Challenge:
        - Team ID: \(team.id)
        - Generated: \(formatter.string(from: Date()))
        - Expires: \(formatter.string(from: Date().addingTimeInterval(3600)))
        - Requires 2 team members
        """
        
        let activeTask = HuntTask(
            title: "Team Challenge: Test",
            subtitle: activeMetadata,
            taskDescription: "A test challenge",
            points: 100,
            verificationMethod: .photo,
            order: 1
        )
        activeTask.hunt = hunt
        
        // Create an expired challenge
        let expiredMetadata = """
        Team Challenge:
        - Team ID: \(team.id)
        - Generated: \(formatter.string(from: Date().addingTimeInterval(-7200)))
        - Expires: \(formatter.string(from: Date().addingTimeInterval(-3600)))
        - Requires 2 team members
        """
        
        let expiredTask = HuntTask(
            title: "Team Challenge: Expired",
            subtitle: expiredMetadata,
            taskDescription: "An expired challenge",
            points: 100,
            verificationMethod: .photo,
            order: 2
        )
        expiredTask.hunt = hunt
        
        // Create a completed challenge
        let completedMetadata = """
        Team Challenge:
        - Team ID: \(team.id)
        - Generated: \(formatter.string(from: Date()))
        - Expires: \(formatter.string(from: Date().addingTimeInterval(3600)))
        - Requires 2 team members
        """
        
        let completedTask = HuntTask(
            title: "Team Challenge: Completed",
            subtitle: completedMetadata,
            taskDescription: "A completed challenge",
            points: 100,
            verificationMethod: .photo,
            order: 3
        )
        completedTask.hunt = hunt
        
        // Add a mock completion to make it completed
        let completion = TaskCompletion(
            id: UUID().uuidString, 
            isVerified: true
        )
        completedTask.completions = [completion]
        
        hunt.tasks = [activeTask, expiredTask, completedTask]
        modelContext.insert(activeTask)
        modelContext.insert(expiredTask)
        modelContext.insert(completedTask)
        modelContext.insert(completion)
        
        // Fetch active challenges
        let activeChallenges = dynamicChallengeManager.fetchActiveChallengesForTeam(team.id)
        
        // Should only include the active challenge, not expired or completed ones
        XCTAssertEqual(activeChallenges.count, 1)
        XCTAssertEqual(activeChallenges.first?.id, activeTask.id)
    }
}

// MARK: - Mock Location Manager for Testing

class MockLocationManager: LocationManager {
    var mockLocation: CLLocation?
    
    override var userLocation: CLLocation? {
        return mockLocation
    }
    
    override var isAuthorized: Bool {
        return true
    }
} 