import SwiftUI
import Charts

#if os(iOS)
import UIKit
#endif

/// Shared view for displaying system metrics (CPU, Memory, and Disk activity) for both macOS and iOS.
struct SystemMetricsDashboard: View {
    #if os(macOS)
    @ObservedObject var systemMonitor = SystemMonitor.shared
    #else
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared
    @State private var hasInitialized = false
    #endif


    var body: some View {
            #if os(macOS)
            // macOS-specific view content
            NavigationStack {
                VStack {
                    Text("Mac Performance Dashboard")
                        .font(.title)
                        .bold()
                        .padding()

                    // macOS-specific Grid
                    Grid {
                        GridRow {
                            NavigationLink(destination: DetailedUsageView<CPUUsageData>(
                                title: "CPU Usage", unit: "%", lineColor: .blue,
                                currentUsage: systemMonitor.cpuUsage,
                                usagePublisher: systemMonitor.$cpuUsage,
                                makeData: { CPUUsageData(usage: $0, time: $1) }
                            )) {
                                MetricPanel(title: "CPU Usage", value: systemMonitor.cpuUsage, unit: "%")
                            }
                            .accessibilityIdentifier("CPU Usage Panel")

                            NavigationLink(destination: DetailedUsageView<MemoryUsageData>(
                                title: "Memory Usage", unit: "MB", lineColor: .green,
                                currentUsage: systemMonitor.memoryUsage,
                                usagePublisher: systemMonitor.$memoryUsage,
                                makeData: { MemoryUsageData(usage: $0, time: $1) }
                            )) {
                                MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "GB")
                            }
                            .accessibilityIdentifier("Memory Usage Panel")

                            // Disk Activity panel (can be expanded with more details)
                            NavigationLink(destination: DiskDetailedView()) {
                                MetricPanel(title: "Disk Usage", value: systemMonitor.diskUsed, unit: "GB")
                            }
                            .accessibilityIdentifier("Disk Usage Panel")
                        }
                    }
                    .padding()
                }
            }
            #elseif os(iOS)
            // iOS-specific view content
            VStack {
                Text("Companion Dashboard")
                    .font(.title)
                    .bold()
                    .padding()

                Grid {
                    GridRow {
                        NavigationLink(destination: DetailedUsageView<CPUUsageData>(
                            title: "CPU Usage", unit: "%", lineColor: .blue,
                            currentUsage: systemMonitor.cpuUsage,
                            usagePublisher: systemMonitor.$cpuUsage,
                            makeData: { CPUUsageData(usage: $0, time: $1) }
                        )) {
                            MetricPanel(title: "CPU Usage", value: systemMonitor.cpuUsage, unit: "%")
                        }

                        NavigationLink(destination: DetailedUsageView<MemoryUsageData>(
                            title: "Memory Usage", unit: "MB", lineColor: .green,
                            currentUsage: systemMonitor.memoryUsage,
                            usagePublisher: systemMonitor.$memoryUsage,
                            makeData: { MemoryUsageData(usage: $0, time: $1) }
                        )) {
                            MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "GB")
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                if !hasInitialized {
                    hasInitialized = true
                    if let manager = systemMonitor.connectionManager {
                        manager.send(.stopSending(typeToStop: 1))  // Stop sending process metrics on iOS
                        manager.send(.sendSystemMetrics)  // Request system metrics data on iOS
                    }
                }
            }
            #endif
        }
    }

/// Preview for both platforms
struct SystemMetricsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SystemMetricsDashboard()
                .previewDisplayName("macOS Preview")
            SystemMetricsDashboard()
                .previewDisplayName("iOS Preview")
        }
    }
}
