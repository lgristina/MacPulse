import XCTest

class MacPulseUITestsmacOS: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testHomeOptionShowsLogo() throws {
        let homeButton = app.descendants(matching: .button)["Home"]
        XCTAssertTrue(homeButton.exists, "Home button should exist")
        homeButton.click()
        XCTAssertTrue(app.images["MacPulse"].waitForExistence(timeout: 1),
                      "Selecting 'Home' should show the MacPulse logo")
    }

    func testHomeDetailShowsLogo() throws {
        XCTAssertTrue(app.images["MacPulse"].waitForExistence(timeout: 1),
                      "The MacPulse logo should appear in the Home pane")
    }

    func testSystemOptionShowsDashboard() throws {
        let systemButton = app.descendants(matching: .button)["System"]
        XCTAssertTrue(systemButton.exists, "System button should exist")
        systemButton.click()
        XCTAssertTrue(app.staticTexts["Mac Performance Dashboard"]
                        .waitForExistence(timeout: 1),
                      "Selecting 'System' should show the performance dashboard")
    }

    func testProcessOptionShowsProcessList() throws {
        let processButton = app.descendants(matching: .button)["Process"]
        XCTAssertTrue(processButton.exists, "Process button should exist")
        processButton.click()
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 1),
                      "Selecting 'Process' should show the process list")
    }

    func testLogOptionShowsLogList() throws {
        let logButton = app.descendants(matching: .button)["Log"]
        XCTAssertTrue(logButton.exists, "Log button should exist")
        logButton.click()
        XCTAssertTrue(app.tables.firstMatch.waitForExistence(timeout: 1),
                      "Selecting 'Log' should show the log view")
    }
}
