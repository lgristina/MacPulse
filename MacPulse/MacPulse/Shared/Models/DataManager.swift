// MARK: DATA MANAGER
/*  This file is responsible for managing the data collected
 and stored in CoreData. By default, there are 2 defined
 thresholds that will trigger data pruning:
 CoreData memory threshold is hit:
 o Size of CoreData entities is larger than X MB
 Data exceeds timeline threshold:
 o For System Data  -  Data older than 10 minutes
 o For Process Data -  Data older than 1 minute
 */
import Foundation
import SwiftData

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
    }
    
    @MainActor
    init(testingContext: ModelContext) {
        self.modelContext = testingContext
    }
    
    // MARK: - Saving Metrics
    @MainActor
    func saveProcessMetrics(processes: [CustomProcessInfo]) {
        do {
            for process in processes {
                modelContext.insert(process) // Insert process metrics
            }
            try modelContext.save() // Save all metrics at once
        } catch {
            print("❌ Error saving process metrics: \(error)")
        }
    }
    
    @MainActor
    func saveSystemMetrics(cpu: Double, memory: Double, disk: Double) {
        let newSystemMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
        do {
            modelContext.insert(newSystemMetric) // Insert system metric
            try modelContext.save() // Save all metrics at once
        } catch {
            print("❌ Error saving system metrics: \(error)")
        }
    }
    
    // MARK: - Pruning Old Metrics
    @MainActor
    func pruneOldSystemMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -10, to: Date())! // 10 minutes ago
        let fetchDescriptor = FetchDescriptor<SystemMetric>(predicate: #Predicate { (metric: SystemMetric) in
            metric.timestamp < retentionPeriod
        })
        
        print("🕒 Pruning system metrics older than \(retentionPeriod)")
        
        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor)
            print("Before pruning: Found \(oldMetrics.count) old system metrics.")
            
            for metric in oldMetrics {
                modelContext.delete(metric)
            }
            try modelContext.save()
            print("🗑️ Old system metrics pruned.")
        } catch {
            print("❌ Error pruning system metrics: \(error)")
        }
    }
    
    
    @MainActor
    func pruneOldProcessMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -1, to: Date())! // 1 minute ago
        let fetchDescriptor = FetchDescriptor<CustomProcessInfo>(predicate: #Predicate { (process: CustomProcessInfo) in
            process.timestamp < retentionPeriod
        })
        
        print("🕒 Pruning process metrics older than \(retentionPeriod)")
        
        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor)
            print("Before pruning: Found \(oldMetrics.count) old process metrics.")
            
            for metric in oldMetrics {
                modelContext.delete(metric)
            }
            try modelContext.save()
            print("🗑️ Old process metrics pruned.")
        } catch {
            print("❌ Error pruning process metrics: \(error)")
        }
    }
    
    // MARK: - Pruning Timers
    func startPruningTimer() {
        pruningTimer?.invalidate()
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
    func databaseSizeInfo() {
        let systemCount = (try? modelContext.fetch(FetchDescriptor<SystemMetric>()))?.count ?? 0
        let processCount = (try? modelContext.fetch(FetchDescriptor<CustomProcessInfo>()))?.count ?? 0
        print("📊 Database size: \(systemCount) system metrics, \(processCount) process metrics")
    }
}

