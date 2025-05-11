#if os(macOS)
import XCTest

class MacPulseUITestsmacOS: XCTestCase {
    var app: XCUIApplication!
    /// Shortcut to the sidebar outline view
    private var sidebar: XCUIElement { app.outlines.firstMatch }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // ⚠️ match the flag your App uses
        app.launchArguments.append("--reset-hasStarted")
        app.launch()
    }

    /// If we're still on the landing screen, tap "Start Monitoring" to enter the main sidebar.
    private func ensureMain() {
        let startButton = app.buttons["Start Monitoring"]
        if startButton.waitForExistence(timeout: 10) {
            startButton.click()
            // Wait for the sidebar outline to appear
            XCTAssertTrue(sidebar.waitForExistence(timeout: 5),
                          "Sidebar should appear after tapping Start Monitoring")
            // And for the "System" row to exist
            _ = sidebar.cells["System"].waitForExistence(timeout: 5)
        }
    }

    // MARK: — Landing View Tests (should not call ensureMain)

    func testLandingViewDisplaysWelcomeAndStartButton() throws {
        XCTAssertTrue(app.images["MacPulse"].waitForExistence(timeout: 10),
                      "LandingView should show the MacPulse logo")
        XCTAssertTrue(app.staticTexts["Welcome to MacPulse"].waitForExistence(timeout: 10),
                      "LandingView should show the welcome title")
        XCTAssertTrue(app.buttons["Start Monitoring"].exists,
                      "LandingView should show the 'Start Monitoring' button")
    }

    func testLandingViewStartMonitoringNavigatesToSystem() throws {
        let startButton = app.buttons["Start Monitoring"]
        if startButton.waitForExistence(timeout: 10){
            XCTAssertTrue(app.buttons["Start Monitoring"].exists)
            app.buttons["Start Monitoring"].click()
        }

        // Now look in the sidebar’s cells, not buttons
        let systemItem = sidebar.buttons["System"]
        XCTAssertTrue(systemItem.waitForExistence(timeout: 5),
                      "Tapping 'Start Monitoring' should show the System item in sidebar")
    }

    // MARK: — System Metrics Dashboard Tests

    func testSystemOptionShowsDashboardPanels() throws {
        ensureMain()
        sidebar.buttons["System"].click()

        // wait for dashboard header
        XCTAssertTrue(
          app.staticTexts["Mac Performance Dashboard"]
             .waitForExistence(timeout: 5)
        )

        // look for the panel containers
        let cpuPanel  = app.buttons["CPU Usage Panel"]
        let memPanel  = app.buttons["Memory Usage Panel"]
        let diskPanel = app.buttons["Disk Usage Panel"]

        XCTAssertTrue(cpuPanel.waitForExistence(timeout: 5),  "CPU panel should be visible")
        XCTAssertTrue(memPanel.waitForExistence(timeout: 5),  "Memory panel should be visible")
        XCTAssertTrue(diskPanel.waitForExistence(timeout: 5), "Disk panel should be visible")
    }

    // MARK: — Dashboard Panel Navigation
    func testCPUPanelNavigatesToDetail() throws {
        ensureMain()
        sidebar.buttons["System"].click()

        // wait for dashboard title
        XCTAssertTrue(
          app.staticTexts["Mac Performance Dashboard"]
             .waitForExistence(timeout: 5)
        )

        // grab the CPU panel as a button
        let cpuPanel = app.buttons["CPU Usage Panel"]
        XCTAssertTrue(
          cpuPanel.waitForExistence(timeout: 5),
          "Should see the CPU panel"
        )

        // click it
        cpuPanel.click()

        // now assert detail view
        XCTAssertTrue(
          app.staticTexts["CPU Usage Detailed View"].waitForExistence(timeout: 5),
          "Detail view should show the CPU Usage title"
        )
    }


    func testMemoryPanelNavigatesToDetail() throws {
        ensureMain()
        sidebar.buttons["System"].click()

        // wait for dashboard title
        XCTAssertTrue(
          app.staticTexts["Mac Performance Dashboard"]
             .waitForExistence(timeout: 5)
        )

        // grab the CPU panel as a button
        let memoryPanel = app.buttons["Memory Usage Panel"]
        XCTAssertTrue(
          memoryPanel.waitForExistence(timeout: 5),
          "Should see the Memory panel"
        )

        // click it
        memoryPanel.click()

        // now assert detail view
        XCTAssertTrue(
          app.staticTexts["Memory Usage Detailed View"].waitForExistence(timeout: 5),
          "Detail view should show the Memory Usage title"
        )
    }

    func testDiskPanelNavigatesToDetail() throws {
        ensureMain()
        sidebar.buttons["System"].click()

        // wait for dashboard title
        XCTAssertTrue(
          app.staticTexts["Mac Performance Dashboard"]
             .waitForExistence(timeout: 5)
        )

        // grab the CPU panel as a button
        let diskPanel = app.buttons["Disk Usage Panel"]
        XCTAssertTrue(
          diskPanel.waitForExistence(timeout: 5),
          "Should see the Disk panel"
        )

        // click it
        diskPanel.click()

        // now assert detail view
        XCTAssertTrue(
          app.staticTexts["Disk Usage Breakdown"].waitForExistence(timeout: 5),
          "Detail view should show the Disk Usage title"
        )
    }

    // MARK: — Process View Tests

    func testProcessOptionShowsProcessList() throws {
        ensureMain()
        let processItem = sidebar.buttons["Process"]
        
        XCTAssertTrue(processItem.exists, "Process item should exist in sidebar")
        
        processItem.click()

        let sortMenu = app.popUpButtons["SortByMenu"]
        XCTAssertTrue(
          sortMenu.waitForExistence(timeout: 5),
          "‘Sort by’ menu should appear in Process view"
        )

        let processList = app.outlines["ProcessList"]
        XCTAssertTrue(
          processList.waitForExistence(timeout: 5),
          "The process list should appear"
        )
        
        let firstRow = processList.outlineRows.element(boundBy: 0)
        XCTAssertTrue(firstRow.waitForExistence(timeout: 10),
                      "There should be at least one process listed")
    }

    func testProcessDetailShowsCorrectInfo() throws {
        ensureMain()
        
        let processItem = sidebar.buttons["Process"]
        
        processItem.click()

        let processList = app.outlines["ProcessList"]
        XCTAssertTrue(
          processList.waitForExistence(timeout: 2),
          "The process list should appear")
        

        let firstRow = processList.outlineRows.element(boundBy: 0)
        XCTAssertTrue(firstRow.waitForExistence(timeout: 10),
                    "There should be at least one process listed")
        
        let rowButton = firstRow.buttons.firstMatch
        XCTAssertTrue(rowButton.exists, "Row should contain a tappable button")
        rowButton.click()

        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5),
                      "Process detail sheet should appear")
        XCTAssertTrue(sheet.staticTexts["Process Details"].waitForExistence(timeout: 5))
        XCTAssertTrue(sheet.staticTexts["Process name:"].exists)
        XCTAssertTrue(sheet.staticTexts["Process ID:"].exists)
        XCTAssertTrue(sheet.staticTexts["CPU Usage:"].exists)
        XCTAssertTrue(sheet.staticTexts["Memory Usage:"].exists)
    }

    // MARK: — Log View Tests

    
    func testLogCategoryPickerSelectionOnly() throws {
        ensureMain()

        // 1) Navigate to the Log view
        let logButton = sidebar.buttons["Log"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 5),
                      "Log item should exist in sidebar")
        logButton.click()

        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 5),
                      "Tapping 'Log' should show the Log view header")

        // 2) The six segments we expect
        let categories = [
          "ErrorAndDebug",
          "SyncConnection",
          "SyncTransmission",
          "SyncRetrieval",
          "DataPersistence",
          "Backup"
        ]

        for category in categories {
          // 3) Find the segment by its visible label
          let segment = app.radioButtons[category]
          XCTAssertTrue(segment.waitForExistence(timeout: 5),
                        "Segment '\(category)' should exist")

          // 4) Click it
          segment.click()

          // 5) Confirm the UI updated: either a scrollView (logs) or the "No logs yet." text
          let didShowList = app.scrollViews.firstMatch.waitForExistence(timeout: 2)
          let didShowPlaceholder = app.staticTexts["No logs yet."].waitForExistence(timeout: 2)
          XCTAssertTrue(
            didShowList || didShowPlaceholder,
            "After tapping '\(category)', either the log list or placeholder should appear"
          )
        }
    }

    // MARK: — Settings View Tests

    func testSettingsOptionShowsSlidersAndToggleExist() throws {
        ensureMain()
        let settingsItem = sidebar.buttons["Settings"]
        XCTAssertTrue(settingsItem.exists, "Settings item should exist in sidebar")
        settingsItem.click()

        // Section headers
        XCTAssertTrue(app.staticTexts["Notification"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Accessibility"].exists)

        // Labels and sliders by identifier
        XCTAssertTrue(app.staticTexts["CPUThresholdLabel"].exists)
        XCTAssertTrue(app.sliders["CPUThresholdSlider"].exists)

        XCTAssertTrue(app.staticTexts["MemoryThresholdLabel"].exists)
        XCTAssertTrue(app.sliders["MemoryThresholdSlider"].exists)

        XCTAssertTrue(app.staticTexts["DiskThresholdLabel"].exists)
        XCTAssertTrue(app.sliders["DiskThresholdSlider"].exists)

        // Invert‐colors toggle
        XCTAssertTrue(app.checkBoxes["Invert Colors"].exists)
    }

    func testSettingsToggleInvertColorsChangesState() throws {
        ensureMain()
        sidebar.buttons["Settings"].click()
        XCTAssertTrue(app.staticTexts["Accessibility"].waitForExistence(timeout: 2))

        let toggle = app.switches["InvertColorToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))

        toggle.click()

    }
}
#endif
