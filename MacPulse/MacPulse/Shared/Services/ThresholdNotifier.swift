import Foundation
import UserNotifications
import Combine

/// Watches each metric (0–100%) and fires local alerts using the injected notification center,
/// with a cooldown interval between repeated alerts.
final class ThresholdNotifier: ObservableObject {
    // how often (in seconds) to repeat notifications when still above threshold
    private let notificationInterval: TimeInterval

    // protocol‑based notification center for testability
    private let notificationCenter: NotificationCenterProtocol

    // stores, per metric key, when we last sent an alert
    private var lastNotificationDate: [String: Date] = [:]

    private var cancellables = Set<AnyCancellable>()

    /// - Parameters:
    ///   - notificationCenter: abstraction over UNUserNotificationCenter
    ///   - notificationInterval: cooldown window before re‑alerting same metric
    init(
        notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current(),
        notificationInterval: TimeInterval = 120
    ) {
        self.notificationCenter = notificationCenter
        self.notificationInterval = notificationInterval

        // CPU usage publisher (0–100%); drop initial value to avoid false positives
        subscribe(
            publisher: SystemMonitor.shared.$cpuUsage
                         .dropFirst()
                         .eraseToAnyPublisher(),
            thresholdKey: "cpuThreshold",
            label: "CPU"
        )

        // Memory usage publisher (0–100%); drop initial value
        subscribe(
            publisher: SystemMonitor.shared.$memoryUsagePercent
                         .dropFirst()
                         .eraseToAnyPublisher(),
            thresholdKey: "memoryThreshold",
            label: "Memory"
        )

        // Disk usage publisher: (used / total) × 100; drop initial
        let diskPercent = Publishers.CombineLatest(
            SystemMonitor.shared.$diskUsed,
            SystemMonitor.shared.$diskTotal
        )
        .dropFirst()
        .map { usedGB, totalGB in
            totalGB > 0 ? (usedGB / totalGB) * 100.0 : 0.0
        }
        .eraseToAnyPublisher()

        subscribe(
            publisher: diskPercent,
            thresholdKey: "diskThreshold",
            label: "Disk"
        )
    }

    private func subscribe(
        publisher: AnyPublisher<Double, Never>,
        thresholdKey: String,
        label: String
    ) {
        publisher
            .sink { [weak self] newValue in
                self?.check(newValue: newValue,
                            thresholdKey: thresholdKey,
                            label: label)
            }
            .store(in: &cancellables)
    }

    private func check(
        newValue: Double,
        thresholdKey: String,
        label: String
    ) {
        let threshold = UserDefaults.standard.double(forKey: thresholdKey)
        guard newValue >= threshold else {
            // still below threshold → nothing to do
            return
        }

        let now = Date()
        if let lastDate = lastNotificationDate[thresholdKey],
           now.timeIntervalSince(lastDate) < notificationInterval {
            // still in cooldown → skip
            return
        }

        // build and schedule the notification
        let content = UNMutableNotificationContent()
        content.title = "\(label) threshold hit"
        content.body  = "\(label) usage at \(Int(newValue))%"

        let request = UNNotificationRequest(
            identifier: "\(thresholdKey)Alert",
            content: content,
            trigger: nil
        )

        notificationCenter.add(request, withCompletionHandler: nil)
        lastNotificationDate[thresholdKey] = now
    }
}
