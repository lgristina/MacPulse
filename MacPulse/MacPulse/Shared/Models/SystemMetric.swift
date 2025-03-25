//
//  SystemMetric.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/11/25.
//

import Foundation
import SwiftData

@Model
class SystemMetric {  // Use 'class' instead of 'struct'
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
