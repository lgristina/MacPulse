//
//  UserNotificationDelegate.swift
//  MacPulse
//
//  Created by Luca Gristina on 5/10/25.
//

#if os(iOS)
import UIKit
import UserNotifications

/// Handles delivery of local notifications when the app is in the foreground.
final class UserNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    /// Show banners/sounds/badges even when the app is frontmost.
    func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      willPresent notification: UNNotification,
      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle taps or action buttons (optional).
    func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      didReceive response: UNNotificationResponse,
      withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
#endif
