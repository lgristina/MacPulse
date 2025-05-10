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
        // Bypass the landing screen in UI tests; your app must detect this arg and set hasStarted = true
        app.launchArguments += ["-UITest_skipLanding"]
        app.launch()
    }

    // MARK: — Landing View (only if you test without skip)

    func testLandingViewDisplaysLogoTitleAndPlaceholder() throws {
        // If you run without the skip argument, this covers LandingView
        // (so you can comment out the skip launchArg in setUp if you want to test it instead)
        XCTAssertTrue(app.images["MacPulse"].exists,           "LandingView should show the app icon")
        XCTAssertTrue(app.staticTexts["Monitor a Mac from your iPhone or iPad"]
                        .exists,                                "LandingView should show the welcome text")
        XCTAssertTrue(app.staticTexts["No peers found yet"]
                        .exists,                                "LandingView should show placeholder when no peers")
    }

    // MARK: — Root List

    func testRootListShowsAllTabs() throws {
        // After skipping landing, you should land on your main navigation (List or TabBar)
        XCTAssertTrue(app.buttons["Home"].exists)
        XCTAssertTrue(app.buttons["System"].exists)
        XCTAssertTrue(app.buttons["Process"].exists)
        XCTAssertTrue(app.buttons["Log"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
        // And the nav title is your app name
        XCTAssertTrue(app.navigationBars["MacPulse"].exists)
    }

    // MARK: — Settings View

    func testSettingsOptionShowsSlidersAndToggle() throws {
        app.buttons["Settings"].tap()

        // Section headers
        XCTAssertTrue(app.staticTexts["Notifications"].exists)
        XCTAssertTrue(app.staticTexts["Accessibility"].exists)

        // Slider labels (defaults: CPU 50%, Memory 50%, Disk 90%)
        XCTAssertTrue(app.staticTexts["CPU Alert ≥ 50%"].exists)
        XCTAssertTrue(app.staticTexts["Memory Alert ≥ 50%"].exists)
        XCTAssertTrue(app.staticTexts["Disk Alert ≥ 90%"].exists)

        // Sliders themselves
        let sliders = app.sliders
        XCTAssertEqual(sliders.count, 3, "There should be 3 sliders on iOS Settings")
        
        // Toggle
        let invertToggle = app.switches["Invert Colors"]
        XCTAssertTrue(invertToggle.exists, "Invert Colors toggle should exist")
    }

    func testSettingsToggleInvertColorsChangesAppearance() throws {
        app.buttons["Settings"].tap()
        let invertToggle = app.switches["Invert Colors"]
        XCTAssertEqual(invertToggle.value as? String, "0", "Invert Colors off by default")
        invertToggle.tap()
        XCTAssertEqual(invertToggle.value as? String, "1", "Invert Colors on after tap")
    }

    // MARK: — System (Dashboard)

    func testSystemOptionShowsDashboardPanels() throws {
        app.buttons["System"].tap()

        // Dashboard header
        XCTAssertTrue(app.staticTexts["Companion Dashboard"]
                        .waitForExistence(timeout: 1),
                      "Should show the iOS dashboard title")

        // Panels
        XCTAssertTrue(app.staticTexts["CPU Usage"].exists)
        XCTAssertTrue(app.staticTexts["Memory Usage"].exists)
    }

    // MARK: — Process

    func testProcessOptionShowsProcessList() throws {
        app.buttons["Process"].tap()

        // Nav title
        XCTAssertTrue(app.navigationBars["Running Processes"].exists)

        // List exists
        let table = app.tables.firstMatch
        XCTAssertTrue(table.exists, "Process view should show a table")

        // At least one row
        XCTAssertTrue(table.cells.element(boundBy: 0).exists,
                      "There should be at least one process in the list")
    }

    func testProcessDetailShowsCorrectInfo() throws {
        app.buttons["Process"].tap()
        let firstCell = app.tables.firstMatch.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists)
        firstCell.tap()

        // Detail view title and labels
        XCTAssertTrue(app.staticTexts["Process Details"].exists)
        XCTAssertTrue(app.staticTexts["Process name:"].exists)
        XCTAssertTrue(app.staticTexts["Process ID:"].exists)
        XCTAssertTrue(app.staticTexts["CPU Usage:"].exists)
        XCTAssertTrue(app.staticTexts["Memory Usage:"].exists)
    }

    // MARK: — Log

    func testLogOptionShowsLogViewElements() throws {
        app.buttons["Log"].tap()

        // Nav title
        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 1))

        // Segmented picker
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.exists, "Category picker should exist")
        // Default segment
        let defaultSeg = picker.buttons["Error & Debug"]
        XCTAssertTrue(defaultSeg.exists && defaultSeg.isSelected)

        // Placeholder
        XCTAssertTrue(app.staticTexts["No logs yet."].exists,
                      "Placeholder should show when no logs")
    }

    func testLogCategoryFilteringKeepsPlaceholder() throws {
        app.buttons["Log"].tap()
        let picker = app.segmentedControls.firstMatch

        // Tap each other segment and verify placeholder remains
        for idx in 0..<picker.buttons.count {
            let btn = picker.buttons.element(boundBy: idx)
            btn.tap()
            XCTAssertTrue(btn.isSelected)
            XCTAssertTrue(app.staticTexts["No logs yet."].exists)
        }
    }
}
#endif
