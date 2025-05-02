import Foundation
import SwiftData

/// This file manages the saving and pruning of system and process metrics in CoreData.
/// It defines two thresholds for pruning:
/// 1. **CoreData memory threshold**: Prunes when CoreData entities exceed a specified size.
/// 2. **Timeline threshold**:
///     - **System Data**: Prunes data older than 10 minutes.
///     - **Process Data**: Prunes data older than 1 minute.
@MainActor
class DataManager {
    /// Singleton instance of `DataManager` for shared use.
    static let shared: DataManager = {
        let ctx = MetricContainer.shared.container.mainContext
        return DataManager(_modelContext: ctx)
    }()
    
    /// The CoreData context used to manage model objects.
    let modelContext: ModelContext
    
    /// Timer for periodic pruning of old metrics.
    private var pruningTimer: Timer?
    
    /// Initializes `DataManager` with a given CoreData context.
    private init(_modelContext: ModelContext) {
        self.modelContext = _modelContext
        LogManager.shared.log(.dataPersistence, level: .low, "Initialized DataManager with main context")
    }
    
    /// Initializes `DataManager` for testing purposes with a mock context.
    @MainActor
    init(testingContext: ModelContext) {
        self.modelContext = testingContext
        LogManager.shared.log(.dataPersistence, level: .low, "Initialized DataManager with testing context")
    }
    
    // MARK: - Saving Metrics
    
    /// Saves a collection of process metrics into CoreData.
    ///
    /// - Parameter processes: An array of `CustomProcessInfo` objects to be saved.
    func saveProcessMetrics(processes: [CustomProcessInfo]) {
        do {
            for process in processes {
                modelContext.insert(process)
            }
            try modelContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "✅ Saved \(processes.count) process metrics.")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error saving process metrics: \(error.localizedDescription)")
        }
    }

    /// Saves system metrics (CPU, memory, disk usage) to CoreData.
    ///
    /// - Parameters:
    ///   - cpu: The CPU usage value to save.
    ///   - memory: The memory usage value to save.
    ///   - disk: The disk activity value to save.
    @MainActor
    func saveSystemMetrics(cpu: Double, memory: Double, disk: Double) {
        let newMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
        do {
            modelContext.insert(newSystemMetric)
            try modelContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "✅ Saved system metrics — CPU: \(cpu), Memory: \(memory), Disk: \(disk)")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error saving system metrics: \(error.localizedDescription)")
        }
    }

    // MARK: - Pruning Old Metrics
    
    /// Prunes system metrics older than 10 minutes.
    ///
    /// - Fetches all system metrics older than 10 minutes.
    /// - Deletes them and saves the changes to CoreData.
    func pruneOldSystemMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -10, to: Date())!
        let fetchDescriptor = FetchDescriptor<SystemMetric>(predicate: #Predicate { metric in
            metric.timestamp < retentionPeriod
        })

        LogManager.shared.log(.dataPersistence, level: .low, "🕒 Pruning process metrics older than \(retentionPeriod)")

        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor)
            LogManager.shared.log(.dataPersistence, level: .low, "Found \(oldMetrics.count) old system metrics to delete.")
            oldMetrics.forEach { modelContext.delete($0) }
            try modelContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "🗑️ System metrics pruning completed.")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error pruning system metrics: \(error.localizedDescription)")
        }
    }
    
    /// Prunes process metrics older than 1 minute.
    ///
    /// - Fetches all process metrics older than 1 minute.
    /// - Deletes them and saves the changes to CoreData.

    @MainActor
    func pruneOldProcessMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
        let fetchDescriptor = FetchDescriptor<CustomProcessInfo>(predicate: #Predicate { process in
            process.timestamp < retentionPeriod
        })

            LogManager.shared.log(.dataPersistence, level: .low, "🕒 Pruning process metrics older than \(retentionPeriod)")

        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor)
            LogManager.shared.log(.dataPersistence, level: .low, "Found \(oldMetrics.count) old process metrics to delete.")
            oldMetrics.forEach { modelContext.delete($0) }
            try modelContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "🗑️ Process metrics pruning completed.")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error pruning process metrics: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Pruning Timer
    
    /// Starts a timer to prune old metrics periodically every minute.
    ///
    /// - The timer triggers pruning of system metrics every 10 minutes and process metrics every 1 minute.
    func startPruningTimer() {
        pruningTimer?.invalidate() // Invalidate any existing timer
        pruningTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            LogManager.shared.log(.dataPersistence, level: .low, "🕒 Timer fired. Starting pruning tasks...")
            Task { @MainActor in
                self.pruneOldSystemMetrics()
                self.pruneOldProcessMetrics()
            }
        }
            LogManager.shared.log(.dataPersistence, level: .medium, "🕒 Pruning scheduled every 1 minute.")
    }

    // MARK: - Debugging
    
    /// Prints the current count of system and process metrics in the database for debugging purposes.
    func databaseSizeInfo() {
        let systemCount = (try? modelContext.fetch(FetchDescriptor<SystemMetric>()))?.count ?? 0
        let processCount = (try? modelContext.fetch(FetchDescriptor<CustomProcessInfo>()))?.count ?? 0
            LogManager.shared.log(.dataPersistence, level: .medium, "📊 Database size — System: \(systemCount), Process: \(processCount)")
    }
}
