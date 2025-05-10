//
//  NotificationManager.swift
//  MacPulse
//
//  Created by Luca Gristina on 5/7/25.
//

import Foundation
import UserNotifications

/// Central place to request permission & send local notifications
enum NotificationManager {
    /// Injectable notification center (default: real UNUserNotificationCenter)
    static var center: NotificationCenterProtocol = UNUserNotificationCenter.current()

    /// Request user permission for alerts, sounds, and badges
    static func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Schedule a local notification with given title and body
    static func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let req = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(req, withCompletionHandler: nil)
    }
}
