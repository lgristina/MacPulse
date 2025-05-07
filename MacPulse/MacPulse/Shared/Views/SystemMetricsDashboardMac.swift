//import SwiftUI
//import Charts
//
//
//
///// Displays system performance metrics (CPU, Memory, and Disk activity) for the macOS dashboard.
//struct SystemMetricsDashboardMac: View {
//    @ObservedObject var systemMonitor = SystemMonitor.shared
//    @Environment(\.modelContext) private var context
//    
//    var body: some View {
//        NavigationStack {
//            VStack {
//                Text("Mac Performance Dashboard")
//                    .font(.title)
//                    .bold()
//                    .padding()
//                
//                Grid {
//                    GridRow {
//                        // CPU usage panel with navigation to a detailed view
//                        NavigationLink(destination: DetailedUsageView<CPUUsageData>(
//                            title: "CPU Usage", unit: "%", lineColor: .blue,
//                            currentUsage: systemMonitor.cpuUsage,
//                            usagePublisher: systemMonitor.$cpuUsage,
//                            makeData: { CPUUsageData(usage: $0, time: $1) }
//                        )) {
//                            MetricPanel(title: "CPU Usage", value: systemMonitor.cpuUsage, unit: "%")
//                        }
//                        
//                        // Memory usage panel with navigation to a detailed view
//                        NavigationLink(destination: DetailedUsageView<MemoryUsageData>(
//                            title: "Memory Usage", unit: "MB", lineColor: .green,
//                            currentUsage: systemMonitor.memoryUsage,
//                            usagePublisher: systemMonitor.$memoryUsage,
//                            makeData: { MemoryUsageData(usage: $0, time: $1) }
//                        )) {
//                            MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "MB")
//                        }
//                        
//                        // Disk activity panel with navigation to a pie chart view
//                        NavigationLink(destination: DiskDetailedView()) {
//                            MetricPanel(title: "Disk Activity", value: systemMonitor.diskUsed, unit: "GB")
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//    }
//}
//
///// Preview for macOS performance dashboard.
//struct SystemMetricsDashboardMac_Previews: PreviewProvider {
//    static var previews: some View {
//        SystemMetricsDashboardMac()
//    }
//}
