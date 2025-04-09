import XCTest
import SwiftUI
import ViewInspector
@testable import HuntandCrawl

extension SyncStatusView: Inspectable {}

final class SyncStatusViewTests: XCTestCase {
    
    func testIdleStatusWithNoPendingItems() throws {
        // Set up the view with idle status and no pending items
        let view = SyncStatusView(
            syncStatus: .constant(.idle),
            pendingSyncCount: .constant(0)
        )
        
        // Inspect the view
        let text = try view.inspect().find(text: "Up to date")
        XCTAssertNotNil(text)
        
        // There should be no pending count text
        let pendingText = try? view.inspect().find(text: "0 pending")
        XCTAssertNil(pendingText, "Pending count should not be shown when there are no pending items")
    }
    
    func testIdleStatusWithPendingItems() throws {
        // Set up the view with idle status and pending items
        let view = SyncStatusView(
            syncStatus: .constant(.idle),
            pendingSyncCount: .constant(5)
        )
        
        // Inspect the view
        let statusText = try view.inspect().find(text: "Sync Needed")
        XCTAssertNotNil(statusText)
        
        // Pending count should be shown
        let pendingText = try view.inspect().find(text: "5 pending")
        XCTAssertNotNil(pendingText)
    }
    
    func testSyncingStatus() throws {
        // Set up the view with syncing status
        let view = SyncStatusView(
            syncStatus: .constant(.syncing),
            pendingSyncCount: .constant(3)
        )
        
        // Inspect the view
        let text = try view.inspect().find(text: "Syncing (3)...")
        XCTAssertNotNil(text)
        
        // Icon should be the syncing icon
        let iconName = try view.inspect().find(viewWithId: "statusIcon").image().name()
        XCTAssertEqual(iconName, "arrow.triangle.2.circlepath.circle")
    }
    
    func testSyncedStatus() throws {
        // Set up the view with synced status
        let view = SyncStatusView(
            syncStatus: .constant(.synced),
            pendingSyncCount: .constant(0)
        )
        
        // Inspect the view
        let text = try view.inspect().find(text: "Sync Complete")
        XCTAssertNotNil(text)
        
        // Icon should be the checkmark icon
        let iconName = try view.inspect().find(viewWithId: "statusIcon").image().name()
        XCTAssertEqual(iconName, "checkmark.circle.fill")
        
        // Background color should be green tinted
        let hStack = try view.inspect().hStack()
        let backgroundColor = try hStack.background().color().value()
        
        // This is a simple check that the color has a green component
        XCTAssertTrue(backgroundColor.green > backgroundColor.red)
        XCTAssertTrue(backgroundColor.green > backgroundColor.blue)
    }
    
    func testOfflineStatus() throws {
        // Set up the view with offline status
        let view = SyncStatusView(
            syncStatus: .constant(.offline),
            pendingSyncCount: .constant(2)
        )
        
        // Inspect the view
        let text = try view.inspect().find(text: "Offline Mode (2 pending)")
        XCTAssertNotNil(text)
        
        // Icon should be the wifi slash icon
        let iconName = try view.inspect().find(viewWithId: "statusIcon").image().name()
        XCTAssertEqual(iconName, "wifi.slash")
        
        // Background color should be orange tinted
        let hStack = try view.inspect().hStack()
        let backgroundColor = try hStack.background().color().value()
        
        // This is a simple check that the color has a higher red and green component (orange)
        XCTAssertTrue(backgroundColor.red > backgroundColor.blue)
        XCTAssertTrue(backgroundColor.green > backgroundColor.blue)
    }
    
    func testErrorStatus() throws {
        // Set up the view with error status
        let view = SyncStatusView(
            syncStatus: .constant(.error("Connection failed")),
            pendingSyncCount: .constant(0)
        )
        
        // Inspect the view
        let text = try view.inspect().find(text: "Sync Failed: Connection failed")
        XCTAssertNotNil(text)
        
        // Icon should be the error icon
        let iconName = try view.inspect().find(viewWithId: "statusIcon").image().name()
        XCTAssertEqual(iconName, "xmark.circle.fill")
        
        // Background color should be red tinted
        let hStack = try view.inspect().hStack()
        let backgroundColor = try hStack.background().color().value()
        
        // This is a simple check that the color has a higher red component
        XCTAssertTrue(backgroundColor.red > backgroundColor.green)
        XCTAssertTrue(backgroundColor.red > backgroundColor.blue)
    }
    
    func testAnimationOnStateChange() throws {
        // Create a view with initial state
        let syncStatus = Binding<SyncManager.SyncStatus>(
            get: { .idle },
            set: { _ in }
        )
        let pendingCount = Binding<Int>(
            get: { 0 },
            set: { _ in }
        )
        
        let view = SyncStatusView(
            syncStatus: syncStatus,
            pendingSyncCount: pendingCount
        )
        
        // Inspect the view for animation
        let hStack = try view.inspect().hStack()
        let hasAnimation = try hStack.animation().isPresent()
        
        XCTAssertTrue(hasAnimation, "View should have animation applied")
    }
} 