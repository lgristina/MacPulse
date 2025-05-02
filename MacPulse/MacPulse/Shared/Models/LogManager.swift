import Foundation
import OSLog
import Combine

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
enum LogCategory: String, CaseIterable, Codable {
    case errorAndDebug = "ErrorAndDebug"
    case syncConnection = "SyncConnection"
    case syncTransmission = "SyncTransmission"
    case syncRetrieval = "SyncRetrieval"
    case dataPersistence = "DataPersistence"
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
class LogManager: ObservableObject {
    static let shared = LogManager()
    
    // Existing loggers for categories
    private let errorAndDebugLogger = Logger(subsystem: "com.MacPulse", category: "ErrorAndDebug")
    private let syncConnectionLogger = Logger(subsystem: "com.MacPulse", category: "SyncConnection")
    private let syncTransmissionLogger = Logger(subsystem: "com.MacPulse", category: "SyncTransmission")
    private let syncRetrievalLogger = Logger(subsystem: "com.MacPulse", category: "SyncRetrieval")
    private let dataPersistenceLogger = Logger(subsystem: "com.MacPulse", category: "DataPersistence")


    // Verbosity levels per category
    var verbosityLevelForErrorAndDebug: LogVerbosityLevel = .medium
    var verbosityLevelForSyncConnection: LogVerbosityLevel = .medium
    var verbosityLevelForSyncTransmission: LogVerbosityLevel = .medium
    var verbosityLevelForSyncRetrieval: LogVerbosityLevel = .medium
    var verbosityLevelForDataPersistence: LogVerbosityLevel = .medium

    @Published private(set) var logs: [LogEntry] = []

    private init() {}

    // General log function, updated for new categories
    func log(_ category: LogCategory, level: LogVerbosityLevel, _ message: String) {
        // Verbosity checks
        switch category {
        case .errorAndDebug:
            guard level <= verbosityLevelForErrorAndDebug else { return }
        case .syncConnection:
            guard level <= verbosityLevelForSyncConnection else { return }
        case .syncTransmission:
            guard level <= verbosityLevelForSyncTransmission else { return }
        case .syncRetrieval:
            guard level <= verbosityLevelForSyncRetrieval else { return }
        case .dataPersistence:
            guard level <= verbosityLevelForDataPersistence else {return}
        }

        // OSLog output based on category
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

        // Save locally for UI/log display
        let entry = LogEntry(timestamp: Date(), category: category, level: level, message: message)
        DispatchQueue.main.async {
            self.logs.append(entry)
        }
    }

    // MARK: - Specialized logging convenience methods
    
    // Connection Info
    func logConnectionStatus(_ status: String, level: LogVerbosityLevel = .medium) {
        log(.syncConnection, level: level, "Connection Status: \(status)")
    }
    
    func logConnectionType(_ type: String, level: LogVerbosityLevel = .medium) {
        log(.syncConnection, level: level, "Connection Type: \(type)")
    }
    
    // Data Transmission
    func logDataSent(_ dataDescription: String, timestamp: Date = Date(), level: LogVerbosityLevel = .medium) {
        log(.syncTransmission, level: level, "Data Sent: \(dataDescription) at \(timestamp)")
    }
    
    func logDataReceived(_ dataDescription: String, timestamp: Date = Date(), level: LogVerbosityLevel = .medium) {
        log(.syncTransmission, level: level, "Data Received: \(dataDescription) at \(timestamp)")
    }
    
    // Data Retrieval
    func logDataRetrieval(_ dataType: String, retrievalTime: Date = Date(), level: LogVerbosityLevel = .medium) {
        log(.syncRetrieval, level: level, "Data Retrieved: \(dataType) at \(retrievalTime)")
    }
}

