import Foundation
import Combine

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Acts as the bridge between the MacPulse macOS and iOS apps.
///
/// `RemoteSystemMonitor` receives system and process metrics from the Mac app,
/// updates its published properties, and makes them accessible to the iOS dashboard.
/// All communication to/from the iOS side flows through this class.
class RemoteSystemMonitor: ObservableObject {
    /// Shared singleton instance
    static var shared = RemoteSystemMonitor(connectionManager: nil)
    
    /// Current CPU usage from the remote Mac
    @Published var cpuUsage: Double = 0.0
    
    /// Current memory usage from the remote Mac
    @Published var memoryUsage: Double = 0.0
    
    /// Current disk activity from the remote Mac
    @Published var diskActivity: Double = 0.0
    
    /// Timer controlling how often system metrics are sent
    @Published var systemMetricTimer: Timer?
    
    /// Timer controlling how often process metrics are sent
    @Published var processMetricTimer: Timer?
    
    /// Latest received remote process list
    @Published var remoteProcesses: [CustomProcessInfo] = []
    
    /// Manages the connection to the peer device (macOS app)
    var connectionManager: MCConnectionManager?
    
    /// Initializes a new `RemoteSystemMonitor` with an optional connection manager.
    /// Assigns the metric receive handler if the connection manager is provided.
    init(connectionManager: MCConnectionManager?) {
        self.connectionManager = connectionManager
        self.connectionManager?.onReceiveMetric = { [weak self] payload in
            self?.updateMetrics(from: payload)
        }
    }
    
    /// Configures the connection manager post-initialization.
    /// Re-assigns the metric receive handler.
    func configure(connectionManager: MCConnectionManager) {
        self.connectionManager = connectionManager
        self.connectionManager?.onReceiveMetric = { [weak self] payload in
            self?.updateMetrics(from: payload)
        }
    }
    
    /// Stops sending metrics based on the type:
    /// - 0: system metrics
    /// - 1: process metrics
    func stopSendingMetrics(type: Int) {
        switch type {
        case 0:
            systemMetricTimer?.invalidate()
            systemMetricTimer = nil
            print("Stopped sending system metrics.")
        case 1:
            processMetricTimer?.invalidate()
            processMetricTimer = nil
            print("Stopped sending process metrics.")
        default:
            break
        }
    }
    
    /// Starts sending metrics of the given type at 1-second intervals:
    /// - 0: system metrics
    /// - 1: process metrics
    func startSendingMetrics(type: Int) {
        switch type {
        case 0:
            systemMetricTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let metrics = SystemMonitor.shared.lastMetrics
                let payload = MetricPayload.system(metrics ?? SystemMetric(timestamp: Date(), cpuUsage: 0, memoryUsage: 0.0, diskActivity: 0.0))
                self.connectionManager?.send(payload)
            }
        case 1:
            processMetricTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let metrics = ProcessMonitor.shared.runningProcesses
                let payload = MetricPayload.process(metrics)
                self.connectionManager?.send(payload)
            }
        default:
            print("Invalid metric type!")
        }
    }
    
    /// Updates the published properties with the latest data from the received payload.
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
                break
            }
        }
    }
}
