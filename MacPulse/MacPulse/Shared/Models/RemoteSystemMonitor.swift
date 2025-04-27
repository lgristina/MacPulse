//
//  RemoteSystemMonitor.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/16/25.
//  Updated by Austin Frank on 4/17/25.
//

import Foundation
import Combine

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


struct MetricsData: Codable {
    let cpu: Double
    let memory: Double
    let disk: Double
}
class RemoteSystemMonitor: ObservableObject {
    static var shared = RemoteSystemMonitor(connectionManager: nil)
    
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: Double = 0.0
    @Published var diskActivity: Double = 0.0
    
    @Published var systemMetricTimer: Timer? // Timer to control querying interval
    @Published var processMetricTimer: Timer? // Timer to control querying interval
    
    @Published var remoteProcesses: [CustomProcessInfo] = []
    
    var connectionManager: MCConnectionManager?
    
    init(connectionManager: MCConnectionManager?) {
        self.connectionManager = connectionManager
        self.connectionManager?.onReceiveMetric = { [weak self] payload in
            self?.updateMetrics(from: payload)
        }
    }
    
    func configure(connectionManager: MCConnectionManager) {
        self.connectionManager = connectionManager
        self.connectionManager?.onReceiveMetric = { [weak self] payload in
            self?.updateMetrics(from: payload)
        }
    }
    // Method to stop sending metrics
    func stopSendingMetrics(type: Int) {
        switch type {
        case 0:
            // Stop sending system metrics
            systemMetricTimer?.invalidate()
            systemMetricTimer = nil
            print("Stopped sending system metrics.")
        case 1:
            // Stop sending process metrics
            processMetricTimer?.invalidate()
            processMetricTimer = nil
            print("Stopped sending process metrics.")
        default:
            break
        }
    }
    private func updateMetrics(from payload: MetricPayload) {
        DispatchQueue.main.async {
            switch payload {
            case .system(let metric):
                self.cpuUsage = metric.cpuUsage
                self.memoryUsage = metric.memoryUsage
                self.diskActivity = metric.diskActivity
            case .process(let processes):
                self.remoteProcesses = processes
            default:
                //print("PAYLOAD: \(payload)")
                break
            }
        }
    }
    
    func startSendingMetrics(type: Int) {
        switch type {
        case 0:
            systemMetricTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in    // Collect the latest metrics
                let metrics = SystemMonitor.shared.lastMetrics
                let payload = MetricPayload.system(metrics ?? SystemMetric(timestamp: Date(), cpuUsage: 0, memoryUsage: 0.0, diskActivity: 0.0))
                self.connectionManager?.send(payload)
            }
        case 1:
            processMetricTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in                    // Collect the latest metrics
                let metrics = ProcessMonitor.shared.runningProcesses
                let payload = MetricPayload.process(metrics)
                self.connectionManager?.send(payload)
            }
        default:
            print("Invalid metric type!")
            
        }
    }
}
