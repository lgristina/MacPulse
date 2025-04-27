//
//  SystemMetric.swift
//  MacPulse
//
//  Created by Austin Frank on 3/30/25.
//
import SwiftUI
import Foundation
import SwiftData

@Model
class SystemMetric: CustomStringConvertible, Codable {
    var timestamp: Date
    var cpuUsage: Double
    var memoryUsage: Double
    var diskActivity: Double
    
    init(timestamp: Date, cpuUsage: Double, memoryUsage: Double, diskActivity: Double) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskActivity = diskActivity
    }
    
    func toString() -> String {
        "SystemMetric | Time: \(timestamp.formatted()), CPU: \(cpuUsage)%, MEM: \(memoryUsage)%, DISK: \(diskActivity)%"
    }
    
    var description: String {
        toString()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: CodingKey {
        case timestamp, cpuUsage, memoryUsage, diskActivity
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let cpuUsage = try container.decode(Double.self, forKey: .cpuUsage)
        let memoryUsage = try container.decode(Double.self, forKey: .memoryUsage)
        let diskActivity = try container.decode(Double.self, forKey: .diskActivity)
        self.init(timestamp: timestamp, cpuUsage: cpuUsage, memoryUsage: memoryUsage, diskActivity: diskActivity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(cpuUsage, forKey: .cpuUsage)
        try container.encode(memoryUsage, forKey: .memoryUsage)
        try container.encode(diskActivity, forKey: .diskActivity)
    }
}

extension SystemMetric {
    func asPayload() -> MetricPayload {
        .system(self)
    }
}
