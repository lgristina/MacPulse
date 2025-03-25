//
//  DataManager.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 3/14/25.
//

import Foundation
import SwiftData

@MainActor  // Ensures all methods run on the main thread
class DataManager {
    static let shared = DataManager()
    let context = EncryptedContainer.shared.container.mainContext

    @MainActor  // Ensures this function runs in the correct thread
    func saveMetrics(cpu: Double, memory: Double, disk: Double) {
        let newMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
        do {
            context.insert(newMetric)  // Now correctly runs in @MainActor
            try context.save()
        } catch {
            print("Error saving metric: \(error)")
        }
    }

    @MainActor  // Fetching data must also be @MainActor
    func fetchRecentMetrics() -> [SystemMetric] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let fetchDescriptor = FetchDescriptor<SystemMetric>(predicate: #Predicate { $0.timestamp > sevenDaysAgo })

        do {
            return try context.fetch(fetchDescriptor)
        } catch {
            print("Error fetching metrics: \(error)")
            return []
        }
    }
}
