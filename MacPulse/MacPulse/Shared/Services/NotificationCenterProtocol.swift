//
//  NotificationCenterProtocol.swift
//  MacPulse
//
//  Created by Luca Gristina on 5/10/25.
//

import UserNotifications

/// Make UNUserNotificationCenter testable
protocol NotificationCenterProtocol {
  func add(_ request: UNNotificationRequest,
           withCompletionHandler completion: ((Error?) -> Void)?)
}

extension UNUserNotificationCenter: NotificationCenterProtocol { }
