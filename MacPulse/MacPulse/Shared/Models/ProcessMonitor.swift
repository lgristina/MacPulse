import Foundation
import SwiftUI


struct ProcessInfo: Identifiable, Codable, Hashable{
    let id : Int
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
}

class ProcessMonitor: ObservableObject {
    static let shared = ProcessMonitor()
    @Published var runningProcesses: [ProcessInfo] = []
    
    init() {
        fetchRunningProcesses()
    }
    
    func fetchRunningProcesses() {
        DispatchQueue.global(qos: .background).async {
            let processes = ProcessMonitor.shared.getRunningProcesses()
            DispatchQueue.main.async {
                self.runningProcesses = processes
            }
        }
    }
    
    /// Returns a list of running processes with CPU & memory usage
    func getRunningProcesses() -> [ProcessInfo] {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid,comm,%cpu,rss"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run() // Updated to use `run()` instead of `launch()` (deprecated)
        } catch {
            print("Failed to fetch processes: \(error)")
            return []
        }

        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let result = String(data: output, encoding: .utf8) else { return [] }

        let lines = result.split(separator: "\n").dropFirst() // Ignore header line
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
