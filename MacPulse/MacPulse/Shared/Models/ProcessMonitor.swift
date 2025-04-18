import Foundation
import SwiftUI
import SwiftData

/// Custom data model for process information
@Model
final class CustomProcessInfo: Identifiable {
    var id: Int
    var timestamp: Date
    var cpuUsage: Double
    var memoryUsage: Double

    // Provide a simple initializer for use in your code.
    init(id: Int, timestamp: Date, cpuUsage: Double, memoryUsage: Double) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }
}

/// Returns a list of running processes with CPU & memory usage.
/// On iOS this returns an empty list since the Process API is unavailable.
class ProcessMonitor: ObservableObject {
    static let shared = ProcessMonitor()
    @Published var runningProcesses: [CustomProcessInfo] = []

    private var timer: Timer?

    init() {
        print("📊 Process monitoring started.")
        startMonitoring()
    }

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            print("Collecting process metrics!")
            self.collectAndSaveProcesses()
        }
        print("---- GETTING PROCESS METRICS! -----")
    }

    func stopMonitoring() {
        timer?.invalidate()
        print("🛑 Process monitoring stopped.")
    }
    
    private func collectAndSaveProcesses() {
        let processes = getRunningProcesses().map { process in
            CustomProcessInfo(
                id: process.id,
                timestamp: process.timestamp,
                cpuUsage: process.cpuUsage,
                memoryUsage: process.memoryUsage
            )
        }
        if !processes.isEmpty {
            Task { @MainActor in
                self.runningProcesses = processes
                DataManager.shared.saveProcessMetrics(processes: processes)
            }
        }
    }

    /// Fetches running processes with CPU & memory usage.
    func getRunningProcesses() -> [CustomProcessInfo] {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid,comm,%cpu,rss"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
        } catch {
            print("❌ Failed to fetch processes: \(error)")
            return []
        }

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let result = String(data: output, encoding: .utf8) else { return [] }

        let lines = result.split(separator: "\n").dropFirst()
        var processList: [CustomProcessInfo] = []

        for line in lines {
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            if components.count >= 4,
               let pid = Int(components[0]),
               let cpuUsage = Double(components[2]),
               let memoryUsageKB = Double(components[3]) {
                let memoryUsageMB = memoryUsageKB / 1024 // Convert KB to MB
                
                let process = CustomProcessInfo(
                    id: pid,
                    timestamp: Date(),
                    cpuUsage: cpuUsage,
                    memoryUsage: memoryUsageMB
                )
                processList.append(process)
            }
        }
        return processList
        #else
        // On iOS, process monitoring via /bin/ps is not supported.
        return []
        #endif
    }
}
