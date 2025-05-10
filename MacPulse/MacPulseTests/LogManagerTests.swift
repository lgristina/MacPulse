//
//  LogManagerTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 5/2/25.
//

import XCTest
@testable import MacPulse

final class LogManagerTests: XCTestCase {

    var logManager: LogManager!

    override func setUp() {
        super.setUp()
        logManager = LogManager.shared
        logManager.clearLogs()
    }

    override func tearDown() {
        logManager.clearLogs()
        super.tearDown()
    }

    func testLogsAreAppended() {
        // Log the test message
        logManager.log(.errorAndDebug, level: .medium, "Test log message")

        // Create an expectation to wait for log appending
        let expectation = XCTestExpectation(description: "Wait for log to append")

        // Check for the log entry after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Ensure logs have been appended
            XCTAssertGreaterThan(self.logManager.logs.count, 0, "Logs should be appended.")

            // Ensure the first log contains the expected message
            XCTAssertTrue(self.logManager.logs.first?.message.contains("Test log message") ?? false, "Log message should contain 'Test log message'")

            // Fulfill the expectation
            expectation.fulfill()
        }

        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 1.0)
    }


    func testVerbosityFiltering() {
        logManager.verbosityLevelForSyncConnection = .low
        logManager.log(.syncConnection, level: .high, "Should not be logged")

        let expectation = XCTestExpectation(description: "Wait for no logs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.logManager.logs.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testMultipleCategories() {
        logManager.log(.dataPersistence, level: .medium, "Saving data...")
        logManager.log(.syncRetrieval, level: .medium, "Retrieving data...")

        let expectation = XCTestExpectation(description: "Wait for multiple logs")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.logManager.logs.count, 2)
            XCTAssertTrue(self.logManager.logs.contains { $0.category == .dataPersistence })
            XCTAssertTrue(self.logManager.logs.contains { $0.category == .syncRetrieval })
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
