//
//  NotificationManagerTests.swift
//  MacPulseTests
//
//  Created by ChatGPT on 05/10/25.
//

import XCTest
import UserNotifications
@testable import MacPulse

final class NotificationManagerTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Reset to real center to avoid leakage
        NotificationManager.center = UNUserNotificationCenter.current()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        NotificationManager.center = UNUserNotificationCenter.current()
        try super.tearDownWithError()
    }

    func testRequestPermissionDoesNotThrow() throws {
        // Ensure calling requestPermission() completes without crashing
        XCTAssertNoThrow(NotificationManager.requestPermission())
    }

    func testSendSchedulesNotificationViaMockCenter() throws {
        // Arrange: inject mock center
        let mockCenter = MockNotificationCenter()
        NotificationManager.center = mockCenter

        // Act
        NotificationManager.send(title: "Hello", body: "World")

        // Assert: mock received the request
        XCTAssertEqual(mockCenter.requests.count, 1,
                       "send(title:body:) should add exactly one request")
        let req = mockCenter.requests.first!
        XCTAssertEqual(req.content.title, "Hello")
        XCTAssertEqual(req.content.body, "World")
    }

    // MARK: - MockNotificationCenter
    final class MockNotificationCenter: NotificationCenterProtocol {
        private(set) var requests: [UNNotificationRequest] = []
        
        func add(_ request: UNNotificationRequest,
                 withCompletionHandler completion: ((Error?) -> Void)?) {
            requests.append(request)
            completion?(nil)
        }
    }
}

