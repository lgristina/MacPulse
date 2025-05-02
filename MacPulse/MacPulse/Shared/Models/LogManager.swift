import Foundation
import OSLog
import Combine

// MARK: - Verbosity Levels

/// Represents the verbosity level of logs.
/// - `low`: Only critical errors are logged.
/// - `medium`: Includes warnings and informational logs.
/// - `high`: Includes all logs, including detailed debug output.
enum LogVerbosityLevel: Int, Comparable {
    case low = 0       // Minimal logs, errors only
    case medium = 1    // Include warnings and info
    case high = 2      // Verbose debug details

    static func < (lhs: LogVerbosityLevel, rhs: LogVerbosityLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Log Categories

/// Defines log categories used in the application.
/// Each category corresponds to a specific functional domain for better filtering and debugging.
enum LogCategory: String, CaseIterable, Codable {
    case errorAndDebug = "ErrorAndDebug"
    case syncConnection = "SyncConnection"
    case syncTransmission = "SyncTransmission"
    case syncRetrieval = "SyncRetrieval"
    case dataPersistence = "DataPersistence"
}

// MARK: - Log Entry Model

/// Represents a single log entry stored in memory for UI display or debugging.
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let category: LogCategory
    let level: LogVerbosityLevel
    let message: String

    /// Formats the log entry for display.
    var formatted: String {
        let dateFormatter = ISO8601DateFormatter()
        let time = dateFormatter.string(from: timestamp)
        return "[\(time)] [\(category.rawValue)] [\(level)] \(message)"
    }
}

// MARK: - LogManager Singleton

/// Manages application logging.
/// Supports verbosity levels, category filtering, and memory-stored logs for display.
/// Outputs logs to Apple's unified logging system via `OSLog`.
class LogManager: ObservableObject {
    static let shared = LogManager()

    // MARK: - OSLog Category Loggers
    private let errorAndDebugLogger = Logger(subsystem: "com.MacPulse", category: "ErrorAndDebug")
    private let syncConnectionLogger = Logger(subsystem: "com.MacPulse", category: "SyncConnection")
    private let syncTransmissionLogger = Logger(subsystem: "com.MacPulse", category: "SyncTransmission")
    private let syncRetrievalLogger = Logger(subsystem: "com.MacPulse", category: "SyncRetrieval")
    private let dataPersistenceLogger = Logger(subsystem: "com.MacPulse", category: "DataPersistence")

    // MARK: - Verbosity Level Settings (per category)
    var verbosityLevelForErrorAndDebug: LogVerbosityLevel = .medium
    var verbosityLevelForSyncConnection: LogVerbosityLevel = .medium
    var verbosityLevelForSyncTransmission: LogVerbosityLevel = .medium
    var verbosityLevelForSyncRetrieval: LogVerbosityLevel = .medium
    var verbosityLevelForDataPersistence: LogVerbosityLevel = .medium

    /// Stores logs that pass verbosity filters for UI or debugging
    @Published private(set) var logs: [LogEntry] = []

    private init() {}

    // MARK: - General Logging Function

    /// Logs a message to the appropriate category and level, respecting verbosity filters.
    ///
    /// - Parameters:
    ///   - category: The category to log under.
    ///   - level: The verbosity level of the message.
    ///   - message: The message to be logged.
    func log(_ category: LogCategory, level: LogVerbosityLevel, _ message: String) {
        // Verbosity check
        switch category {
        case .errorAndDebug: guard level <= verbosityLevelForErrorAndDebug else { return }
        case .syncConnection: guard level <= verbosityLevelForSyncConnection else { return }
        case .syncTransmission: guard level <= verbosityLevelForSyncTransmission else { return }
        case .syncRetrieval: guard level <= verbosityLevelForSyncRetrieval else { return }
        case .dataPersistence: guard level <= verbosityLevelForDataPersistence else { return }
        }

        // OSLog output
        switch (category, level) {
        case (.errorAndDebug, .low): errorAndDebugLogger.error("\(message, privacy: .public)")
        case (.errorAndDebug, .medium): errorAndDebugLogger.warning("\(message, privacy: .public)")
        case (.errorAndDebug, .high): errorAndDebugLogger.info("\(message, privacy: .public)")

        case (.syncConnection, .low): syncConnectionLogger.error("\(message, privacy: .public)")
        case (.syncConnection, .medium): syncConnectionLogger.warning("\(message, privacy: .public)")
        case (.syncConnection, .high): syncConnectionLogger.info("\(message, privacy: .public)")

        case (.syncTransmission, .low): syncTransmissionLogger.error("\(message, privacy: .public)")
        case (.syncTransmission, .medium): syncTransmissionLogger.warning("\(message, privacy: .public)")
        case (.syncTransmission, .high): syncTransmissionLogger.info("\(message, privacy: .public)")

        case (.syncRetrieval, .low): syncRetrievalLogger.error("\(message, privacy: .public)")
        case (.syncRetrieval, .medium): syncRetrievalLogger.warning("\(message, privacy: .public)")
        case (.syncRetrieval, .high): syncRetrievalLogger.info("\(message, privacy: .public)")

        case (.dataPersistence, .low): dataPersistenceLogger.error("\(message, privacy: .public)")
        case (.dataPersistence, .medium): dataPersistenceLogger.warning("\(message, privacy: .public)")
        case (.dataPersistence, .high): dataPersistenceLogger.info("\(message, privacy: .public)")
        }

        // Add to local log storage
        let entry = LogEntry(timestamp: Date(), category: category, level: level, message: message)
        DispatchQueue.main.async {
            self.logs.append(entry)
        }
    }

    // MARK: - Specialized Logging Convenience Methods

    /// Logs the current connection status (e.g., connected, disconnected).
    func logConnectionStatus(_ status: String, level: LogVerbosityLevel = .medium) {
        log(.syncConnection, level: level, "Connection Status: \(status)")
    }

    /// Logs the type of connection (e.g., WiFi, Bluetooth).
    func logConnectionType(_ type: String, level: LogVerbosityLevel = .medium) {
        log(.syncConnection, level: level, "Connection Type: \(type)")
    }

    /// Logs a sent data payload description.
    func logDataSent(_ dataDescription: String, timestamp: Date = Date(), level: LogVerbosityLevel = .medium) {
        log(.syncTransmission, level: level, "Data Sent: \(dataDescription) at \(timestamp)")
    }

    /// Logs a received data payload description.
    func logDataReceived(_ dataDescription: String, timestamp: Date = Date(), level: LogVerbosityLevel = .medium) {
        log(.syncTransmission, level: level, "Data Received: \(dataDescription) at \(timestamp)")
    }

    /// Logs a data retrieval operation for a specific data type.
    func logDataRetrieval(_ dataType: String, retrievalTime: Date = Date(), level: LogVerbosityLevel = .medium) {
        log(.syncRetrieval, level: level, "Data Retrieved: \(dataType) at \(retrievalTime)")
    }
}

#if DEBUG
extension LogManager {
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}
#endif
