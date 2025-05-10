//
//  NotificationCenterProtocolTests.swift
//  MacPulseTests
//
//  Created by ChatGPT on 05/10/25.
//

import XCTest
import UserNotifications
@testable import MacPulse

final class NotificationCenterProtocolTests: XCTestCase {
    
    var center: NotificationCenterProtocol!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        center = UNUserNotificationCenter.current()
    }

    override func tearDownWithError() throws {
        center = nil
        try super.tearDownWithError()
    }

    func testProtocolConformance() throws {
        // UNUserNotificationCenter.current() should conform to NotificationCenterProtocol
        XCTAssertTrue(center is UNUserNotificationCenter,
                      "UNUserNotificationCenter must implement NotificationCenterProtocol")
    }

    func testAddRequestDoesNotThrow() throws {
        let content = UNMutableNotificationContent()
        content.title = "Test Title"
        content.body  = "Test Body"
        let request = UNNotificationRequest(
            identifier: "test-id",
            content: content,
            trigger: nil
        )

        // Calling add(_:,withCompletionHandler:) should not throw
        XCTAssertNoThrow(center.add(request, withCompletionHandler: nil))
    }
}
