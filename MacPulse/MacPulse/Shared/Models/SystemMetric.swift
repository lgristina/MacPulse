import SwiftUI
import Foundation
import SwiftData

/// Defines the information contained for system metrics including CPU usage, memory usage, and disk activity.
@Model
class SystemMetric: CustomStringConvertible, Codable {
    
    // MARK: - Properties
    
    /// The timestamp when the metric was recorded.
    var timestamp: Date
    
    /// The percentage of CPU usage.
    var cpuUsage: Double
    
    /// The percentage of memory usage.
    var memoryUsage: Double
    
    /// The percentage of disk activity.
    var diskActivity: Double
    
    // MARK: - Initializer
    
    /// Initializes a new instance of `SystemMetric` with the provided values.
    /// - Parameters:
    ///   - timestamp: The timestamp when the metric was recorded.
    ///   - cpuUsage: The percentage of CPU usage.
    ///   - memoryUsage: The percentage of memory usage.
    ///   - diskActivity: The percentage of disk activity.
    init(timestamp: Date, cpuUsage: Double, memoryUsage: Double, diskActivity: Double) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskActivity = diskActivity
    }
    
    // MARK: - CustomStringConvertible
    
    /// Returns a string description of the system metrics.
    var description: String {
        toString()
    }
    
    /// Converts the system metrics to a string representation.
    /// - Returns: A string describing the system metrics.
    func toString() -> String {
        "SystemMetric | Time: \(timestamp.formatted()), CPU: \(cpuUsage)%, MEM: \(memoryUsage)%, DISK: \(diskActivity)%"
    }
    
    // MARK: - Codable
    
    /// The keys used to encode and decode the `SystemMetric` object.
    enum CodingKeys: CodingKey {
        case timestamp, cpuUsage, memoryUsage, diskActivity
    }
    
    /// Creates a `SystemMetric` from a decoder.
    /// - Parameter decoder: The decoder used to decode the data.
    /// - Throws: An error if decoding fails.
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let cpuUsage = try container.decode(Double.self, forKey: .cpuUsage)
        let memoryUsage = try container.decode(Double.self, forKey: .memoryUsage)
        let diskActivity = try container.decode(Double.self, forKey: .diskActivity)
        self.init(timestamp: timestamp, cpuUsage: cpuUsage, memoryUsage: memoryUsage, diskActivity: diskActivity)
    }
    
    /// Encodes the `SystemMetric` object.
    /// - Parameter encoder: The encoder used to encode the data.
    /// - Throws: An error if encoding fails.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(cpuUsage, forKey: .cpuUsage)
        try container.encode(memoryUsage, forKey: .memoryUsage)
        try container.encode(diskActivity, forKey: .diskActivity)
    }
}

extension SystemMetric {
    /// Converts the `SystemMetric` into a payload for transmission.
    /// - Returns: A `MetricPayload` representing this system metric.
    func asPayload() -> MetricPayload {
        .system(self)
    }
}

