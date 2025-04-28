import Foundation
import OSLog
import Combine

<<<<<<< Updated upstream
// MARK: - Verbosity Levels
enum LogVerbosityLevel: Int, Comparable {
    case low = 0       // minimal logs, errors only
    case medium = 1    // include warnings and info
    case high = 2      // verbose debug details

    static func < (lhs: LogVerbosityLevel, rhs: LogVerbosityLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Log Categories
enum LogCategory: String, CaseIterable {
    case errorAndDebug = "ErrorAndDebug"
    case sync = "Sync"
}

// MARK: - Log Entry Model
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let category: LogCategory
    let level: LogVerbosityLevel
    let message: String

    var formatted: String {
        let dateFormatter = ISO8601DateFormatter()
        let time = dateFormatter.string(from: timestamp)
        return "[\(time)] [\(category.rawValue)] [\(level)] \(message)"
    }
}

// MARK: - LogManager Singleton
=======
///  LogManager is responsible for documenting different User, System, and CoreData interactions
>>>>>>> Stashed changes
class LogManager: ObservableObject {
    static let shared = LogManager()

    // OSLog instances for each category
    private let errorAndDebugLogger = Logger(subsystem: "com.MacPulse", category: "ErrorAndDebug")
    private let syncLogger = Logger(subsystem: "com.MacPulse", category: "Sync")

    // Published logs for UI
    @Published private(set) var logs: [LogEntry] = []

    // Configurable verbosity levels per category
    var verbosityLevelForErrorAndDebug: LogVerbosityLevel = .medium
    var verbosityLevelForSync: LogVerbosityLevel = .medium

    private init() {}
<<<<<<< Updated upstream

    // MARK: - Public Logging Methods
    func log(_ category: LogCategory, level: LogVerbosityLevel, _ message: String) {
        print("LogManager: Logging message for category \(category) level \(level): \(message)")
        // Check verbosity
        switch category {
        case .errorAndDebug:
            guard level <= verbosityLevelForErrorAndDebug else { return }
        case .sync:
            guard level <= verbosityLevelForSync else { return }
        }

        // OSLog output
        switch (category, level) {
        case (.errorAndDebug, .low):
            errorAndDebugLogger.error("\(message, privacy: .public)")
        case (.errorAndDebug, .medium):
            errorAndDebugLogger.warning("\(message, privacy: .public)")
        case (.errorAndDebug, .high):
            errorAndDebugLogger.info("\(message, privacy: .public)")
        case (.sync, .low):
            syncLogger.error("\(message, privacy: .public)")
        case (.sync, .medium):
            syncLogger.warning("\(message, privacy: .public)")
        case (.sync, .high):
            syncLogger.info("\(message, privacy: .public)")
        }

        // Save locally (on main thread for UI)
        let entry = LogEntry(timestamp: Date(), category: category, level: level, message: message)
=======
    
    func logInfo(_ message: String) {
        logger.info("\(message, privacy: .public)")
        addToLog("[INFO] \(message)")
    }
    
    func logError(_ message: String) {
        logger.error("\(message, privacy: .public)")
        addToLog("[ERROR] \(message)")
    }
    
    func logWarning(_ message: String, category: String = "General") {
        logger.warning("\(message, privacy: .public)")
    }
    
    /// Description
    /// - Parameter entry: entry description
    private func addToLog(_ entry: String) {
>>>>>>> Stashed changes
        DispatchQueue.main.async {
            self.logs.append(entry)
        }
    }

    // Convenience methods
    func logError(_ category: LogCategory, _ message: String) {
        log(category, level: .low, "[ERROR] " + message)
    }

    func logWarning(_ category: LogCategory, _ message: String) {
        log(category, level: .medium, "[WARNING] " + message)
    }

    func logInfo(_ category: LogCategory, _ message: String) {
        log(category, level: .high, "[INFO] " + message)
    }

    // Clear logs if needed
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}
