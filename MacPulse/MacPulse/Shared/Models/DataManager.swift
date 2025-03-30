//
//  DataManager.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 3/14/25.
//

import Foundation
import SwiftData

@MainActor  
class DataManager {
    static let shared = DataManager()
    let context = EncryptedContainer.shared.container.mainContext

    @MainActor
    func saveMetrics(cpu: Double, memory: Double, disk: Double) {
        let newMetric = SystemMetric(timestamp: Date(), cpuUsage: cpu, memoryUsage: memory, diskActivity: disk)
        do {
            context.insert(newMetric)
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
    
    func saveProcessMetrics(processes: [ProcessMetric]) {
            for process in processes {
                print("Saving process: \(process)")
                context.insert(process)
            }

            do {
                try context.save()
                print("✅ Process metrics saved successfully.")
            } catch {
                print("❌ Error saving process metrics: \(error)")
            }
        }

        func fetchRecentProcessMetrics() -> [ProcessMetric] {
            let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
            let fetchDescriptor = FetchDescriptor<ProcessMetric>(predicate: #Predicate { $0.timestamp > oneHourAgo })

            do {
                return try context.fetch(fetchDescriptor)
            } catch {
                print("❌ Error fetching process metrics: \(error)")
                return []
            }
        }

}
