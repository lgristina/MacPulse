import Foundation
import SwiftUI
import SwiftData

/// Monitors and records process-level CPU and memory usage.
class ProcessMonitor: ObservableObject {
    
    static let shared = ProcessMonitor()
    @Published var runningProcesses: [CustomProcessInfo] = []
    
    var timer: Timer?
    
    init() {
        LogManager.shared.log(.dataPersistence, level: .medium, "📊 Process monitoring started.")
        startMonitoring()
    }
    
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            LogManager.shared.log(.dataPersistence, level: .low, "🌀 Collecting process metrics...")
            self.collectAndSaveProcesses()
        }
        LogManager.shared.log(.dataPersistence, level: .medium, "▶️ Started periodic process collection every 5 seconds.")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        LogManager.shared.log(.dataPersistence, level: .medium, "🛑 Process monitoring stopped.")
    }
    
    /// Collects current running process metrics and persists them.
    func collectAndSaveProcesses() {
        let processes = getRunningProcesses()
        if !processes.isEmpty {
            LogManager.shared.log(.dataPersistence, level: .medium, "📥 Retrieved \(processes.count) process metrics.")
            Task { @MainActor in
                self.runningProcesses = processes
                DataManager.shared.saveProcessMetrics(processes: processes)
            }
        } else {
            LogManager.shared.log(.dataPersistence, level: .low, "⚠️ No processes retrieved during this cycle.")
        }
    }
    
    /// Uses `/bin/ps` to retrieve process info.
    /// - Returns: An array of `CustomProcessInfo` for each running process.
    func getRunningProcesses() -> [CustomProcessInfo] {
#if os(macOS)
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-axo", "pid,%cpu,rss,command"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Failed to run /bin/ps: \(error)")
            return []
        }
        
        let output = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let result = String(data: output, encoding: .utf8) else {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Failed to decode output from /bin/ps.")
            return []
        }

        let lines = result.split(separator: "\n").dropFirst()
        var processList: [CustomProcessInfo] = []
        
        for line in lines {
            let components = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            if components.count == 4,
               let pid = Int(components[0]),
               let cpuUsage = Double(components[1]),
               let memoryUsageKB = Double(components[2]) {
                
                let memoryUsageMB = memoryUsageKB / 1024
                let rawCommand = String(components[3])

                // Truncate at "--" if present
                let truncatedCommand = rawCommand.components(separatedBy: " -").first ?? rawCommand

                // Trim extra whitespace (just in case)
                let cleanedCommand = truncatedCommand.trimmingCharacters(in: .whitespacesAndNewlines)

                let fullName = cleanedCommand
                let shortName = URL(fileURLWithPath: fullName).lastPathComponent.isEmpty ? "Unnamed Process" : URL(fileURLWithPath: fullName).lastPathComponent
                let process = CustomProcessInfo(
                    id: pid,
                    timestamp: Date(),
                    cpuUsage: cpuUsage,
                    memoryUsage: memoryUsageMB,
                    shortProcessName: shortName,
                    fullProcessName: fullName
                )
                
                processList.append(process)
            }
        }
        
        LogManager.shared.log(.dataPersistence, level: .low, "✅ Parsed \(processList.count) process entries from /bin/ps output.")
        return processList
#else
        LogManager.shared.log(.dataPersistence, level: .low, "ℹ️ Process monitoring is not supported on iOS.")
        return []
#endif
    }
}
