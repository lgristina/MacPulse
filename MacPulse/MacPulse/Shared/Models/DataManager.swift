import Foundation
import SwiftData

@MainActor
class DataManager {
    static let shared = DataManager()
    let modelContext = MetricContainer.shared.container.mainContext // Single context for both SystemMetric and ProcessMetric

    // Saving System and Process Metrics together
    @MainActor
    func saveProcessMetrics(processes: [ProcessInfo]) {
        do {
            for process in processes {
                modelContext.insert(process) // Insert process metrics
            }
            try modelContext.save() // Save all metrics at once
            print("✅ Process metrics saved successfully.")
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
        //    print("✅ System metrics saved successfully.")
        } catch {
            print("❌ Error saving system metrics: \(error)")
        }
    }

    // Fetching Recent System Metrics
    @MainActor
    func fetchRecentSystemMetrics() -> [SystemMetric] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let fetchDescriptor = FetchDescriptor<SystemMetric>(predicate: #Predicate { $0.timestamp > sevenDaysAgo })

        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("❌ Error fetching System metrics: \(error)")
            return []
        }
    }

    // Fetching Recent Process Metrics
    func fetchRecentProcessMetrics() -> [ProcessInfo] {
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let fetchDescriptor = FetchDescriptor<ProcessInfo>(predicate: #Predicate { $0.timestamp > oneHourAgo })

        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("❌ Error fetching Process metrics: \(error)")
            return []
        }
    }
}
