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
        logManager.log(.errorAndDebug, level: .medium, "Test log message")

        let expectation = XCTestExpectation(description: "Wait for log to append")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.logManager.logs.count, 1)
            XCTAssertTrue(self.logManager.logs.first?.message.contains("Test log message") ?? false)
            expectation.fulfill()
        }

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
