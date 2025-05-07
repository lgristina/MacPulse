//import SwiftUI
//import Charts
//#if os(iOS)
//import UIKit
//#endif
//
///// A view displaying system metrics (such as CPU and Memory usage) for the companion iOS dashboard.
//struct SystemMetricsDashboardiOS: View {
//    // Observed object for monitoring system metrics
//    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared
//    
//    var body: some View {
//        VStack {
//            // Title text for the dashboard
//            Text("Companion Dashboard")
//                .font(.title)
//                .bold()
//                .padding()  // Adds padding around the title
//            
//            // Grid layout to display the CPU and memory usage panels side by side
//            Grid {
//                GridRow {
//                    // Navigation link to a detailed view for CPU usage
//                    NavigationLink(destination: DetailedUsageView<CPUUsageData>(
//                        title: "CPU Usage",  // Title for the detailed view
//                        unit: "%",           // Unit of measurement for CPU usage
//                        lineColor: .blue,    // Color for the CPU usage line graph
//                        currentUsage: systemMonitor.cpuUsage,  // Current CPU usage value
//                        usagePublisher: systemMonitor.$cpuUsage,  // Bind the usage data to the view
//                        makeData: { CPUUsageData(usage: $0, time: $1) }  // Data transformation closure for CPU data
//                    )) {
//                        // Metric panel to display CPU usage in the grid
//                        MetricPanel(title: "CPU Usage", value: systemMonitor.cpuUsage, unit: "%")
//                    }
//                    
//                    // Navigation link to a detailed view for memory usage
//                    NavigationLink(destination: DetailedUsageView<MemoryUsageData>(
//                        title: "Memory Usage",  // Title for the detailed view
//                        unit: "MB",             // Unit of measurement for memory usage
//                        lineColor: .green,     // Color for the memory usage line graph
//                        currentUsage: systemMonitor.memoryUsage,  // Current memory usage value
//                        usagePublisher: systemMonitor.$memoryUsage,  // Bind the usage data to the view
//                        makeData: { MemoryUsageData(usage: $0, time: $1) }  // Data transformation closure for memory data
//                    )) {
//                        // Metric panel to display memory usage in the grid
//                        MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "MB")
//                    }
//                }
//            }
//            .padding()  // Adds padding around the grid
//        }
//        // Perform actions when the view appears
//        .onAppear {
//            // Stop sending previous data and request system metrics
//            if let manager = RemoteSystemMonitor.shared.connectionManager {
//                manager.send(.stopSending(typeToStop: 1))  // Stop sending process metrics
//                manager.send(.sendSystemMetrics)  // Request system metrics data
//            } else {
//                print("⚠️ Connection manager not set on RemoteSystemMonitor.shared")
//            }
//        }
//    }
//}
//
///// Preview provider for SwiftUI preview
//struct SystemMetricsDashboardView_Previews: PreviewProvider {
//    static var previews: some View {
//        SystemMetricsDashboardiOS()
//    }
//}


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

                            NavigationLink(destination: DetailedUsageView<MemoryUsageData>(
                                title: "Memory Usage", unit: "MB", lineColor: .green,
                                currentUsage: systemMonitor.memoryUsage,
                                usagePublisher: systemMonitor.$memoryUsage,
                                makeData: { MemoryUsageData(usage: $0, time: $1) }
                            )) {
                                MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "MB")
                            }

                            // Disk Activity panel (can be expanded with more details)
                            NavigationLink(destination: DiskDetailedView()) {
                                MetricPanel(title: "Disk Activity", value: systemMonitor.diskUsed, unit: "GB")
                            }
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
                            MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "MB")
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
