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
class SystemMetric {
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
}
