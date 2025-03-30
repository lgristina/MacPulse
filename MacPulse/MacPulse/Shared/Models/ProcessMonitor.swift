import Foundation
import SwiftUI
import SwiftData


struct ProcessInfo: Identifiable, Codable, Hashable {
    let id : Int
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
}

    /// Returns a list of running processes with CPU & memory usage
class ProcessMonitor: ObservableObject {
    static let shared = ProcessMonitor()
    @Published var runningProcesses: [ProcessInfo] = []


    private var timer: Timer?

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            print("Collecting process metrics!")
            self.collectAndSaveProcesses()
        }
        print("📊 Process monitoring started.")
    }

    func stopMonitoring() {
        timer?.invalidate()
        print("🛑 Process monitoring stopped.")
    }

    private func collectAndSaveProcesses() {
        let processes = getRunningProcesses().map { process in
            ProcessMetric(id: Int(), timestamp: process.timestamp, cpuUsage: process.cpuUsage, memoryUsage: process.memoryUsage)
        }

        if !processes.isEmpty {
            print("Not empty!")
            Task { @MainActor in
                DataManager.shared.saveProcessMetrics(processes: processes)
                print("Saving!")
            }
        }
    }

    /// Fetches running processes with CPU & memory usage
    func getRunningProcesses() -> [ProcessInfo] {
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
        var processList: [ProcessInfo] = []

        for line in lines {
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            if components.count >= 4,
               let pid = Int(components[0]),
               let cpuUsage = Double(components[2]),
               let memoryUsageKB = Double(components[3]) {

                let memoryUsageMB = memoryUsageKB / 1024 // Convert KB to MB
                
                let process = ProcessInfo(
                    id: pid,
                    timestamp: Date(),
                    cpuUsage: cpuUsage,
                    memoryUsage: memoryUsageMB
                )
                processList.append(process)
            }
        }
        return processList
    }
}
