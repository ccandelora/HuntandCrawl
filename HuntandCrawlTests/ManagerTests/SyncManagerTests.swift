import XCTest
import SwiftData
import Combine
@testable import HuntandCrawl

final class SyncManagerTests: XCTestCase {
    var syncManager: SyncManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        // Create an in-memory container for testing
        let schema = Schema([
            Hunt.self,
            Task.self,
            TaskCompletion.self,
            BarCrawl.self,
            BarStop.self,
            BarStopVisit.self,
            User.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Initialize the SyncManager
        syncManager = SyncManager()
        syncManager.initialize(modelContext: modelContext)
    }
    
    override func tearDownWithError() throws {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        syncManager = nil
        modelContext = nil
        modelContainer = nil
    }
    
    // MARK: - Tests
    
    func testInitialState() {
        // Verify initial state values
        XCTAssertEqual(syncManager.syncStatus, .idle)
        XCTAssertTrue(syncManager.isOnline)
        XCTAssertNil(syncManager.lastSyncTime)
    }
    
    func testOfflineMode() {
        // Create expectation for status change
        let expectation = XCTestExpectation(description: "Sync status changed to offline")
        
        // Monitor for changes
        syncManager.$syncStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if case .offline = status {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Set sync manager to offline
        syncManager.isOnline = false
        syncManager.trySync()
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify state
        if case .offline = syncManager.syncStatus {
            // Test passed
        } else {
            XCTFail("Expected offline status, but got \(syncManager.syncStatus)")
        }
    }
    
    func testSyncProcess() {
        // Create expectation for sync process
        let syncStartedExpectation = XCTestExpectation(description: "Sync process started")
        let syncCompletedExpectation = XCTestExpectation(description: "Sync process completed")
        
        // Set up test data
        syncManager.pendingSyncCount = 5
        
        // Monitor for changes
        syncManager.$syncStatus
            .dropFirst() // Skip initial value
            .sink { status in
                switch status {
                case .syncing:
                    syncStartedExpectation.fulfill()
                case .synced:
                    syncCompletedExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Trigger sync
        syncManager.trySync()
        
        // Wait for expectations
        wait(for: [syncStartedExpectation, syncCompletedExpectation], timeout: 5.0)
        
        // Verify final state
        XCTAssertEqual(syncManager.syncStatus, .synced)
        XCTAssertEqual(syncManager.pendingSyncCount, 0)
        XCTAssertNotNil(syncManager.lastSyncTime)
    }
    
    func testSaveForSync() {
        // Create a sample item to sync
        let hunt = Hunt(name: "Test Hunt")
        
        // Create expectations
        let pendingCountChangedExpectation = XCTestExpectation(description: "Pending sync count changed")
        
        // Monitor for changes
        syncManager.$pendingSyncCount
            .dropFirst() // Skip initial value
            .sink { count in
                pendingCountChangedExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Register the item for sync
        syncManager.saveForSync(item: hunt)
        
        // Wait for expectation
        wait(for: [pendingCountChangedExpectation], timeout: 1.0)
        
        // Verify pending count was updated
        XCTAssertGreaterThan(syncManager.pendingSyncCount, 0)
    }
    
    func testSyncStatusPublisher() {
        // Test that the status is properly published
        let statusChanges = XCTestExpectation(description: "Status changes received")
        statusChanges.expectedFulfillmentCount = 2 // Expect at least 2 status changes
        
        syncManager.$syncStatus
            .dropFirst() // Skip initial status
            .sink { status in
                statusChanges.fulfill()
            }
            .store(in: &cancellables)
        
        // Force status changes
        syncManager.syncStatus = .syncing
        syncManager.syncStatus = .synced
        
        wait(for: [statusChanges], timeout: 1.0)
    }
    
    func testSyncError() {
        // Create expectation for error status
        let errorExpectation = XCTestExpectation(description: "Sync error received")
        
        // Monitor for changes
        syncManager.$syncStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if case .error = status {
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Force an error state
        syncManager.syncStatus = .error("Test error message")
        
        // Wait for expectation
        wait(for: [errorExpectation], timeout: 1.0)
        
        // Verify error message
        if case let .error(message) = syncManager.syncStatus {
            XCTAssertEqual(message, "Test error message")
        } else {
            XCTFail("Expected error status with message")
        }
    }
    
    func testRetrySync() {
        // Create a scenario where sync failed
        syncManager.syncStatus = .error("Previous failure")
        syncManager.pendingSyncCount = 3
        
        // Create expectations
        let syncingExpectation = XCTestExpectation(description: "Sync process started")
        
        // Monitor for changes
        syncManager.$syncStatus
            .dropFirst() // Skip initial value
            .sink { status in
                if case .syncing = status {
                    syncingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Retry sync
        syncManager.trySync()
        
        // Wait for expectation
        wait(for: [syncingExpectation], timeout: 1.0)
        
        // Verify sync was attempted
        XCTAssertEqual(syncManager.syncStatus, .syncing)
    }
    
    func testNoPendingSyncs() {
        // Ensure there are no pending syncs
        syncManager.pendingSyncCount = 0
        
        // Set a known state
        syncManager.syncStatus = .idle
        
        // Try to sync
        syncManager.trySync()
        
        // Verify state didn't change to syncing
        XCTAssertEqual(syncManager.syncStatus, .idle)
    }
    
    func testOnlineStatusChange() {
        // Create expectation for online status changes
        let offlineExpectation = XCTestExpectation(description: "Went offline")
        let onlineExpectation = XCTestExpectation(description: "Came back online")
        
        var offlineDetected = false
        
        // Monitor for changes
        syncManager.$isOnline
            .dropFirst() // Skip initial value
            .sink { isOnline in
                if !isOnline && !offlineDetected {
                    offlineExpectation.fulfill()
                    offlineDetected = true
                } else if isOnline && offlineDetected {
                    onlineExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Change online status
        syncManager.isOnline = false
        
        // Wait for offline expectation
        wait(for: [offlineExpectation], timeout: 1.0)
        
        // Change back to online and attempt sync
        syncManager.isOnline = true
        syncManager.pendingSyncCount = 5
        syncManager.trySync()
        
        // Wait for online expectation
        wait(for: [onlineExpectation], timeout: 1.0)
        
        // Verify sync was attempted after coming back online
        XCTAssertEqual(syncManager.syncStatus, .syncing)
    }
} 