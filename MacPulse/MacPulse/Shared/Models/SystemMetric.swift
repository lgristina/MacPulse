//
//  SystemMetric.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/11/25.
//

import Foundation

struct SystemMetric: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let diskActivity: Double
}
