import XCTest

class MacPulseUITestsmacOS: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testSidebarOptionsExist() throws {
        // Sidebar should list the four options
        XCTAssertTrue(app.staticTexts["Home"].exists)
        XCTAssertTrue(app.staticTexts["System"].exists)
        XCTAssertTrue(app.staticTexts["Process"].exists)
        XCTAssertTrue(app.staticTexts["Log"].exists)
    }

    func testHomeDetailShowsLogo() throws {
        // Default selection is “Home” → shows the MacPulse image
        XCTAssertTrue(app.images["MacPulse"].waitForExistence(timeout: 1),
                      "The MacPulse logo should appear in the Home pane")
    }

    func testSystemOptionShowsDashboard() throws {
        app.staticTexts["System"].click()
        // System metrics dashboard title
        XCTAssertTrue(app.staticTexts["Mac Performance Dashboard"]
                        .waitForExistence(timeout: 1),
                      "Selecting ’System’ should show the performance dashboard")
    }

    func testProcessOptionShowsProcessList() throws {
        app.staticTexts["Process"].click()
        // We expect a List (table) of processes to appear
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 1),
                      "Selecting ’Process’ should show the process list")
    }

    func testLogOptionShowsLogList() throws {
        app.staticTexts["Log"].click()
        // We expect a List (table) of log entries to appear
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 1),
                      "Selecting ’Log’ should show the log view")
    }
}
