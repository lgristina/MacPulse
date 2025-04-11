import Foundation
import SwiftData

@Model
class ProcessInfo: Identifiable, CustomStringConvertible, Codable {
    var id: Int
    var timestamp: Date
    var cpuUsage: Double
    var memoryUsage: Double

    init(id: Int, timestamp: Date, cpuUsage: Double, memoryUsage: Double) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }

    func toString() -> String {
        "ProcessInfo | ID: \(id), Time: \(timestamp.formatted()), CPU: \(cpuUsage)%, MEM: \(memoryUsage)%"
    }

    var description: String {
        toString()
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case id, timestamp, cpuUsage, memoryUsage
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(Int.self, forKey: .id)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let cpuUsage = try container.decode(Double.self, forKey: .cpuUsage)
        let memoryUsage = try container.decode(Double.self, forKey: .memoryUsage)
        self.init(id: id, timestamp: timestamp, cpuUsage: cpuUsage, memoryUsage: memoryUsage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(cpuUsage, forKey: .cpuUsage)
        try container.encode(memoryUsage, forKey: .memoryUsage)
    }
}
