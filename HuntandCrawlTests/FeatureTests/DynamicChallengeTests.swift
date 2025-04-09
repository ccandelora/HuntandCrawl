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
            Task.self,
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
        try modelContext.delete(model: Task.self)
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
                XCTAssertEqual(challenge.huntId, hunt.id)
                
                // Verify challenge properties
                XCTAssertTrue(challenge.title.contains("Team Challenge"))
                XCTAssertTrue(challenge.isDynamic)
                XCTAssertEqual(challenge.teamId, team.id)
                
                // Verify that the challenge was added to the hunt
                XCTAssertTrue(hunt.tasks.contains(where: { $0.id == challenge.id }))
                
                // Verify location was set from mock location manager
                XCTAssertEqual(challenge.latitude, 25.123)
                XCTAssertEqual(challenge.longitude, -80.456)
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
        
        // Create an active challenge
        let activeTask = Task(
            hunt: hunt,
            name: "Team Challenge: Test",
            description: "A test challenge",
            points: 100,
            latitude: 0,
            longitude: 0,
            verificationMethod: .photo,
            order: 1
        )
        activeTask.isDynamic = true
        activeTask.teamId = team.id
        activeTask.expiresAt = Date().addingTimeInterval(3600) // Expires in 1 hour
        
        // Create an expired challenge
        let expiredTask = Task(
            hunt: hunt,
            name: "Team Challenge: Expired",
            description: "An expired challenge",
            points: 100,
            latitude: 0,
            longitude: 0,
            verificationMethod: .photo,
            order: 2
        )
        expiredTask.isDynamic = true
        expiredTask.teamId = team.id
        expiredTask.expiresAt = Date().addingTimeInterval(-3600) // Expired 1 hour ago
        
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
        
        // Create an active challenge
        let activeTask = Task(
            hunt: hunt,
            name: "Team Challenge: Test",
            description: "A test challenge",
            points: 100,
            latitude: 0,
            longitude: 0,
            verificationMethod: .photo,
            order: 1
        )
        activeTask.isDynamic = true
        activeTask.teamId = team.id
        activeTask.expiresAt = Date().addingTimeInterval(3600) // Expires in 1 hour
        
        // Create an expired challenge
        let expiredTask = Task(
            hunt: hunt,
            name: "Team Challenge: Expired",
            description: "An expired challenge",
            points: 100,
            latitude: 0,
            longitude: 0,
            verificationMethod: .photo,
            order: 2
        )
        expiredTask.isDynamic = true
        expiredTask.teamId = team.id
        expiredTask.expiresAt = Date().addingTimeInterval(-3600) // Expired 1 hour ago
        
        // Create a completed challenge
        let completedTask = Task(
            hunt: hunt,
            name: "Team Challenge: Completed",
            description: "A completed challenge",
            points: 100,
            latitude: 0,
            longitude: 0,
            verificationMethod: .photo,
            order: 3
        )
        completedTask.isDynamic = true
        completedTask.teamId = team.id
        completedTask.isCompleted = true
        
        hunt.tasks = [activeTask, expiredTask, completedTask]
        modelContext.insert(activeTask)
        modelContext.insert(expiredTask)
        modelContext.insert(completedTask)
        
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