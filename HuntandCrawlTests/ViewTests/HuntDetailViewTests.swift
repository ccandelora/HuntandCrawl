import XCTest
import SwiftUI
import SwiftData
import ViewInspector
@testable import HuntandCrawl

final class HuntDetailViewTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var hunt: Hunt!
    var networkMonitor: MockNetworkMonitor!
    var syncManager: SyncManager!
    var locationManager: MockableLocationManager!
    
    override func setUpWithError() throws {
        // Set up an in-memory SwiftData container for testing
        let schema = Schema([
            Hunt.self,
            Task.self,
            User.self,
            TaskCompletion.self,
            SyncEvent.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        // Create a mock hunt with tasks
        hunt = Hunt(title: "Test Hunt", description: "Test Description", location: "Test Location")
        
        // Add tasks to the hunt
        let task1 = Task(title: "Task 1", description: "Description 1", points: 10, latitude: 25.761681, longitude: -80.191788)
        let task2 = Task(title: "Task 2", description: "Description 2", points: 20, latitude: 25.762681, longitude: -80.192788)
        hunt.tasks = [task1, task2]
        
        modelContext.insert(hunt)
        
        // Create network monitor and sync manager
        networkMonitor = MockNetworkMonitor()
        syncManager = SyncManager(modelContext: modelContext, networkMonitor: networkMonitor)
        
        // Create location manager
        locationManager = MockableLocationManager()
    }
    
    override func tearDownWithError() throws {
        try modelContext.delete(model: TaskCompletion.self)
        try modelContext.delete(model: Task.self)
        try modelContext.delete(model: Hunt.self)
        try modelContext.delete(model: SyncEvent.self)
        modelContainer = nil
        modelContext = nil
        hunt = nil
        networkMonitor = nil
        syncManager = nil
        locationManager = nil
    }
    
    func testHuntDetailViewDisplaysCorrectHuntInfo() throws {
        // Create the view
        let view = HuntDetailView(hunt: hunt, syncManager: syncManager, networkMonitor: networkMonitor, locationManager: locationManager)
        
        // Inspect the view
        let huntTitle = try view.inspect().find(viewWithId: "huntTitle").text().string()
        let huntDescription = try view.inspect().find(viewWithId: "huntDescription").text().string()
        let huntLocation = try view.inspect().find(viewWithId: "huntLocation").text().string()
        
        // Verify the displayed information
        XCTAssertEqual(huntTitle, "Test Hunt")
        XCTAssertEqual(huntDescription, "Test Description")
        XCTAssertEqual(huntLocation, "Test Location")
    }
    
    func testHuntDetailViewDisplaysOfflineStatus() throws {
        // Set network to offline
        networkMonitor.isConnected = false
        
        // Create the view
        let view = HuntDetailView(hunt: hunt, syncManager: syncManager, networkMonitor: networkMonitor, locationManager: locationManager)
        
        // Inspect the view
        let offlineIndicator = try? view.inspect().find(viewWithId: "offlineIndicator")
        
        // Verify offline indicator is present
        XCTAssertNotNil(offlineIndicator)
    }
    
    func testHuntDetailViewHidesOfflineStatusWhenOnline() throws {
        // Set network to online
        networkMonitor.isConnected = true
        
        // Create the view
        let view = HuntDetailView(hunt: hunt, syncManager: syncManager, networkMonitor: networkMonitor, locationManager: locationManager)
        
        // Try to find the offline indicator (should throw an error)
        XCTAssertThrowsError(try view.inspect().find(viewWithId: "offlineIndicator"))
    }
    
    func testHuntDetailViewDisplaysTaskList() throws {
        // Create the view
        let view = HuntDetailView(hunt: hunt, syncManager: syncManager, networkMonitor: networkMonitor, locationManager: locationManager)
        
        // Find the task list
        let taskList = try view.inspect().find(viewWithId: "taskList")
        
        // Get the number of tasks
        let tasksCount = try taskList.forEach().count
        
        // Verify the correct number of tasks is displayed
        XCTAssertEqual(tasksCount, 2)
    }
    
    func testHuntDetailViewTaskCompletionWhenOffline() throws {
        // Set network to offline
        networkMonitor.isConnected = false
        
        // Create the view
        let view = HuntDetailView(hunt: hunt, syncManager: syncManager, networkMonitor: networkMonitor, locationManager: locationManager)
        
        // Set observer for sync events
        let syncExpectation = expectation(description: "Sync event should be created")
        
        // Create a task completion
        let task = hunt.tasks!.first!
        let taskCompletion = TaskCompletion(
            taskId: task.id,
            huntId: hunt.id,
            completedAt: Date(),
            points: task.points,
            verificationMethod: "manual"
        )
        
        // Simulate completion through the view
        view.completeTask(task: task, completion: taskCompletion)
        
        // Fetch sync events
        let descriptor = FetchDescriptor<SyncEvent>()
        let syncEvents = try modelContext.fetch(descriptor)
        
        // Verify a sync event was created
        XCTAssertEqual(syncEvents.count, 1)
        XCTAssertEqual(syncEvents.first?.eventType, "taskCompletion")
    }
    
    func testHuntDetailViewProgressCalculation() throws {
        // Create the view
        let view = HuntDetailView(hunt: hunt, syncManager: syncManager, networkMonitor: networkMonitor, locationManager: locationManager)
        
        // Initially, no tasks are completed
        XCTAssertEqual(view.completedTasksCount, 0)
        XCTAssertEqual(view.progressPercentage, 0)
        
        // Complete the first task
        let task = hunt.tasks!.first!
        let taskCompletion = TaskCompletion(
            taskId: task.id,
            huntId: hunt.id,
            completedAt: Date(),
            points: task.points,
            verificationMethod: "manual"
        )
        modelContext.insert(taskCompletion)
        
        // Simulate view refresh
        view.refreshCompletedTasks()
        
        // Now one task is completed, progress should be 50%
        XCTAssertEqual(view.completedTasksCount, 1)
        XCTAssertEqual(view.progressPercentage, 0.5)
        
        // Complete the second task
        let task2 = hunt.tasks![1]
        let taskCompletion2 = TaskCompletion(
            taskId: task2.id,
            huntId: hunt.id,
            completedAt: Date(),
            points: task2.points,
            verificationMethod: "manual"
        )
        modelContext.insert(taskCompletion2)
        
        // Simulate view refresh
        view.refreshCompletedTasks()
        
        // Now both tasks are completed, progress should be 100%
        XCTAssertEqual(view.completedTasksCount, 2)
        XCTAssertEqual(view.progressPercentage, 1.0)
    }
    
    func testLocationBasedTaskVerification() throws {
        // Create the view
        let view = HuntDetailView(hunt: hunt, syncManager: syncManager, networkMonitor: networkMonitor, locationManager: locationManager)
        
        // Set up user location close to task 1
        let task = hunt.tasks!.first!
        let userLocation = CLLocation(latitude: task.latitude, longitude: task.longitude)
        locationManager.simulateLocationUpdate(location: userLocation)
        
        // Check if task can be verified by location
        let canVerify = view.canVerifyTaskByLocation(task: task)
        
        // Task should be verifiable
        XCTAssertTrue(canVerify)
        
        // Set up user location far from task 2
        let task2 = hunt.tasks![1]
        let farLocation = CLLocation(latitude: task2.latitude + 1.0, longitude: task2.longitude + 1.0)
        locationManager.simulateLocationUpdate(location: farLocation)
        
        // Check if task can be verified by location
        let canVerify2 = view.canVerifyTaskByLocation(task: task2)
        
        // Task should not be verifiable
        XCTAssertFalse(canVerify2)
    }
}

// Add ViewInspector conformance
extension HuntDetailView: Inspectable {}

// Add ViewInspector View ID provider
extension View {
    func viewWithId(_ id: String) -> InspectableView<ViewType.ClassifiedView> {
        return try! find(viewWithId: id)
    }
} 