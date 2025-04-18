//
//  SystemMetricsDashboard.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/11/25.
//


import SwiftUI
import Charts
#if os(iOS)
import UIKit
#endif


struct SystemMetricsDashboardiOS: View {
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared

    var body: some View {
        VStack {
            Text("Companion Dashboard")
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
                }
            }
            .padding()
        }
    }
}


struct SystemMetricsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        SystemMetricsDashboardiOS()
    }
}
