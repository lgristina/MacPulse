//
//  MacPulseUITestsiOS.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/20/25.
//
#if os(iOS)
import XCTest

class MacPulseiOSUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testRootListShowsAllOptions() throws {
        // Root list should show “Home”, “System”, “Process”, “Log”
        XCTAssertTrue(app.staticTexts["Home"].exists)
        XCTAssertTrue(app.staticTexts["System"].exists)
        XCTAssertTrue(app.staticTexts["Process"].exists)
        XCTAssertTrue(app.staticTexts["Log"].exists)
        // And the nav title should be “MacPulse”
        XCTAssertTrue(app.navigationBars["MacPulse"].exists)
    }

    func testHomeDetailView() throws {
        app.staticTexts["Home"].tap()
        // Should navigate to the Home detail
        XCTAssertTrue(app.staticTexts["Detail for Home"]
                        .waitForExistence(timeout: 1),
                      "Tapping Home should show its detail view")
        XCTAssertTrue(app.images["MacPulse"].exists,
                      "Home detail must show the MacPulse logo")
        XCTAssertTrue(app.navigationBars["Home"].exists)
    }

    func testSystemDetailView() throws {
        app.staticTexts["System"].tap()
        // Should navigate to the Companion Dashboard
        XCTAssertTrue(app.staticTexts["Companion Dashboard"]
                        .waitForExistence(timeout: 1),
                      "Tapping System should show the iOS dashboard")
        // And its two panels
        XCTAssertTrue(app.staticTexts["CPU Usage"].exists)
        XCTAssertTrue(app.staticTexts["Memory Usage"].exists)
        XCTAssertTrue(app.navigationBars["System"].exists)
    }

    func testProcessDetailView() throws {
        app.staticTexts["Process"].tap()
        // Detail for Process
        XCTAssertTrue(app.staticTexts["Detail for Process"]
                        .waitForExistence(timeout: 1),
                      "Tapping Process should show its detail view")
        // Expect a table of processes
        XCTAssertTrue(app.tables.firstMatch.exists,
                      "Process detail must show a list of processes")
        XCTAssertTrue(app.navigationBars["Process"].exists)
    }
    
    
    func testLogDetailView() throws {
        app.staticTexts["Log"].tap()
        
        // Wait for the nav bar
        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 1),
                      "Should navigate to the Log detail view")

        // If there are no logs, the placeholder text should exist
        if app.staticTexts["No logs yet."].exists {
            XCTAssertTrue(app.staticTexts["No logs yet."].exists,
                          "When there are no logs, it should show a placeholder")
        } else {
            // Otherwise, assert at least one log item exists
            // Option 1: Look for known log text if you're injecting one during testing
             XCTAssertTrue(app.staticTexts["[INFO] ContentView appeared - App Launched (macOS)."].exists)

            // Option 2: Loosely verify some log content exists
            let logText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "INFO")).firstMatch
            XCTAssertTrue(logText.exists, "Log content should be visible in the log view")
        }
    }
}
#endif
