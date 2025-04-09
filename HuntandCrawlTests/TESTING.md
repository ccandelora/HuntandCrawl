# Testing Documentation for Hunt and Crawl App

This document provides an overview of the testing approach for the Hunt and Crawl application, including test organization, how to run tests, and guidelines for adding new tests.

## Test Organization

The tests are organized into the following categories:

### Model Tests
Located in `HuntandCrawlTests/ModelTests/`
- Tests for data models including Hunt, BarCrawl, Task, TaskCompletion, BarStop, and BarStopVisit
- Focus on CRUD operations, relationships, and business logic

### Manager Tests
Located in `HuntandCrawlTests/ManagerTests/`
- Tests for service classes like LocationManager, NavigationManager, and SyncManager
- Focus on state management, event handling, and service coordination

### View Tests
Located in `HuntandCrawlTests/ViewTests/`
- Tests for SwiftUI views and components
- Uses ViewInspector for UI testing

### Integration Tests
Located in `HuntandCrawlTests/IntegrationTests/`
- Tests for interactions between multiple components
- Ensures components work correctly together

### Test Utilities
Located in `HuntandCrawlTests/TestUtilities/`
- Mock implementations like MockCLLocationManager
- Helper classes for test setup and verification

## Running Tests

### Running from Xcode

1. Open the HuntandCrawl project in Xcode
2. Select the HuntandCrawl scheme
3. Press `⌘+U` or navigate to Product > Test

To run a specific test class:
1. Open the test file in Xcode
2. Click the diamond-shaped icon next to the class declaration or individual test method
3. Select "Test" from the popup menu

### Running from Command Line

```bash
# Run all tests
xcodebuild -scheme HuntandCrawl -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a specific test class
xcodebuild -scheme HuntandCrawl -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:HuntandCrawlTests/LocationManagerTests

# Run a specific test method
xcodebuild -scheme HuntandCrawl -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:HuntandCrawlTests/LocationManagerTests/testLocationUpdate
```

## Test Coverage

To view test coverage:

1. Edit the HuntandCrawl scheme in Xcode
2. Select the "Test" action
3. Check "Gather coverage for" and select "All targets"
4. Run the tests
5. Open the Report navigator (⌘+9) and select the latest test run
6. Click on "Coverage" to see coverage details

## Adding New Tests

### Guidelines for Writing Tests

1. **Test Naming**: Use descriptive names in the format `testWhatIsBeingTested_ConditionUnderTest_ExpectedOutcome`
2. **Arrange-Act-Assert**: Structure tests with clear setup, action, and verification phases
3. **Isolation**: Tests should be independent and not rely on side effects from other tests
4. **Mocking**: Use mocks for external dependencies (e.g., network, location services)
5. **Coverage**: Aim for comprehensive coverage of critical functionality

### Model Test Example

```swift
func testCreateHunt() throws {
    // Arrange - Set up test data
    let hunt = Hunt(name: "Test Hunt", difficulty: "Easy")
    
    // Act - Perform the operation
    context.insert(hunt)
    try context.save()
    
    // Assert - Verify the outcome
    let descriptor = FetchDescriptor<Hunt>(predicate: #Predicate { $0.id == hunt.id })
    let fetchedHunts = try context.fetch(descriptor)
    
    XCTAssertEqual(fetchedHunts.count, 1)
    XCTAssertEqual(fetchedHunts.first?.name, "Test Hunt")
}
```

### Manager Test Example

```swift
func testLocationUpdate() {
    // Arrange - Set up test conditions
    mockCLLocationManager.mockAuthorizationStatus = .authorizedWhenInUse
    
    // Create expectation
    let expectation = XCTestExpectation(description: "Location update received")
    
    // Monitor for changes
    locationManager.$userLocation
        .dropFirst()
        .sink { _ in expectation.fulfill() }
        .store(in: &cancellables)
    
    // Act - Trigger the event
    let mockLocation = CLLocation(latitude: 25.0, longitude: -80.0)
    mockCLLocationManager.simulateLocationUpdate(location: mockLocation)
    
    // Assert - Verify the outcome
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(locationManager.userLocation?.coordinate.latitude, 25.0)
}
```

## Test Mocks and Utilities

### MockCLLocationManager

A mock implementation of CLLocationManager for testing location services without actual device location.

Usage:
```swift
// In setUp
mockCLLocationManager = MockCLLocationManager()
locationManager = LocationManager()
locationManager.locationManager = mockCLLocationManager

// In test
mockCLLocationManager.simulateLocationUpdate(location: CLLocation(latitude: 25.0, longitude: -80.0))
```

## Troubleshooting

### Common Issues

1. **Tests Fail with "No such module" Error**:
   - Make sure the HuntandCrawl module is correctly imported with `@testable import HuntandCrawl`
   - Check that test target settings include proper framework search paths

2. **AsyncTests Failing with Timeout**:
   - Increase the timeout in wait(for:timeout:) calls
   - Check that expectations are being fulfilled correctly

3. **UI Tests Failing**:
   - Ensure ViewInspector is properly configured
   - Check that views conform to Inspectable protocol

### Reporting Test Issues

When reporting test failures:

1. Note the full test name and error message
2. Include relevant parts of the test log
3. Describe the expected behavior
4. List any recent changes that might affect the test 