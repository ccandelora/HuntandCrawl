import XCTest
import SwiftData
import Combine
@testable import HuntandCrawl

final class SyncManagerTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var networkMonitor: MockNetworkMonitor!
    var syncManager: SyncManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        // Set up an in-memory SwiftData container for testing
        let schema = Schema([
            Hunt.self,
            Task.self,
            User.self,
            BarCrawl.self,
            BarStop.self,
            Team.self,
            SyncEvent.self,
            TaskCompletion.self,
            BarStopVisit.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // Create a mock network monitor
        networkMonitor = MockNetworkMonitor()
        
        // Initialize the sync manager with the mock network monitor
        syncManager = SyncManager(modelContext: modelContext, networkMonitor: networkMonitor)
    }
    
    override func tearDownWithError() throws {
        // Clear any test data
        try modelContext.delete(model: SyncEvent.self)
        try modelContext.delete(model: Hunt.self)
        try modelContext.delete(model: Task.self)
        try modelContext.delete(model: TaskCompletion.self)
        try modelContext.delete(model: BarCrawl.self)
        try modelContext.delete(model: BarStop.self)
        try modelContext.delete(model: BarStopVisit.self)
        try modelContext.delete(model: User.self)
        try modelContext.delete(model: Team.self)
        
        cancellables.removeAll()
        syncManager = nil
        networkMonitor = nil
        modelContainer = nil
        modelContext = nil
    }
    
    func testCreateSyncEvent() throws {
        // Test creating a sync event
        let eventData: [String: Any] = [
            "eventType": "taskCompletion",
            "entityId": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Create a sync event
        syncManager.createSyncEvent(type: "taskCompletion", entityId: UUID(), data: eventData)
        
        // Fetch all sync events
        let descriptor = FetchDescriptor<SyncEvent>()
        let syncEvents = try modelContext.fetch(descriptor)
        
        // Verify an event was created
        XCTAssertEqual(syncEvents.count, 1)
        XCTAssertEqual(syncEvents.first?.eventType, "taskCompletion")
    }
    
    func testNetworkStatusChangeTriggersSync() throws {
        // Create an expectation for sync to be triggered
        let syncExpectation = expectation(description: "Sync should be triggered when network becomes available")
        
        // Monitor sync status updates
        syncManager.$isSyncing
            .dropFirst() // Skip initial value
            .sink { isSyncing in
                if isSyncing {
                    syncExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Create some sync events
        for _ in 1...3 {
            let eventData: [String: Any] = [
                "eventType": "taskCompletion",
                "entityId": UUID().uuidString,
                "timestamp": Date().timeIntervalSince1970
            ]
            syncManager.createSyncEvent(type: "taskCompletion", entityId: UUID(), data: eventData)
        }
        
        // Set network to offline
        networkMonitor.isConnected = false
        
        // Wait briefly
        usleep(100000) // 0.1 seconds
        
        // Then set network to online, which should trigger sync
        networkMonitor.isConnected = true
        
        // Wait for the expectation to be fulfilled
        wait(for: [syncExpectation], timeout: 2.0)
    }
    
    func testTaskCompletionSync() throws {
        // Create a hunt
        let hunt = Hunt(title: "Test Hunt", description: "Test Description", location: "Test Location")
        modelContext.insert(hunt)
        
        // Create a task
        let task = Task(title: "Test Task", description: "Test Description", points: 10, latitude: 25.0, longitude: -80.0)
        hunt.tasks = [task]
        
        // Create a task completion
        let taskCompletion = TaskCompletion(
            taskId: task.id,
            huntId: hunt.id,
            completedAt: Date(),
            points: 10,
            verificationMethod: "manual"
        )
        modelContext.insert(taskCompletion)
        
        // Save the task completion as a sync event
        let eventData: [String: Any] = [
            "taskId": taskCompletion.taskId.uuidString,
            "huntId": taskCompletion.huntId.uuidString,
            "completedAt": taskCompletion.completedAt.timeIntervalSince1970,
            "points": taskCompletion.points,
            "verificationMethod": taskCompletion.verificationMethod
        ]
        
        syncManager.createSyncEvent(type: "taskCompletion", entityId: taskCompletion.id, data: eventData)
        
        // Verify sync event was created
        let descriptor = FetchDescriptor<SyncEvent>()
        let syncEvents = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(syncEvents.count, 1)
        XCTAssertEqual(syncEvents.first?.eventType, "taskCompletion")
        
        // Test sync process (mock API call)
        let syncExpectation = expectation(description: "Sync process should complete")
        
        // Create a mock API service
        let apiService = MockAPIService()
        syncManager.apiService = apiService
        
        // Start sync and wait for it to complete
        syncManager.syncPendingEvents()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    syncExpectation.fulfill()
                case .failure(let error):
                    XCTFail("Sync failed with error: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [syncExpectation], timeout: 2.0)
        
        // Verify API call was made
        XCTAssertEqual(apiService.syncCallCount, 1)
        
        // Verify sync event was removed after successful sync
        let updatedDescriptor = FetchDescriptor<SyncEvent>()
        let updatedSyncEvents = try modelContext.fetch(updatedDescriptor)
        
        XCTAssertEqual(updatedSyncEvents.count, 0)
    }
    
    func testBarStopVisitSync() throws {
        // Create a bar crawl
        let barCrawl = BarCrawl(name: "Test Bar Crawl", description: "Test Description", theme: "Test Theme")
        modelContext.insert(barCrawl)
        
        // Create a bar stop
        let barStop = BarStop(name: "Test Bar", description: "Test Description", specialDrink: "Test Drink", latitude: 25.0, longitude: -80.0)
        barCrawl.barStops = [barStop]
        
        // Create a bar stop visit
        let barStopVisit = BarStopVisit(
            barStopId: barStop.id,
            barCrawlId: barCrawl.id,
            visitedAt: Date(),
            verificationMethod: "location"
        )
        modelContext.insert(barStopVisit)
        
        // Save the bar stop visit as a sync event
        let eventData: [String: Any] = [
            "barStopId": barStopVisit.barStopId.uuidString,
            "barCrawlId": barStopVisit.barCrawlId.uuidString,
            "visitedAt": barStopVisit.visitedAt.timeIntervalSince1970,
            "verificationMethod": barStopVisit.verificationMethod
        ]
        
        syncManager.createSyncEvent(type: "barStopVisit", entityId: barStopVisit.id, data: eventData)
        
        // Verify sync event was created
        let descriptor = FetchDescriptor<SyncEvent>()
        let syncEvents = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(syncEvents.count, 1)
        XCTAssertEqual(syncEvents.first?.eventType, "barStopVisit")
        
        // Test sync process (mock API call)
        let syncExpectation = expectation(description: "Sync process should complete")
        
        // Create a mock API service
        let apiService = MockAPIService()
        syncManager.apiService = apiService
        
        // Start sync and wait for it to complete
        syncManager.syncPendingEvents()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    syncExpectation.fulfill()
                case .failure(let error):
                    XCTFail("Sync failed with error: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [syncExpectation], timeout: 2.0)
        
        // Verify API call was made
        XCTAssertEqual(apiService.syncCallCount, 1)
        
        // Verify sync event was removed after successful sync
        let updatedDescriptor = FetchDescriptor<SyncEvent>()
        let updatedSyncEvents = try modelContext.fetch(updatedDescriptor)
        
        XCTAssertEqual(updatedSyncEvents.count, 0)
    }
    
    func testSyncFailure() throws {
        // Create a sync event
        let eventData: [String: Any] = [
            "eventType": "taskCompletion",
            "entityId": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        syncManager.createSyncEvent(type: "taskCompletion", entityId: UUID(), data: eventData)
        
        // Test sync process with API failure
        let syncExpectation = expectation(description: "Sync process should fail")
        
        // Create a mock API service that fails
        let apiService = MockAPIService(shouldFail: true)
        syncManager.apiService = apiService
        
        // Start sync and expect it to fail
        syncManager.syncPendingEvents()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Sync should have failed")
                case .failure:
                    syncExpectation.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [syncExpectation], timeout: 2.0)
        
        // Verify sync event was not removed after failed sync
        let updatedDescriptor = FetchDescriptor<SyncEvent>()
        let updatedSyncEvents = try modelContext.fetch(updatedDescriptor)
        
        XCTAssertEqual(updatedSyncEvents.count, 1)
    }
    
    func testMultipleSyncEvents() throws {
        // Create multiple sync events of different types
        let taskCompletion = TaskCompletion(
            taskId: UUID(),
            huntId: UUID(),
            completedAt: Date(),
            points: 10,
            verificationMethod: "manual"
        )
        modelContext.insert(taskCompletion)
        
        let barStopVisit = BarStopVisit(
            barStopId: UUID(),
            barCrawlId: UUID(),
            visitedAt: Date(),
            verificationMethod: "location"
        )
        modelContext.insert(barStopVisit)
        
        // Create sync events
        syncManager.createSyncEvent(
            type: "taskCompletion", 
            entityId: taskCompletion.id, 
            data: ["type": "taskCompletion"]
        )
        
        syncManager.createSyncEvent(
            type: "barStopVisit", 
            entityId: barStopVisit.id, 
            data: ["type": "barStopVisit"]
        )
        
        // Verify sync events were created
        let descriptor = FetchDescriptor<SyncEvent>()
        let syncEvents = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(syncEvents.count, 2)
        
        // Test batch sync process
        let syncExpectation = expectation(description: "Sync process should complete")
        
        // Create a mock API service
        let apiService = MockAPIService()
        syncManager.apiService = apiService
        
        // Start sync and wait for it to complete
        syncManager.syncPendingEvents()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    syncExpectation.fulfill()
                case .failure(let error):
                    XCTFail("Sync failed with error: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [syncExpectation], timeout: 2.0)
        
        // Verify API calls were made
        XCTAssertEqual(apiService.syncCallCount, 2)
        
        // Verify sync events were removed after successful sync
        let updatedDescriptor = FetchDescriptor<SyncEvent>()
        let updatedSyncEvents = try modelContext.fetch(updatedDescriptor)
        
        XCTAssertEqual(updatedSyncEvents.count, 0)
    }
}

// MARK: - Mock Classes for Testing

class MockNetworkMonitor: NetworkMonitor {
    override init() {
        super.init()
    }
    
    override var isConnected: Bool {
        get {
            return _isConnected
        }
        set {
            _isConnected = newValue
            connectionStateDidChange()
        }
    }
    
    private var _isConnected: Bool = true
    
    private func connectionStateDidChange() {
        NotificationCenter.default.post(name: .connectivityStatusChanged, object: nil)
    }
}

class MockAPIService: APIService {
    var syncCallCount = 0
    var shouldFail: Bool
    
    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }
    
    override func syncEvent(_ event: SyncEvent) -> AnyPublisher<Bool, Error> {
        syncCallCount += 1
        
        if shouldFail {
            return Fail(error: NSError(domain: "MockAPIError", code: 500, userInfo: nil))
                .eraseToAnyPublisher()
        } else {
            return Just(true)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
} 