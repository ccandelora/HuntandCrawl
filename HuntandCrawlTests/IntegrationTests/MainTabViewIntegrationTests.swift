import XCTest
import SwiftUI
import SwiftData
import Combine
@testable import HuntandCrawl

final class MainTabViewIntegrationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        // Create an in-memory model container for testing
        let schema = Schema([
            Hunt.self,
            Task.self,
            TaskCompletion.self,
            BarCrawl.self,
            BarStop.self,
            BarStopVisit.self,
            User.self,
            Team.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDownWithError() throws {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        modelContainer = nil
    }
    
    func testManagerInitialization() throws {
        // Create a TestStore to hold observed objects
        let testStore = TestObservableStore()
        
        // Create the view with the test store
        let mainTabView = MainTabView()
            .environment(testStore.locationManager)
            .environment(testStore.navigationManager)
            .environment(testStore.syncManager)
            .modelContainer(modelContainer)
        
        // Create a hosting controller to initialize the view
        let hostingController = UIHostingController(rootView: mainTabView)
        
        // Trigger view appearance
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        
        // Create expectations for manager initializations
        let locationManagerInitialized = XCTestExpectation(description: "LocationManager initialized")
        let syncManagerInitialized = XCTestExpectation(description: "SyncManager initialized")
        
        // Monitor location manager authorization status
        testStore.locationManager.$authorizationStatus
            .dropFirst() // Skip initial value
            .sink { status in
                locationManagerInitialized.fulfill()
            }
            .store(in: &cancellables)
        
        // Monitor sync manager status
        testStore.syncManager.$syncStatus
            .dropFirst() // Skip initial value
            .sink { status in
                syncManagerInitialized.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait for expectations
        wait(for: [locationManagerInitialized, syncManagerInitialized], timeout: 2.0)
        
        // Test that all managers are initialized
        XCTAssertNotNil(testStore.locationManager)
        XCTAssertNotNil(testStore.navigationManager)
        XCTAssertNotNil(testStore.syncManager)
    }
    
    func testManagerCoordination() throws {
        // Create a TestStore to hold observed objects and coordinate them
        let testStore = TestObservableStore()
        
        // Create expectations for manager coordination
        let syncStatusChanged = XCTestExpectation(description: "Sync status changed")
        
        // Monitor sync manager status
        var syncStatuses: [SyncManager.SyncStatus] = []
        testStore.syncManager.$syncStatus
            .sink { status in
                syncStatuses.append(status)
                if syncStatuses.count > 1 {
                    syncStatusChanged.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate going offline
        testStore.syncManager.isOnline = false
        
        // Wait for sync status to change
        wait(for: [syncStatusChanged], timeout: 2.0)
        
        // Verify that sync status reflects offline state
        XCTAssertEqual(syncStatuses.last, .offline)
    }
    
    func testLocationAndNavigationIntegration() throws {
        // Create a TestStore
        let testStore = TestObservableStore()
        
        // Create expectations
        let locationUpdateReceivedByUI = XCTestExpectation(description: "Location update received by UI")
        
        // Monitor location changes
        var locationUpdates = 0
        testStore.locationManager.$userLocation
            .sink { location in
                locationUpdates += 1
                if locationUpdates > 1 { // Skip initial nil value
                    locationUpdateReceivedByUI.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate location update
        testStore.locationManager.userLocation = CLLocation(
            latitude: 25.0,
            longitude: -80.0
        )
        
        // Wait for UI to receive location update
        wait(for: [locationUpdateReceivedByUI], timeout: 2.0)
        
        // Now test that navigation can use location information
        let task = Task(
            name: "Test Task",
            pointValue: 100,
            verificationMethod: .location,
            latitude: 25.0001,
            longitude: -80.0001,
            completionRadius: 100
        )
        
        // The task should be within range of our simulated location
        XCTAssertTrue(testStore.locationManager.isUserNearCoordinate(
            latitude: task.latitude,
            longitude: task.longitude,
            radius: task.completionRadius
        ))
        
        // Navigate to the task
        testStore.navigationManager.navigateToTask(task)
        
        // Verify navigation path contains the task
        XCTAssertEqual(testStore.navigationManager.path.count, 1)
        if case let .task(navigatedTask) = testStore.navigationManager.path.first {
            XCTAssertEqual(navigatedTask.id, task.id)
        } else {
            XCTFail("Navigation path should contain the task")
        }
    }
    
    func testIntegrationWithSyncAndScenePhase() throws {
        // Create a TestStore
        let testStore = TestObservableStore()
        
        // Create the MainTabView with test store
        let mainTabView = MainTabView()
            .environment(testStore.locationManager)
            .environment(testStore.navigationManager)
            .environment(testStore.syncManager)
            .modelContainer(modelContainer)
        
        // Create a hosting controller
        let hostingController = UIHostingController(rootView: mainTabView)
        
        // Trigger view appearance
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        
        // Create expectation for sync attempt
        let syncAttemptExpectation = XCTestExpectation(description: "Sync attempt made")
        
        // Monitor sync status
        testStore.syncManager.$syncStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if case .syncing = status {
                    syncAttemptExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate app returning to foreground
        NotificationCenter.default.post(
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Wait for sync attempt
        wait(for: [syncAttemptExpectation], timeout: 2.0)
        
        // Verify sync was attempted
        if case .syncing = testStore.syncManager.syncStatus {
            // Test passed
        } else {
            XCTFail("Expected sync status to be syncing, but got \(testStore.syncManager.syncStatus)")
        }
    }
}

// Test helper to create and hold observable objects
class TestObservableStore {
    let locationManager = LocationManager()
    let navigationManager = NavigationManager()
    let syncManager = SyncManager()
} 