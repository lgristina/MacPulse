//
//  ProcessInfo.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 3/25/25.
//

import Foundation
import SwiftData

@Model  
class ProcessInfo: Identifiable {
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
}

