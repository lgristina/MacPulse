import Foundation
import Combine

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


/// <#Description#>
/// The interface between the MacPulse iOS and MacPulse macOS
/// Any information requested by the iOS application must flow through
/// the RemoteSystemMonitor.

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
    
    @Published var systemMetricTimer: Timer?
    @Published var processMetricTimer: Timer?
    
    @Published var remoteProcesses: [CustomProcessInfo] = []
    
    var connectionManager: MCConnectionManager?
    
    init(connectionManager: MCConnectionManager?) {
        self.connectionManager = connectionManager
        self.connectionManager?.onReceiveMetric = { [weak self] payload in
            self?.updateMetrics(from: payload)
        }
        LogManager.shared.log(.syncTransmission, level: .medium, "📡 RemoteSystemMonitor initialized.")
    }
    
    func configure(connectionManager: MCConnectionManager) {
        self.connectionManager = connectionManager
        self.connectionManager?.onReceiveMetric = { [weak self] payload in
            self?.updateMetrics(from: payload)
        }
        LogManager.shared.log(.syncTransmission, level: .medium, "🔄 RemoteSystemMonitor reconfigured with new connection manager.")
    }

    func stopSendingMetrics(type: Int) {
        switch type {
        case 0:

            systemMetricTimer?.invalidate()
            systemMetricTimer = nil
            LogManager.shared.log(.syncTransmission, level: .medium, "🛑 Stopped sending system metrics.")
        case 1:
            processMetricTimer?.invalidate()
            processMetricTimer = nil
            LogManager.shared.log(.syncTransmission, level: .medium, "🛑 Stopped sending process metrics.")
        default:
            LogManager.shared.log(.syncTransmission, level: .low, "⚠️ Attempted to stop unknown metric type: \(type).")
        }
    }

    private func updateMetrics(from payload: MetricPayload) {
        DispatchQueue.main.async {
            switch payload {
            case .system(let metric):
                self.cpuUsage = metric.cpuUsage
                self.memoryUsage = metric.memoryUsage
                self.diskActivity = metric.diskActivity
                LogManager.shared.log(.syncTransmission, level: .low, "📈 Received system metrics: CPU \(metric.cpuUsage)%, Mem \(metric.memoryUsage)MB, Disk \(metric.diskActivity)%")
            case .process(let processes):
                self.remoteProcesses = processes
                LogManager.shared.log(.syncTransmission, level: .low, "📊 Received \(processes.count) remote process metrics.")
            default:
                LogManager.shared.log(.syncTransmission, level: .low, "ℹ️ Received unknown metric payload.")
            }
        }
    }

    func startSendingMetrics(type: Int) {
        switch type {
        case 0:
            systemMetricTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let metrics = SystemMonitor.shared.lastMetrics
                let payload = MetricPayload.system(metrics ?? SystemMetric(timestamp: Date(), cpuUsage: 0, memoryUsage: 0.0, diskActivity: 0.0))
                self.connectionManager?.send(payload)
                LogManager.shared.log(.syncTransmission, level: .low, "📤 Sent system metrics payload.")
            }
            LogManager.shared.log(.syncTransmission, level: .medium, "⏱️ Started sending system metrics every second.")
        case 1:
            processMetricTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let metrics = ProcessMonitor.shared.runningProcesses
                let payload = MetricPayload.process(metrics)
                self.connectionManager?.send(payload)
                LogManager.shared.log(.syncTransmission, level: .low, "📤 Sent process metrics payload.")
            }
            LogManager.shared.log(.syncTransmission, level: .medium, "⏱️ Started sending process metrics every second.")
        default:
            LogManager.shared.log(.syncTransmission, level: .high, "❌ Invalid metric type requested: \(type).")
        }
    }
}
