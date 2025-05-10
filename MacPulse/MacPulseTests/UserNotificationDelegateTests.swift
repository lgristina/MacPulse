//
//  UserNotificationDelegateTests.swift
//  MacPulse
//
//  Created by Luca Gristina on 5/10/25.
//

#if os(iOS)
import XCTest
import UserNotifications
@testable import MacPulse

final class UserNotificationDelegateTests: XCTestCase {

    var delegate: UserNotificationDelegate!
    let center = UNUserNotificationCenter.current()

    override func setUpWithError() throws {
        try super.setUpWithError()
        delegate = UserNotificationDelegate()
    }

    override func tearDownWithError() throws {
        delegate = nil
        try super.tearDownWithError()
    }

    func testWillPresentCallsCompletionWithAllOptions() throws {
        // Prepare a dummy notification
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.body  = "Body"
        let request = UNNotificationRequest(
            identifier: "test-id",
            content: content,
            trigger: nil
        )
        // UNNotification has an internal initializer; use the public one if available
        let notification = UNNotification(request: request, date: Date())

        // Capture the presentation options passed to the handler
        var receivedOptions: UNNotificationPresentationOptions?
        delegate.userNotificationCenter(
            center,
            willPresent: notification
        ) { options in
            receivedOptions = options
        }

        // Assert that banner, sound, and badge were requested
        XCTAssertEqual(
            receivedOptions,
            [.banner, .sound, .badge],
            "willPresent should request banner, sound, and badge"
        )
    }

    func testDidReceiveCallsCompletionHandler() throws {
        // Prepare a dummy notification and response
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.body  = "Body"
        let request = UNNotificationRequest(
            identifier: "resp-id",
            content: content,
            trigger: nil
        )
        let notification = UNNotification(request: request, date: Date())
        let response = UNNotificationResponse(
            notification: notification,
            actionIdentifier: UNNotificationDefaultActionIdentifier
        )

        // Track whether the completion handler is invoked
        var didCallCompletion = false
        delegate.userNotificationCenter(
            center,
            didReceive: response
        ) {
            didCallCompletion = true
        }

        XCTAssertTrue(
            didCallCompletion,
            "didReceive should always invoke its completion handler"
        )
    }
}
#endif
