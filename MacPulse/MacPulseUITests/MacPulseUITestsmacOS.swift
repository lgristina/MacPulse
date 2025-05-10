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
        if startButton.waitForExistence(timeout: 5) {
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
        XCTAssertTrue(app.images["MacPulse"].waitForExistence(timeout: 5),
                      "LandingView should show the MacPulse logo")
        XCTAssertTrue(app.staticTexts["Welcome to MacPulse"].waitForExistence(timeout: 5),
                      "LandingView should show the welcome title")
        XCTAssertTrue(app.buttons["Start Monitoring"].exists,
                      "LandingView should show the 'Start Monitoring' button")
    }

    func testLandingViewStartMonitoringNavigatesToSystem() throws {
        XCTAssertTrue(app.buttons["Start Monitoring"].exists)
        app.buttons["Start Monitoring"].click()

        // Now look in the sidebar’s cells, not buttons
        let systemItem = sidebar.cells["System"]
        XCTAssertTrue(systemItem.waitForExistence(timeout: 5),
                      "Tapping 'Start Monitoring' should show the System item in sidebar")
    }

    // MARK: — System Metrics Dashboard Tests

    func testSystemOptionShowsDashboardPanels() throws {
        ensureMain()
        let systemItem = sidebar.cells["System"]
        XCTAssertTrue(systemItem.exists, "System item should exist in sidebar")
        systemItem.click()

        XCTAssertTrue(app.staticTexts["Mac Performance Dashboard"].waitForExistence(timeout: 5),
                      "Dashboard should show the title")
        XCTAssertTrue(app.staticTexts["CPU Usage"].exists,
                      "CPU Usage panel should be visible")
        XCTAssertTrue(app.staticTexts["Memory Usage"].exists,
                      "Memory Usage panel should be visible")
        XCTAssertTrue(app.staticTexts["Disk Activity"].exists,
                      "Disk Activity panel should be visible")
    }

    func testDashboardPanelNavigatesToDetail() throws {
        ensureMain()
        let systemItem = sidebar.cells["System"]
        systemItem.click()
        XCTAssertTrue(app.staticTexts["Mac Performance Dashboard"].waitForExistence(timeout: 5))

        let cpuLabel = app.staticTexts["CPU Usage"]
        XCTAssertTrue(cpuLabel.exists, "CPU Usage label must exist")
        cpuLabel.click()

        let backButton = app.buttons["Mac Performance Dashboard"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5),
                      "After tapping CPU Usage, a back button labelled with the dashboard title should appear")
        XCTAssertTrue(app.staticTexts["CPU Usage"].exists,
                      "Detail view should display the 'CPU Usage' title")
    }

    // MARK: — Memory & Disk Panel Navigation

    func testMemoryPanelNavigatesToDetail() throws {
        ensureMain()
        let systemItem = sidebar.cells["System"]
        systemItem.click()
        XCTAssertTrue(app.staticTexts["Mac Performance Dashboard"].waitForExistence(timeout: 5))

        let memoryLabel = app.staticTexts["Memory Usage"]
        XCTAssertTrue(memoryLabel.exists, "Memory Usage panel must exist")
        memoryLabel.click()

        let backButton = app.buttons["Mac Performance Dashboard"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5),
                      "Back button labelled with dashboard title should appear")
        XCTAssertTrue(app.staticTexts["Memory Usage"].exists,
                      "Detail view should display the 'Memory Usage' title")
    }

    func testDiskPanelNavigatesToDetail() throws {
        ensureMain()
        let systemItem = sidebar.cells["System"]
        systemItem.click()
        XCTAssertTrue(app.staticTexts["Mac Performance Dashboard"].waitForExistence(timeout: 5),
                      "Dashboard title should be visible")

        let diskLabel = app.staticTexts["Disk Activity"]
        XCTAssertTrue(diskLabel.exists, "Disk Activity panel must exist")
        diskLabel.click()

        XCTAssertTrue(app.staticTexts["Disk Usage Breakdown"].waitForExistence(timeout: 5),
                      "Detail view should show 'Disk Usage Breakdown' title")
        let usedEntry = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Used:")).firstMatch
        XCTAssertTrue(usedEntry.exists, "Used: label should be visible in Disk detail")
        let freeEntry = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Free:")).firstMatch
        XCTAssertTrue(freeEntry.exists, "Free: label should be visible in Disk detail")
    }

    // MARK: — Process View Tests

    func testProcessOptionShowsProcessList() throws {
        ensureMain()
        let processItem = sidebar.cells["Process"]
        XCTAssertTrue(processItem.exists, "Process item should exist in sidebar")
        processItem.click()

        let sortMenuButton = app.buttons["Sort by"]
        XCTAssertTrue(sortMenuButton.exists, "\"Sort by\" menu should appear in Process view")

        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5),
                      "Selecting 'Process' should show the process list")
        let firstCell = table.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.exists,
                      "There should be at least one process listed in the table")
    }

    func testProcessDetailShowsCorrectInfo() throws {
        ensureMain()
        let processItem = sidebar.cells["Process"]
        processItem.click()

        let table = app.tables.firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        let firstRowButton = table.buttons.element(boundBy: 0)
        XCTAssertTrue(firstRowButton.exists, "There should be a tappable process row")
        firstRowButton.click()

        let sheet = app.sheets.firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5),
                      "Process detail sheet should appear")
        XCTAssertTrue(sheet.staticTexts["Process Details"].exists)
        XCTAssertTrue(sheet.staticTexts["Process name:"].exists)
        XCTAssertTrue(sheet.staticTexts["Process ID:"].exists)
        XCTAssertTrue(sheet.staticTexts["CPU Usage:"].exists)
        XCTAssertTrue(sheet.staticTexts["Memory Usage:"].exists)
    }

    // MARK: — Log View Tests

    func testLogOptionShowsLogList() throws {
        ensureMain()
        let logItem = sidebar.cells["Log"]
        XCTAssertTrue(logItem.exists, "Log item should exist in sidebar")
        logItem.click()

        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 5),
                      "Selecting 'Log' should navigate to the log view")
        if app.staticTexts["No logs yet."].exists {
            XCTAssertTrue(app.staticTexts["No logs yet."].exists,
                          "When there are no logs, it should show a placeholder")
        } else {
            let logText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "INFO")).firstMatch
            XCTAssertTrue(logText.exists, "Log content should be visible in the log view")
        }
    }

    func testLogOptionShowsLogViewElements() throws {
        ensureMain()
        let logItem = sidebar.cells["Log"]
        logItem.click()

        XCTAssertTrue(app.staticTexts["Log"].waitForExistence(timeout: 5),
                      "Log view should display the ‘Log’ title")
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.exists, "Category picker should exist in Log view")
        let defaultSegment = picker.buttons["Error & Debug"]
        XCTAssertTrue(defaultSegment.exists && defaultSegment.isSelected,
                      "Default segment (‘Error & Debug’) should be selected")
        XCTAssertTrue(app.staticTexts["No logs yet."].exists,
                      "When there are no logs, it should show a placeholder")
    }

    func testLogCategoryFilteringKeepsPlaceholder() throws {
        ensureMain()
        let picker = app.segmentedControls.firstMatch
        let categories = picker.buttons.allElementsBoundByIndex.map { $0.label }
        for category in categories where category != "Error & Debug" {
            let segment = picker.buttons[category]
            segment.click()
            XCTAssertTrue(segment.isSelected,
                          "Tapping ‘\(category)’ should select that segment")
            XCTAssertTrue(app.staticTexts["No logs yet."].exists,
                          "Still shows placeholder when category has no logs")
        }
    }

    // MARK: — Settings View Tests

    func testSettingsOptionShowsSlidersAndToggle() throws {
        ensureMain()
        let settingsItem = sidebar.cells["Settings"]
        XCTAssertTrue(settingsItem.exists, "Settings item should exist in sidebar")
        settingsItem.click()

        XCTAssertTrue(app.staticTexts["Notification"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Accessibility"].exists)

        XCTAssertTrue(app.staticTexts["CPU Alert ≥ 50%"].exists)
        XCTAssertTrue(app.staticTexts["Memory Alert ≥ 50%"].exists)
        XCTAssertTrue(app.staticTexts["Disk Alert ≥ 90%"].exists)

        let cpuSlider = app.sliders.element(boundBy: 0)
        XCTAssertTrue(cpuSlider.exists)
        let memSlider = app.sliders.element(boundBy: 1)
        XCTAssertTrue(memSlider.exists)
        let diskSlider = app.sliders.element(boundBy: 2)
        XCTAssertTrue(diskSlider.exists)

        let invertCheckbox = app.checkBoxes["Invert Colors"]
        XCTAssertTrue(invertCheckbox.exists)
    }

    func testSettingsToggleInvertColorsChangesState() throws {
        ensureMain()
        let settingsItem = sidebar.cells["Settings"]
        settingsItem.click()

        let invertCheckbox = app.checkBoxes["Invert Colors"]
        XCTAssertEqual(invertCheckbox.value as? String, "0")
        invertCheckbox.click()
        XCTAssertEqual(invertCheckbox.value as? String, "1")
    }
}
#endif
