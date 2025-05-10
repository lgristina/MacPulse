//
//  ThresholdNotifierTests.swift
//  MacPulseTests
//
//  Created by Luca Gristina on 05/10/25.
//

import XCTest
import UserNotifications
import Combine
@testable import MacPulse

/// Mock notification center for capturing scheduled alerts
final class MockNotificationCenter: NotificationCenterProtocol {
    private(set) var requests: [UNNotificationRequest] = []
    func add(_ request: UNNotificationRequest,
             withCompletionHandler completion: ((Error?) -> Void)?) {
        requests.append(request)
        completion?(nil)
    }
}

final class ThresholdNotifierTests: XCTestCase {

    var mockCenter: MockNotificationCenter!
    var notifier: ThresholdNotifier!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // 1) Stop the shared SystemMonitor’s timer so it won't fire off real metrics
        SystemMonitor.shared.stopMonitoring()

        // 2) Reset all monitored values to a clean slate
        SystemMonitor.shared.cpuUsage             = 0
        SystemMonitor.shared.memoryUsagePercent   = 0
        SystemMonitor.shared.diskUsed             = 0
        SystemMonitor.shared.diskTotal            = 0

        // 3) Now install our mock notification center and build a fresh notifier
        mockCenter = MockNotificationCenter()
        notifier  = ThresholdNotifier(
            notificationCenter: mockCenter,
            notificationInterval: 0    // no cooldown in tests
        )

        cancellables = []

        // 4) Clear any stored thresholds
        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "memoryThreshold")
        UserDefaults.standard.removeObject(forKey: "diskThreshold")
    }

    override func tearDownWithError() throws {
        mockCenter = nil
        notifier  = nil
        cancellables = nil

        UserDefaults.standard.removeObject(forKey: "cpuThreshold")
        UserDefaults.standard.removeObject(forKey: "memoryThreshold")
        UserDefaults.standard.removeObject(forKey: "diskThreshold")
        try super.tearDownWithError()
    }

    func testCPUThresholdFiresNotification() throws {
        // Arrange
        UserDefaults.standard.set(50, forKey: "cpuThreshold")

        // Act
        SystemMonitor.shared.cpuUsage = 75

        // Assert: exactly one alert
        XCTAssertEqual(mockCenter.requests.count, 1,
                       "Should fire one CPU alert when usage exceeds threshold")
        let r = mockCenter.requests.first!
        XCTAssertEqual(r.content.title, "CPU threshold hit")
        XCTAssertEqual(r.content.body,  "CPU usage at 75%")
    }

    func testNoCPUNotificationWhenBelowThreshold() throws {
        UserDefaults.standard.set(80, forKey: "cpuThreshold")
        SystemMonitor.shared.cpuUsage = 50
        XCTAssertTrue(mockCenter.requests.isEmpty,
                      "No alert should be sent when CPU usage is below threshold")
    }

    func testMemoryThresholdFiresNotification() throws {
        UserDefaults.standard.set(40, forKey: "memoryThreshold")
        SystemMonitor.shared.memoryUsagePercent = 60

        XCTAssertEqual(mockCenter.requests.count, 1,
                       "Should fire one Memory alert when usage exceeds threshold")
        let r = mockCenter.requests.first!
        XCTAssertEqual(r.content.title, "Memory threshold hit")
        XCTAssertEqual(r.content.body,  "Memory usage at 60%")
    }

    func testDiskThresholdFiresNotification() throws {
        UserDefaults.standard.set(30, forKey: "diskThreshold")
        // trigger CombineLatest: first set used, then total
        SystemMonitor.shared.diskUsed  = 20
        SystemMonitor.shared.diskTotal = 50

        XCTAssertEqual(mockCenter.requests.count, 1,
                       "Should fire one Disk alert when usage exceeds threshold")
        let r = mockCenter.requests.first!
        XCTAssertEqual(r.content.title, "Disk threshold hit")
        XCTAssertEqual(r.content.body,  "Disk usage at 40%")
    }
}
