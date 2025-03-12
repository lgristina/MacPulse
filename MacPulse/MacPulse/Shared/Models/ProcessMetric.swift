//
//  ProcessMetrics.swift
//  MacPulse
//
//  Created by Austin Frank on 3/12/25.
//

import Foundation

struct ProcessInfo: Identifiable, Codable, Hashable{
    let id : Int
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
}
