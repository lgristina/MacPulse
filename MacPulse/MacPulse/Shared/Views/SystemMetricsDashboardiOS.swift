import SwiftUI
import Charts
#if os(iOS)
import UIKit
#endif

/// A view displaying system metrics (such as CPU and Memory usage) for the companion iOS dashboard.
struct SystemMetricsDashboardiOS: View {
    // Observed object for monitoring system metrics
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared
    
    var body: some View {
        VStack {
            // Title text for the dashboard
            Text("Companion Dashboard")
                .font(.title)
                .bold()
                .padding()  // Adds padding around the title
            
            // Grid layout to display the CPU and memory usage panels side by side
            Grid {
                GridRow {
                    // Navigation link to a detailed view for CPU usage
                    NavigationLink(destination: DetailedUsageView<CPUUsageData>(
                        title: "CPU Usage",  // Title for the detailed view
                        unit: "%",           // Unit of measurement for CPU usage
                        lineColor: .blue,    // Color for the CPU usage line graph
                        currentUsage: systemMonitor.cpuUsage,  // Current CPU usage value
                        usagePublisher: systemMonitor.$cpuUsage,  // Bind the usage data to the view
                        makeData: { CPUUsageData(usage: $0, time: $1) }  // Data transformation closure for CPU data
                    )) {
                        // Metric panel to display CPU usage in the grid
                        MetricPanel(title: "CPU Usage", value: systemMonitor.cpuUsage, unit: "%")
                    }
                    
                    // Navigation link to a detailed view for memory usage
                    NavigationLink(destination: DetailedUsageView<MemoryUsageData>(
                        title: "Memory Usage",  // Title for the detailed view
                        unit: "MB",             // Unit of measurement for memory usage
                        lineColor: .green,     // Color for the memory usage line graph
                        currentUsage: systemMonitor.memoryUsage,  // Current memory usage value
                        usagePublisher: systemMonitor.$memoryUsage,  // Bind the usage data to the view
                        makeData: { MemoryUsageData(usage: $0, time: $1) }  // Data transformation closure for memory data
                    )) {
                        // Metric panel to display memory usage in the grid
                        MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "MB")
                    }
                }
            }
            .padding()  // Adds padding around the grid
        }
        // Perform actions when the view appears
        .onAppear {
            // Stop sending previous data and request system metrics
            if let manager = RemoteSystemMonitor.shared.connectionManager {
                manager.send(.stopSending(typeToStop: 1))  // Stop sending process metrics
                manager.send(.sendSystemMetrics)  // Request system metrics data
            } else {
                print("⚠️ Connection manager not set on RemoteSystemMonitor.shared")
            }
        }
    }
}

/// Preview provider for SwiftUI preview
struct SystemMetricsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        SystemMetricsDashboardiOS()
    }
}
