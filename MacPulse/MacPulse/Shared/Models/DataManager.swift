import Foundation
import SwiftData

/// This file is responsible for managing the data collected and stored in CoreData.
/// By default, there are 2 defined  thresholds that will trigger data pruning:
///     CoreData memory threshold is hit:
///      o  Size of CoreData entities is larger than X MB
///     Data exceeds timeline threshold:
///      o  For System Data  -  Data older than 10 minutes
///      o  For Process Data -  Data older than 1 minute
@MainActor
class DataManager {
    static let shared: DataManager = {
        let ctx = MetricContainer.shared.container.mainContext
        return DataManager(_modelContext: ctx)
    }()
    
    let modelContext: ModelContext
    private var pruningTimer: Timer?
    
    @MainActor
    private init(_modelContext: ModelContext) {
        self.modelContext = _modelContext
        LogManager.shared.log(.dataPersistence, level: .low, "Initialized DataManager with main context")
    }
    
    @MainActor
    init(testingContext: ModelContext) {
        self.modelContext = testingContext
        LogManager.shared.log(.dataPersistence, level: .low, "Initialized DataManager with testing context")
    }
    
    // MARK: - Saving Metrics
    @MainActor
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

    @MainActor
    func saveSystemMetrics(cpu: Double, memory: Double, disk: Double) {
        let newSystemMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
        do {
            modelContext.insert(newSystemMetric)
            try modelContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "✅ Saved system metrics — CPU: \(cpu), Memory: \(memory), Disk: \(disk)")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error saving system metrics: \(error.localizedDescription)")
        }
    }

    // MARK: - Pruning Old Metrics
    @MainActor
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

    // MARK: - Pruning Timers
    func startPruningTimer() {
        pruningTimer?.invalidate()
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
    func databaseSizeInfo() {
        let systemCount = (try? modelContext.fetch(FetchDescriptor<SystemMetric>()))?.count ?? 0
        let processCount = (try? modelContext.fetch(FetchDescriptor<CustomProcessInfo>()))?.count ?? 0
            LogManager.shared.log(.dataPersistence, level: .medium, "📊 Database size — System: \(systemCount), Process: \(processCount)")
    }
}
