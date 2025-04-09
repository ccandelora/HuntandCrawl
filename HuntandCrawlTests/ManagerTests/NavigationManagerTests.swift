import XCTest
import SwiftData
import Combine
@testable import HuntandCrawl

final class NavigationManagerTests: XCTestCase {
    var navigationManager: NavigationManager!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        navigationManager = NavigationManager()
    }
    
    override func tearDownWithError() throws {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        navigationManager = nil
    }
    
    // MARK: - Navigation Path Tests
    
    func testNavigationPathInitialState() {
        XCTAssertTrue(navigationManager.path.isEmpty)
    }
    
    func testNavigateToDestination() {
        // Create expectation for path change
        let expectation = XCTestExpectation(description: "Navigation path updated")
        
        // Monitor for changes
        navigationManager.$path
            .dropFirst() // Skip initial value
            .sink { path in
                if !path.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Navigate to a destination
        navigationManager.path.append(NavigationManager.Destination.profile)
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify path was updated
        XCTAssertFalse(navigationManager.path.isEmpty)
        XCTAssertEqual(navigationManager.path.count, 1)
    }
    
    func testNavigateToHunt() {
        // Create a hunt
        let hunt = Hunt(name: "Test Hunt")
        
        // Create expectation for path change
        let expectation = XCTestExpectation(description: "Navigation path updated with hunt")
        
        // Monitor for changes
        navigationManager.$path
            .dropFirst() // Skip initial value
            .sink { path in
                if !path.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Navigate to the hunt
        navigationManager.navigateToHunt(hunt)
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify path was updated
        XCTAssertFalse(navigationManager.path.isEmpty)
        XCTAssertEqual(navigationManager.path.count, 1)
        
        // Check navigation path contains the hunt
        if case let .hunt(navigatedHunt) = navigationManager.path.first {
            XCTAssertEqual(navigatedHunt.id, hunt.id)
            XCTAssertEqual(navigatedHunt.name, hunt.name)
        } else {
            XCTFail("Navigation path should contain a hunt destination")
        }
    }
    
    func testNavigateToBarCrawl() {
        // Create a bar crawl
        let barCrawl = BarCrawl(name: "Test Bar Crawl")
        
        // Create expectation for path change
        let expectation = XCTestExpectation(description: "Navigation path updated with bar crawl")
        
        // Monitor for changes
        navigationManager.$path
            .dropFirst() // Skip initial value
            .sink { path in
                if !path.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Navigate to the bar crawl
        navigationManager.navigateToBarCrawl(barCrawl)
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify path was updated
        XCTAssertFalse(navigationManager.path.isEmpty)
        XCTAssertEqual(navigationManager.path.count, 1)
        
        // Check navigation path contains the bar crawl
        if case let .barCrawl(navigatedBarCrawl) = navigationManager.path.first {
            XCTAssertEqual(navigatedBarCrawl.id, barCrawl.id)
            XCTAssertEqual(navigatedBarCrawl.name, barCrawl.name)
        } else {
            XCTFail("Navigation path should contain a bar crawl destination")
        }
    }
    
    func testNavigateToTask() {
        // Create a task
        let task = Task(name: "Test Task", pointValue: 100, verificationMethod: .manual)
        
        // Create expectation for path change
        let expectation = XCTestExpectation(description: "Navigation path updated with task")
        
        // Monitor for changes
        navigationManager.$path
            .dropFirst() // Skip initial value
            .sink { path in
                if !path.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Navigate to the task
        navigationManager.navigateToTask(task)
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify path was updated
        XCTAssertFalse(navigationManager.path.isEmpty)
        XCTAssertEqual(navigationManager.path.count, 1)
        
        // Check navigation path contains the task
        if case let .task(navigatedTask) = navigationManager.path.first {
            XCTAssertEqual(navigatedTask.id, task.id)
            XCTAssertEqual(navigatedTask.name, task.name)
        } else {
            XCTFail("Navigation path should contain a task destination")
        }
    }
    
    func testNavigateBack() {
        // Add multiple items to the path
        navigationManager.path.append(NavigationManager.Destination.profile)
        navigationManager.path.append(NavigationManager.Destination.nearbyLocations)
        XCTAssertEqual(navigationManager.path.count, 2)
        
        // Create expectation for path change
        let expectation = XCTestExpectation(description: "Navigation path popped")
        
        // Monitor for changes
        navigationManager.$path
            .dropFirst() // Skip initial state with 2 items
            .sink { path in
                if path.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Navigate back
        navigationManager.navigateBack()
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify path was updated
        XCTAssertEqual(navigationManager.path.count, 1)
        
        // Check the remaining item is the profile destination
        if case .profile = navigationManager.path.first {
            // Test passed
        } else {
            XCTFail("First destination should be profile")
        }
    }
    
    func testNavigateToRoot() {
        // Add multiple items to the path
        navigationManager.path.append(NavigationManager.Destination.profile)
        navigationManager.path.append(NavigationManager.Destination.nearbyLocations)
        navigationManager.path.append(NavigationManager.Destination.createHunt)
        XCTAssertEqual(navigationManager.path.count, 3)
        
        // Create expectation for path change
        let expectation = XCTestExpectation(description: "Navigation path cleared")
        
        // Monitor for changes
        navigationManager.$path
            .dropFirst() // Skip initial state with 3 items
            .sink { path in
                if path.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Navigate to root
        navigationManager.navigateToRoot()
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify path was cleared
        XCTAssertTrue(navigationManager.path.isEmpty)
    }
    
    // MARK: - Sheet Presentation Tests
    
    func testSheetPresentationInitialState() {
        XCTAssertNil(navigationManager.activeSheet)
        XCTAssertFalse(navigationManager.isSheetPresented)
    }
    
    func testPresentSheet() {
        // Create expectation for sheet presentation
        let expectation = XCTestExpectation(description: "Sheet presented")
        
        // Monitor for changes
        navigationManager.$isSheetPresented
            .dropFirst() // Skip initial value
            .sink { isPresented in
                if isPresented {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Present a sheet
        navigationManager.presentSheet(.createTask)
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify sheet is presented
        XCTAssertTrue(navigationManager.isSheetPresented)
        XCTAssertEqual(navigationManager.activeSheet, .createTask)
    }
    
    func testDismissSheet() {
        // First present a sheet
        navigationManager.presentSheet(.createTask)
        XCTAssertTrue(navigationManager.isSheetPresented)
        
        // Create expectation for sheet dismissal
        let expectation = XCTestExpectation(description: "Sheet dismissed")
        
        // Monitor for changes
        navigationManager.$isSheetPresented
            .dropFirst() // Skip initial value (true)
            .sink { isPresented in
                if !isPresented {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Dismiss the sheet
        navigationManager.dismissSheet()
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify sheet is dismissed
        XCTAssertFalse(navigationManager.isSheetPresented)
        XCTAssertNil(navigationManager.activeSheet)
    }
    
    // MARK: - Action Sheet Tests
    
    func testActionSheetInitialState() {
        XCTAssertNil(navigationManager.actionSheetTitle)
        XCTAssertNil(navigationManager.actionSheetMessage)
        XCTAssertTrue(navigationManager.actionSheetButtons.isEmpty)
        XCTAssertFalse(navigationManager.isActionSheetPresented)
    }
    
    func testPresentActionSheet() {
        // Create expectation for action sheet presentation
        let expectation = XCTestExpectation(description: "Action sheet presented")
        
        // Monitor for changes
        navigationManager.$isActionSheetPresented
            .dropFirst() // Skip initial value
            .sink { isPresented in
                if isPresented {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Present an action sheet
        navigationManager.presentActionSheet(
            title: "Test Title",
            message: "Test Message",
            buttons: [
                .default(Text("OK")),
                .cancel()
            ]
        )
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify action sheet is presented
        XCTAssertTrue(navigationManager.isActionSheetPresented)
        XCTAssertEqual(navigationManager.actionSheetTitle, "Test Title")
        XCTAssertEqual(navigationManager.actionSheetMessage, "Test Message")
        XCTAssertEqual(navigationManager.actionSheetButtons.count, 2)
    }
    
    func testDismissActionSheet() {
        // First present an action sheet
        navigationManager.presentActionSheet(
            title: "Test Title",
            message: "Test Message",
            buttons: [.default(Text("OK"))]
        )
        XCTAssertTrue(navigationManager.isActionSheetPresented)
        
        // Create expectation for action sheet dismissal
        let expectation = XCTestExpectation(description: "Action sheet dismissed")
        
        // Monitor for changes
        navigationManager.$isActionSheetPresented
            .dropFirst() // Skip initial value (true)
            .sink { isPresented in
                if !isPresented {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Dismiss the action sheet
        navigationManager.dismissActionSheet()
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify action sheet is dismissed
        XCTAssertFalse(navigationManager.isActionSheetPresented)
    }
    
    // MARK: - Alert Tests
    
    func testAlertInitialState() {
        XCTAssertNil(navigationManager.alertTitle)
        XCTAssertNil(navigationManager.alertMessage)
        XCTAssertFalse(navigationManager.isAlertPresented)
    }
    
    func testPresentAlert() {
        // Create expectation for alert presentation
        let expectation = XCTestExpectation(description: "Alert presented")
        
        // Monitor for changes
        navigationManager.$isAlertPresented
            .dropFirst() // Skip initial value
            .sink { isPresented in
                if isPresented {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Present an alert
        navigationManager.presentAlert(
            title: "Test Alert",
            message: "This is a test alert"
        )
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify alert is presented
        XCTAssertTrue(navigationManager.isAlertPresented)
        XCTAssertEqual(navigationManager.alertTitle, "Test Alert")
        XCTAssertEqual(navigationManager.alertMessage, "This is a test alert")
    }
    
    func testDismissAlert() {
        // First present an alert
        navigationManager.presentAlert(
            title: "Test Alert",
            message: "This is a test alert"
        )
        XCTAssertTrue(navigationManager.isAlertPresented)
        
        // Create expectation for alert dismissal
        let expectation = XCTestExpectation(description: "Alert dismissed")
        
        // Monitor for changes
        navigationManager.$isAlertPresented
            .dropFirst() // Skip initial value (true)
            .sink { isPresented in
                if !isPresented {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Dismiss the alert
        navigationManager.dismissAlert()
        
        // Wait for expectation
        wait(for: [expectation], timeout: 1.0)
        
        // Verify alert is dismissed
        XCTAssertFalse(navigationManager.isAlertPresented)
    }
} 