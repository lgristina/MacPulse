import Foundation
import SwiftData

@Model
class CustomProcessInfo: Identifiable, CustomStringConvertible, Codable {
    var id: Int
    var timestamp: Date
    var cpuUsage: Double
    var memoryUsage: Double
    var shortProcessName: String
    var fullProcessName: String

    init(id: Int, timestamp: Date, cpuUsage: Double, memoryUsage: Double, shortProcessName: String, fullProcessName: String) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.shortProcessName = shortProcessName
        self.fullProcessName = fullProcessName
    }

    var description: String {
        "ProcessInfo | ID: \(id), Time: \(timestamp.formatted()), CPU: \(cpuUsage)%, MEM: \(memoryUsage)% | Short: \(shortProcessName), Full: \(fullProcessName)"
    }

    // MARK: - Codable
    enum CodingKeys: CodingKey {
        case id, timestamp, cpuUsage, memoryUsage, shortProcessName, fullProcessName
    }

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
