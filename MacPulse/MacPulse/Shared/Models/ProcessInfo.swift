import Foundation
import SwiftData

/// Represents information about a running process, including its CPU usage, memory usage, and names.
@Model
class CustomProcessInfo: Identifiable, CustomStringConvertible, Codable, Hashable {
    var id: Int  // Unique identifier for the process
    var timestamp: Date  // The timestamp when the process information was recorded
    var cpuUsage: Double  // CPU usage percentage
    var memoryUsage: Double  // Memory usage in MB
    var shortProcessName: String  // Short version of the process name (e.g., process name without the path)
    var fullProcessName: String  // Full path to the process executable

    // MARK: - Initializer
    /// Initializes a new `CustomProcessInfo` instance with provided values.
    init(id: Int, timestamp: Date, cpuUsage: Double, memoryUsage: Double, shortProcessName: String, fullProcessName: String) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.shortProcessName = shortProcessName
        self.fullProcessName = fullProcessName
    }

    // MARK: - Description
    /// Custom string description of the process information.
    var description: String {
        "ProcessInfo | ID: \(id), Time: \(timestamp.formatted()), CPU: \(cpuUsage)%, MEM: \(memoryUsage)% | Short: \(shortProcessName), Full: \(fullProcessName)"
    }

    // MARK: - Codable
    // Conforms to Codable to support encoding and decoding from and to JSON.
    enum CodingKeys: CodingKey {
        case id, timestamp, cpuUsage, memoryUsage, shortProcessName, fullProcessName
    }

    /// Decodes the `CustomProcessInfo` instance from a decoder.
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(Int.self, forKey: .id)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let cpuUsage = try container.decode(Double.self, forKey: .cpuUsage)
        let memoryUsage = try container.decode(Double.self, forKey: .memoryUsage)
        let shortProcessName = try container.decode(String.self, forKey: .shortProcessName)
        let fullProcessName = try container.decode(String.self, forKey: .fullProcessName)
        self.init(id: id, timestamp: timestamp, cpuUsage: cpuUsage, memoryUsage: memoryUsage, shortProcessName: shortProcessName, fullProcessName: fullProcessName)
    }

    /// Encodes the `CustomProcessInfo` instance to a encoder.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(cpuUsage, forKey: .cpuUsage)
        try container.encode(memoryUsage, forKey: .memoryUsage)
        try container.encode(shortProcessName, forKey: .shortProcessName)
        try container.encode(fullProcessName, forKey: .fullProcessName)
    }
}
