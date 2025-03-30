import Foundation
import SwiftUI
import Combine
import SwiftData

// Extend Double to round to N decimal places efficiently
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

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

class SystemMonitor: ObservableObject{
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var diskActivity: Double = 0.0
    private var timer: Timer?
    private var previousCPUInfo: host_cpu_load_info_data_t?
    private var interval: TimeInterval = 1.0

    init() {
        print("🔄 Starting system monitoring...")

        // Schedule a timer to collect metrics in real-time
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.collectMetrics()
        }

    }

    func stopMonitoring() {
        timer?.invalidate()
        print("🛑 Stopped system monitoring.")
    }

    private func collectMetrics() {
        cpuUsage = getCPUUsage()
        memoryUsage = getMemoryUsage()
        diskActivity = getDiskUsage()

        print("📊 CPU: \(cpuUsage)% | 🖥️ Memory: \(memoryUsage) MB | 💾 Disk: \(diskActivity) GB")
        
        Task { @MainActor in
                DataManager.shared.saveMetrics(cpu: cpuUsage, memory: memoryUsage, disk: diskActivity)
            }
    }
   
    private var previousLoad: host_cpu_load_info = SystemMonitor.hostCPULoadInfo()

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

    func getCPUUsage() -> Double {
        let currentLoad = SystemMonitor.hostCPULoadInfo()

        // Calculate CPU tick differences
        let systemDiff = Double(currentLoad.cpu_ticks.0 - previousLoad.cpu_ticks.0)
        let userDiff = Double(currentLoad.cpu_ticks.1 - previousLoad.cpu_ticks.1)
        let idleDiff = Double(currentLoad.cpu_ticks.2 - previousLoad.cpu_ticks.2)
        let niceDiff = Double(currentLoad.cpu_ticks.3 - previousLoad.cpu_ticks.3)


        let totalTicks = userDiff + niceDiff + systemDiff + idleDiff
        let usedTicks = userDiff + niceDiff + systemDiff

        // Store current load as previous for next calculation
        previousLoad = currentLoad

        // Prevent division by zero
        guard totalTicks > 0 else { return 0.0 }

        // Calculate CPU usage percentage
        return ((usedTicks / totalTicks) * 100.0).rounded(toPlaces: 2)
    
    }
    
    private func getMemoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return -1 }

        let usedMemory = Double(stats.active_count + stats.inactive_count + stats.wire_count) * Double(vm_page_size) / (1024 * 1024 * 1024) // Convert bytes to GB
        return usedMemory.rounded(toPlaces: 2)
    }

    private func getDiskUsage() -> Double {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            
            // Get the total disk space and free space
            if let totalSpace = attributes[.systemSize] as? NSNumber,
               let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                // Calculate used space
                let usedSpace = totalSpace.doubleValue - freeSpace.doubleValue
                // Convert bytes to GB (1024^3 bytes in 1 GB)
                let usedSpaceInGB = usedSpace / (1024 * 1024 * 1024)
                // Return the value rounded to 2 decimal places
                return usedSpaceInGB.rounded(toPlaces: 2)
            }
        } catch {
            print("❌ Error getting disk usage: \(error)")
        }
        return -1
    }
}
