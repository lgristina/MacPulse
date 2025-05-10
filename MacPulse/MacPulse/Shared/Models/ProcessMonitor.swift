import Foundation
import SwiftUI
import SwiftData
import Darwin

/// Monitors and records process-level CPU and memory usage.
class ProcessMonitor: ObservableObject {
    
    static let shared = ProcessMonitor()
    @Published var runningProcesses: [CustomProcessInfo] = []
    private var previousCpuTimes: [Int: TimeInterval] = [:]
    
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
        runningProcesses = getRunningProcesses()
        if !runningProcesses.isEmpty {
            LogManager.shared.log(.dataPersistence, level: .medium, "📥 Retrieved \(runningProcesses.count) process metrics.")
            
            // Serialize processes into JSON data
            do {
                // Serialize the processes array into JSON data
                let jsonData = try JSONEncoder().encode(runningProcesses)
                guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                    throw NSError(domain: "ProcessMonitor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert process data to string."])
                }
                
                // Retrieve the encryption key securely
                guard let encryptionKey = KeyManager.getEncryptionKey() else {
                    throw NSError(domain: "ProcessMonitor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Encryption key is missing."])
                }
                
                // Encrypt the JSON string using the encryption key
                let encryptedProcesses = try CryptoHelper.encrypt(jsonString, with: encryptionKey)
                
                // Save the encrypted data
                Task { @MainActor in
                    // You can save the encrypted string to your storage or perform necessary actions here
                    DataManager.shared.saveEncryptedProcessMetrics(encryptedProcesses)
                }
            } catch {
                LogManager.shared.log(.dataPersistence, level: .high, "⚠️ Failed to encrypt process metrics: \(error.localizedDescription)")
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
        task.arguments = ["-axo", "pid,time,rss,command"]
        
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
        var updatedCpuTimes: [Int: TimeInterval] = [:]
        var processList: [CustomProcessInfo] = []
        
        for line in lines {
            let components = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
            if components.count == 4,
               let pid = Int(components[0]),
               let timeInterval = parsePsTime(String(components[1])),
               let memoryUsageKB = Double(components[2]) {

                let memoryUsageMB = memoryUsageKB / 1024
                let rawCommand = String(components[3])
                let truncatedCommand = rawCommand.components(separatedBy: " -").first ?? rawCommand
                let cleanedCommand = truncatedCommand.trimmingCharacters(in: .whitespacesAndNewlines)
                let shortName = URL(fileURLWithPath: cleanedCommand).lastPathComponent.isEmpty ? "Unnamed Process" : URL(fileURLWithPath: cleanedCommand).lastPathComponent

                // CPU delta calculation
                let previousTime = previousCpuTimes[pid] ?? 0
                let delta = timeInterval - previousTime
                let cpuUsage = (delta / 5.0) * 100 // assuming 5 second interval

                updatedCpuTimes[pid] = timeInterval

                let process = CustomProcessInfo(
                    id: pid,
                    timestamp: Date(),
                    cpuUsage: cpuUsage,
                    memoryUsage: memoryUsageMB,
                    shortProcessName: shortName,
                    fullProcessName: cleanedCommand
                )
                processList.append(process)
            }
        }

        // Update state
        previousCpuTimes = updatedCpuTimes

        LogManager.shared.log(.dataPersistence, level: .low, "✅ Parsed \(processList.count) process entries from /bin/ps output.")
        return processList
    #else
        LogManager.shared.log(.dataPersistence, level: .low, "ℹ️ Process monitoring is not supported on iOS.")
        return []
    #endif
    }
    
    /// Parses CPU time from `ps` format ("MM:SS" or "HH:MM:SS") to seconds.
    func parsePsTime(_ time: String) -> TimeInterval? {
        let parts = time.split(separator: ":").map { Double($0) ?? 0 }
        switch parts.count {
        case 2:
            return parts[0] * 60 + parts[1]            // MM:SS
        case 3:
            return parts[0] * 3600 + parts[1] * 60 + parts[2]  // HH:MM:SS
        default:
            return nil
        }
    }
}
