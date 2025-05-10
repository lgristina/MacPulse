import Foundation
import SwiftData
import CryptoKit


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
    let backupContext: ModelContext
    
    private var encryptionKey: SymmetricKey
    
    let symmetricKey = SymmetricKey(size: .bits256) // 256-bit key

    
    // Tracks corruption detection
    private var wasCorruptionDetectedLastSession: Bool = false
    
    /// Timer for periodic pruning of old metrics.
    private var pruningTimer: Timer?
    
    /// Initializes `DataManager` with a given CoreData context.
    private init(_modelContext: ModelContext) {
        self.modelContext = _modelContext
        self.backupContext = MetricContainer.shared.backupContainer.mainContext
       
        // Load the encryption key from the Keychain
        let keyName = "com.example.app.encryptionKey"

        if let loadedKeyData = KeychainHelper.loadKey(keyName),
           let loadedKey = try? SymmetricKey(data: loadedKeyData) {
            self.encryptionKey = loadedKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            self.encryptionKey = newKey
            KeychainHelper.saveKey(newKey, forKey: keyName)
        }
    }
    /// Initializes `DataManager` for testing purposes with a mock context.
    @MainActor
    init(testingContext: ModelContext) {
        self.modelContext = testingContext
        self.backupContext = testingContext
        self.encryptionKey = SymmetricKey(size: .bits256)
        LogManager.shared.log(.dataPersistence, level: .low, "Initialized DataManager with testing context")
    }
    
    // MARK: - Saving Metrics
    
    /// Saves a collection of process metrics into CoreData.
    ///
    /// - Parameter processes: An array of `CustomProcessInfo` objects to be saved.
    func saveProcessMetrics(processes: [CustomProcessInfo]) {
        do {
            for process in processes {
                // Encrypt the process name
                let encryptedName = CryptoHelper.encrypt(process.fullProcessName, with: encryptionKey)
                process.fullProcessName = encryptedName
                
                modelContext.insert(process)
                try mirrorInsert(process, into: backupContext)
            }
            try modelContext.save()
            try backupContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "✅ Saved \(processes.count) process metrics to both containers.")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error saving process metrics: \(error.localizedDescription)")
        }
    }

    /// Saves system metrics (CPU, memory, disk usage) to CoreData.
    ///
    /// - Parameters:
    ///   - cpu: The CPU usage value to save.
    ///   - memory: The memory usage value to save.
    ///   - disk: The disk activity value to save.
    @MainActor
    func saveSystemMetrics(cpu: Double, memory: Double, disk: Double) {
        let newMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
        do {
            modelContext.insert(newMetric)
            try modelContext.save()
            
            let backupMetric = SystemMetric(timestamp: newMetric.timestamp, cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
            backupContext.insert(backupMetric)
            try backupContext.save()

            LogManager.shared.log(.backup, level: .medium, "✅ System metrics saved to main and backup.")
        } catch {
            LogManager.shared.log(.backup, level: .high, "❌ Failed to save system metrics: \(error.localizedDescription)")
        }
    }

//    func saveSystemMetrics(cpu: Double, memory: Double, disk: Double) {
//        let newMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
//        do {
//            // Insert the metric into the main context
//            modelContext.insert(newMetric)
//            try modelContext.save()
//            
//            // Insert the metric into the backup context
//            let backupMetric = SystemMetric(timestamp: newMetric.timestamp, cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
//            backupContext.insert(backupMetric)
//            try backupContext.save()
//
//            LogManager.shared.log(.backup, level: .medium, "✅ System metrics saved to main and backup.")
//
//            // Check the backup context by fetching and logging the count of system metrics in the backup context
//            let backupFetchRequest = FetchDescriptor<SystemMetric>()
//            let backupMetrics = try backupContext.fetch(backupFetchRequest)
//            LogManager.shared.log(.dataPersistence, level: .low, "Found \(backupMetrics.count) system metrics in the backup context.")
//            
//        } catch {
//            LogManager.shared.log(.backup, level: .high, "❌ Failed to save system metrics: \(error.localizedDescription)")
//        }
//    }

    // MARK: - Fetch and Decrypt Process Metrics
    func fetchProcessMetrics() {
        do {
            let fetchDescriptor = FetchDescriptor<CustomProcessInfo>()
            let processes = try modelContext.fetch(fetchDescriptor)
            
            for process in processes {
                // Decrypt the process name
                if let decryptedName = CryptoHelper.decrypt(process.fullProcessName, with: encryptionKey) {
                    process.fullProcessName = decryptedName
                }
            }
            // Continue with using the decrypted processes
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error fetching process metrics: \(error.localizedDescription)")
        }
    }


    //  MARK: - Mirror Insert
    private func mirrorInsert<T: PersistentModel>(_ model: T, into backupContext: ModelContext) throws {
        if let process = model as? CustomProcessInfo {
            do {
                // Try encrypting the process name
                let encryptedProcessName = try CryptoHelper.encrypt(process.fullProcessName, with: symmetricKey)
                
                // Create the copy of the process with the encrypted name
                let copy = CustomProcessInfo(id: process.id, timestamp: process.timestamp, cpuUsage: process.cpuUsage, memoryUsage: process.memoryUsage, shortProcessName: process.shortProcessName, fullProcessName: encryptedProcessName)
                backupContext.insert(copy)
            } catch {
                // Handle encryption error
                LogManager.shared.log(.dataPersistence, level: .high, "❌ Encryption failed for process name: \(error.localizedDescription)")
                throw error // Rethrow the error to propagate it
            }
        } else if let metric = model as? SystemMetric {
            let copy = SystemMetric(timestamp: metric.timestamp, cpuUsage: metric.cpuUsage, memoryUsage: metric.memoryUsage, diskActivity: metric.diskActivity)
            backupContext.insert(copy)
        }
    }

    // MARK: - Pruning Old Metrics
    
    /// Prunes system metrics older than 10 minutes.
    ///
    /// - Fetches all system metrics older than 10 minutes.
    /// - Deletes them and saves the changes to CoreData.
    func pruneOldSystemMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -10, to: Date())!
        let fetchDescriptor = FetchDescriptor<SystemMetric>(predicate: #Predicate { metric in
            metric.timestamp < retentionPeriod
        })

        LogManager.shared.log(.dataPersistence, level: .low, "🕒 Pruning process metrics older than \(retentionPeriod)")

        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor)
            LogManager.shared.log(.dataPersistence, level: .low, "Found \(oldMetrics.count) old system metrics to delete.")
            oldMetrics.forEach { modelContext.delete($0) }
            try modelContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "🗑️ System metrics pruning completed.")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error pruning system metrics: \(error.localizedDescription)")
        }
    }
    
    /// Prunes process metrics older than 1 minute.
    ///
    /// - Fetches all process metrics older than 1 minute.
    /// - Deletes them and saves the changes to CoreData.

    @MainActor
    func pruneOldProcessMetrics() {
        let retentionPeriod = Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
        let fetchDescriptor = FetchDescriptor<CustomProcessInfo>(predicate: #Predicate { process in
            process.timestamp < retentionPeriod
        })

            LogManager.shared.log(.dataPersistence, level: .low, "🕒 Pruning process metrics older than \(retentionPeriod)")

        do {
            let oldMetrics = try modelContext.fetch(fetchDescriptor)
            LogManager.shared.log(.dataPersistence, level: .low, "Found \(oldMetrics.count) old process metrics to delete.")
            oldMetrics.forEach { modelContext.delete($0) }
            try modelContext.save()
            LogManager.shared.log(.dataPersistence, level: .medium, "🗑️ Process metrics pruning completed.")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Error pruning process metrics: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Pruning Timer
    
    /// Starts a timer to prune old metrics periodically every minute.
    ///
    /// - The timer triggers pruning of system metrics every 10 minutes and process metrics every 1 minute.
    func startPruningTimer() {
        pruningTimer?.invalidate() // Invalidate any existing timer
        pruningTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            LogManager.shared.log(.dataPersistence, level: .low, "🕒 Timer fired. Starting pruning tasks...")
            Task { @MainActor in
                self.pruneOldSystemMetrics()
                self.pruneOldProcessMetrics()
            }
        }
            LogManager.shared.log(.dataPersistence, level: .medium, "🕒 Pruning scheduled every 1 minute.")
    }

    // MARK: - Debugging
    
    /// Prints the current count of system and process metrics in the database for debugging purposes.
    func databaseSizeInfo() {
        let systemCount = (try? modelContext.fetch(FetchDescriptor<SystemMetric>()))?.count ?? 0
        let processCount = (try? modelContext.fetch(FetchDescriptor<CustomProcessInfo>()))?.count ?? 0
            LogManager.shared.log(.dataPersistence, level: .medium, "📊 Database size — System: \(systemCount), Process: \(processCount)")
    }
    
    /// Attempts to restore from the backup context if corruption is detected in the model context.
    func handlePotentialCorruption() {
        do {
            try modelContext.save() // Attempt to save the main context
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Corruption detected: \(error.localizedDescription). Attempting to restore from backup.")
            
            // Perform restore from backup context
            restoreFromBackup()
        }
    }

    /// Restores data from the backup context to the main context.
    private func restoreFromBackup() {
        do {
            let systemMetrics = try backupContext.fetch(FetchDescriptor<SystemMetric>())
            let processMetrics = try backupContext.fetch(FetchDescriptor<CustomProcessInfo>())
            
            // Insert backup data into the main context
            systemMetrics.forEach { modelContext.insert($0) }
            processMetrics.forEach { modelContext.insert($0) }

            // Save the restored data
            try modelContext.save()
            
            LogManager.shared.log(.dataPersistence, level: .medium, "✅ Restored data from backup context to main context.")
        } catch {
            LogManager.shared.log(.dataPersistence, level: .high, "❌ Failed to restore from backup: \(error.localizedDescription)")
        }
    }

    @MainActor
    func checkForCorruptionOnLaunch() {
        // Check for corruption in the main and backup containers
        let isCorrupted = checkForCorruption() // Implement your corruption detection logic here

        if isCorrupted {
            LogManager.shared.log(.backup, level: .high, "Corruption detected. Restoring backup.")
            restoreBackup()
            wasCorruptionDetectedLastSession = true
        } else {
            wasCorruptionDetectedLastSession = false
        }
    }
    
    @MainActor
    func checkForCorruption() -> Bool {
        do {
            let context = modelContext
            let descriptor = FetchDescriptor<SystemMetric>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            _ = try context.fetch(descriptor).prefix(1)
            return false // no corruption
        } catch {
            LogManager.shared.log(.backup, level: .high, "Corruption check failed: \(error.localizedDescription)")
            return true // likely corruption
        }
    }
    
    @MainActor
    func restoreBackup() {
        let backupContext = backupContext
        let mainContext = modelContext
        
        do {
            let backupMetrics = try backupContext.fetch(FetchDescriptor<SystemMetric>())
            let backupProcesses = try backupContext.fetch(FetchDescriptor<CustomProcessInfo>())

            // Clear current data
            try deleteAllData(in: mainContext)

            // Copy backup data
            for metric in backupMetrics {
                let copy = try SystemMetric(from: metric as! Decoder)
                mainContext.insert(copy)
            }
            for process in backupProcesses {
                let copy = try CustomProcessInfo(from: process as! Decoder)
                mainContext.insert(copy)
            }

            try mainContext.save()
            LogManager.shared.log(.backup, level: .high, "Backup restored successfully.")
        } catch {
            LogManager.shared.log(.backup, level: .high, "Failed to restore from backup: \(error.localizedDescription)")
        }
    }
    
    func deleteAllData(in context: ModelContext) throws {
        let metricDescriptor = FetchDescriptor<SystemMetric>()
        let processDescriptor = FetchDescriptor<CustomProcessInfo>()

        let metrics = try context.fetch(metricDescriptor)
        let processes = try context.fetch(processDescriptor)

        for metric in metrics {
            context.delete(metric)
        }

        for process in processes {
            context.delete(process)
        }

        try context.save()
    }


}
