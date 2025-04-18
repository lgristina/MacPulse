//
//  RemoteSystemMonitor.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/16/25.
//

import Foundation
import Combine
import MultipeerConnectivity

// Shared data model used for transmitting system metrics.
// Ensure that the macOS app uses the same structure when encoding the metrics.
struct MetricsData: Codable {
    let cpu: Double
    let memory: Double
    let disk: Double
}

class RemoteSystemMonitor: ObservableObject {
    static let shared = RemoteSystemMonitor()
    
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var diskActivity: Double = 0.0
    
    private var connectivityService: MultipeerConnectivityService
    
    init() {
        // Initialize your connectivity service.
        self.connectivityService = MultipeerConnectivityService()
        
        // Set the onReceive closure to get notified when data arrives.
        self.connectivityService.onReceive = { [weak self] data in
            print("RemoteSystemMonitor: Received data of length \(data.count) bytes")
            self?.updateMetrics(from: data)
        }
    }
    
    private func updateMetrics(from data: Data) {
        do {
            let metrics = try JSONDecoder().decode(MetricsData.self, from: data)
            // Ensure UI updates happen on the main thread.
            DispatchQueue.main.async {
                self.cpuUsage = metrics.cpu
                self.memoryUsage = metrics.memory
                self.diskActivity = metrics.disk
                print("RemoteSystemMonitor: Updated metrics - CPU: \(metrics.cpu), Memory: \(metrics.memory), Disk: \(metrics.disk)")
            }
        } catch {
            print("RemoteSystemMonitor: Error decoding metrics data: \(error)")
        }
    }
}
