//  SystemMetricsDashboardMac.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/12/25.
//

import SwiftUI
import Charts

struct SystemMetricsDashboardMac: View {
    @ObservedObject var systemMonitor = SystemMonitor.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Mac Performance Dashboard")
                    .font(.title)
                    .bold()
                    .padding()
                
                Grid {
                    GridRow {
                        NavigationLink(destination: DetailedUsageView<CPUUsageData>(
                            title: "CPU Usage",
                            unit: "%",
                            lineColor: .blue,
                            currentUsage: systemMonitor.cpuUsage,
                            usagePublisher: systemMonitor.$cpuUsage,
                            makeData: { CPUUsageData(usage: $0, time: $1) }
                        )) {
                            MetricPanel(title: "CPU Usage", value: systemMonitor.cpuUsage, unit: "%")
                        }
                        
                        NavigationLink(destination: DetailedUsageView<MemoryUsageData>(
                            title: "Memory Usage",
                            unit: "MB",
                            lineColor: .green,
                            currentUsage: systemMonitor.memoryUsage,
                            usagePublisher: systemMonitor.$memoryUsage,
                            makeData: { MemoryUsageData(usage: $0, time: $1) }
                        )) {
                            MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "MB")
                        }
                        
                        NavigationLink(destination: DiskPieChartView()) {
                            MetricPanel(title: "Disk Activity", value: systemMonitor.diskActivity, unit: "GB")
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct SystemMetricsDashboardMac_Previews: PreviewProvider {
    static var previews: some View {
        SystemMetricsDashboardMac()
        
    }
}
