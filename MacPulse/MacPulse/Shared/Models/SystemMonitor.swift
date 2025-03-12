//
//  SystemMonitor.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/11/25.
//

import Foundation

class SystemMonitor {
    static func getCPUUsage() -> Double {
        return Double.random(in: 0...100)  // Replace with real system API call
    }

    static func getMemoryUsage() -> Double {
        return Double.random(in: 0...100)  // Replace with real system API call
    }

    static func getDiskActivity() -> Double {
        return Double.random(in: 0...100)  // Replace with real system API call
    }
    
    static func getRunningProcesses() -> [String] {
        return ["Safari", "Xcode", "Terminal", "Messages", "Finder"] // Replace with real process fetch
    }
}
