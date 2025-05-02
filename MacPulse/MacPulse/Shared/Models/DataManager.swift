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
    }
    
    /// Initializes `DataManager` for testing purposes with a mock context.
    @MainActor
    init(testingContext: ModelContext) {
        self.modelContext = testingContext
    }
    
    // MARK: - Saving Metrics
    
    /// Saves a collection of process metrics into CoreData.
    ///
    /// - Parameter processes: An array of `CustomProcessInfo` objects to be saved.
    func saveProcessMetrics(processes: [CustomProcessInfo]) {
        do {
            for process in processes {
                modelContext.insert(process) // Insert each process into CoreData
            }
            try modelContext.save() // Save the context with all the new metrics
        } catch {
            print("❌ Error saving process metrics: \(error)")
        }
    }
    
    /// Saves system metrics (CPU, memory, disk usage) to CoreData.
    ///
    /// - Parameters:
    ///   - cpu: The CPU usage value to save.
    ///   - memory: The memory usage value to save.
    ///   - disk: The disk activity value to save.
    func saveSystemMetrics(cpu: Double, memory: Double, disk: Double) {
        let newMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
        do {
            modelContext.insert(newMetric) // Insert system metric into CoreData
            try modelContext.save() // Save the new system metric
        } catch {
            print("❌ Error saving system metrics: \(error)")
        }
    }
    
    // MARK: - Pruning Old Metrics
    
    /// Prunes system metrics older than 10 minutes.
    ///
    /// - Fetches all system metrics older than 10 minutes.
    /// - Deletes them and saves the changes to CoreData.
    func pruneOldSystemMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -10, to: Date())! // 10 minutes ago
        let fetchDescriptor = FetchDescriptor<SystemMetric>(predicate: #Predicate { (metric: SystemMetric) in
            metric.timestamp < retentionPeriod
        })
        
        print("🕒 Pruning system metrics older than \(retentionPeriod)")
        
        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor) // Fetch old system metrics
            print("Found \(oldMetrics.count) old system metrics.")
            
            for metric in oldMetrics {
                modelContext.delete(metric) // Delete the old system metrics
            }
            try modelContext.save() // Save the pruned metrics
            print("🗑️ Old system metrics pruned.")
        } catch {
            print("❌ Error pruning system metrics: \(error)")
        }
    }
    
    /// Prunes process metrics older than 1 minute.
    ///
    /// - Fetches all process metrics older than 1 minute.
    /// - Deletes them and saves the changes to CoreData.
    func pruneOldProcessMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -1, to: Date())! // 1 minute ago
        let fetchDescriptor = FetchDescriptor<CustomProcessInfo>(predicate: #Predicate { (process: CustomProcessInfo) in
            process.timestamp < retentionPeriod
        })
        
        print("🕒 Pruning process metrics older than \(retentionPeriod)")
        
        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor) // Fetch old process metrics
            print("Found \(oldMetrics.count) old process metrics.")
            
            for metric in oldMetrics {
                modelContext.delete(metric) // Delete the old process metrics
            }
            try modelContext.save() // Save the pruned metrics
            print("🗑️ Old process metrics pruned.")
        } catch {
            print("❌ Error pruning process metrics: \(error)")
        }
    }
    
    // MARK: - Pruning Timer
    
    /// Starts a timer to prune old metrics periodically every minute.
    ///
    /// - The timer triggers pruning of system metrics every 10 minutes and process metrics every 1 minute.
    func startPruningTimer() {
        pruningTimer?.invalidate() // Invalidate any existing timer
        pruningTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            print("🕒 Timer fired. Starting pruning...")
            Task { @MainActor in
                self.pruneOldSystemMetrics() // Prune system metrics every 10 minutes
                self.pruneOldProcessMetrics() // Prune process metrics every 1 minute
            }
        }
        print("🕒 Pruning scheduled every 1 minute.")
    }
    
    // MARK: - Debugging
    
    /// Prints the current count of system and process metrics in the database for debugging purposes.
    func databaseSizeInfo() {
        let systemCount = (try? modelContext.fetch(FetchDescriptor<SystemMetric>()))?.count ?? 0
        let processCount = (try? modelContext.fetch(FetchDescriptor<CustomProcessInfo>()))?.count ?? 0
        print("📊 Database size: \(systemCount) system metrics, \(processCount) process metrics")
    }
}
