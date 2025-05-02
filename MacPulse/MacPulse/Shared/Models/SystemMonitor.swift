import Foundation
import SwiftUI
import SwiftData

// Extend Double to round to N decimal places efficiently
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

/// Fetches CPU load statistics from the system.
fileprivate func hostCPULoadInfo() -> host_cpu_load_info {
    var info = host_cpu_load_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
        }
    }
    
    guard kerr == KERN_SUCCESS else {
        print("❌ Failed to get CPU load")
        return host_cpu_load_info()
    }
    
    return info
}

/// Monitors and records system-level CPU, memory, and disk usage.
class SystemMonitor: ObservableObject {
    
    static let shared = SystemMonitor()
    @Published var lastMetrics: SystemMetric?
    
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var diskActivity: Double = 0.0
    var timer: Timer?
    private var previousCPUInfo: host_cpu_load_info_data_t?
    private var interval: TimeInterval = 1.0
    
    /// Initializes the system monitor and begins collecting metrics.
    init() {
        print("🔄 Starting system monitoring...")
        LogManager.shared.logConnectionStatus("Started system monitoring.", level: .medium)

        // Schedule a timer to collect metrics every second
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.collectMetrics()
        }
    }

    /// Stops the system monitoring by invalidating the timer.
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        print("🛑 Stopped system monitoring.")
        LogManager.shared.logConnectionStatus("Stopped system monitoring.", level: .medium)
    }

    /// Collects CPU, memory, and disk usage metrics and saves them.
    func collectMetrics() {
        cpuUsage = getCPUUsage()
        memoryUsage = getMemoryUsage()
        diskActivity = getDiskUsage()

        let metrics = SystemMetric(timestamp: Date(), cpuUsage: cpuUsage, memoryUsage: memoryUsage, diskActivity: diskActivity)
        lastMetrics = metrics
        
        Task { @MainActor in
            // Save the metrics to the data manager and log the action
            DataManager.shared.saveSystemMetrics(cpu: cpuUsage, memory: memoryUsage, disk: diskActivity)
            LogManager.shared.log(.dataPersistence, level: .medium, "System metrics saved to database.")
        }
    }

    private var previousLoad: host_cpu_load_info = SystemMonitor.hostCPULoadInfo()
    
    /// Retrieves the current CPU load statistics.
    /// - Returns: `host_cpu_load_info` struct containing the CPU load information.
    static func hostCPULoadInfo() -> host_cpu_load_info {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return host_cpu_load_info()
        }
        
        return info
    }

    /// Calculates the CPU usage percentage.
    /// - Returns: The current CPU usage as a percentage (rounded to 2 decimal places).
    func getCPUUsage() -> Double {
        let currentLoad = SystemMonitor.hostCPULoadInfo()
        
        // Calculate CPU tick differences
        let systemDiff = Double(currentLoad.cpu_ticks.0 - previousLoad.cpu_ticks.0)
        let userDiff = Double(currentLoad.cpu_ticks.1 - previousLoad.cpu_ticks.1)
        let idleDiff = Double(currentLoad.cpu_ticks.2 - previousLoad.cpu_ticks.2)
        let niceDiff = Double(currentLoad.cpu_ticks.3 - previousLoad.cpu_ticks.3)
        
        let totalTicks = userDiff + niceDiff + systemDiff + idleDiff
        let usedTicks = userDiff + niceDiff + systemDiff
        
        // Store current load for the next calculation
        previousLoad = currentLoad
        
        // Prevent division by zero
        guard totalTicks > 0 else { return 0.0 }
    
        return ((usedTicks / totalTicks) * 100.0).rounded(toPlaces: 2)
    }

    /// Retrieves the current memory usage.
    /// - Returns: The current memory usage in GB, rounded to 2 decimal places.
    func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            LogManager.shared.log(.syncRetrieval, level: .low, "Error retrieving memory usage.")
            return -1
        }

        let usedMemory = Double(stats.active_count + stats.inactive_count + stats.wire_count) * Double(vm_page_size) / (1024 * 1024 * 1024) // Convert bytes to GB
        return usedMemory.rounded(toPlaces: 2)
    }

    /// Retrieves the current disk usage.
    /// - Returns: The current used disk space in GB, rounded to 2 decimal places.
    func getDiskUsage() -> Double {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            
            if let totalSpace = attributes[.systemSize] as? NSNumber,
               let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                let usedSpace = totalSpace.doubleValue - freeSpace.doubleValue
                let usedSpaceInGB = usedSpace / (1024 * 1024 * 1024) // Convert bytes to GB
                return usedSpaceInGB.rounded(toPlaces: 2)
            }
        } catch {
            LogManager.shared.log(.syncRetrieval, level: .low, "Error retrieving disk usage: \(error)")
        }
        return -1
    }
}
