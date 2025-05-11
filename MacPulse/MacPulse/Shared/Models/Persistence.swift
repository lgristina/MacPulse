import SwiftData
import Foundation

/// Unified container for primary and backup metric stores
struct MetricContainer {
    static let shared = MetricContainer()
    let container: ModelContainer
    let backupContainer: ModelContainer

    init() {
        do {
            // Main container
            self.container = try ModelContainer(for: SystemMetric.self, CustomProcessInfo.self)

            // Backup container stored at a custom location
            let backupURL = MetricContainer.backupStoreURL
            let backupConfig = ModelConfiguration("Backup", url: backupURL)
            self.backupContainer = try ModelContainer(for: SystemMetric.self, CustomProcessInfo.self, configurations: backupConfig)

            LogManager.shared.log(.backup, level: .low, "✅ Initialized both main and backup containers.")

        } catch {
            fatalError("Failed to initialize containers: \(error)")
        }
    }

    static var backupStoreURL: URL {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return supportDir.appendingPathComponent("BackupMetricContainer.sqlite")
    }
}
