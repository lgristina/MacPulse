//
//  SystemMetricsDashboardMac.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/12/25.
//

import SwiftUI
import Charts

struct SystemMetricsDashboardMac: View {
    @ObservedObject var viewModel = SystemMetricsViewModel()
    
    var body: some View {
        VStack {
            Text("Mac Performance Dashboard")
                .font(.title)
                .bold()
                .padding()
            
            Grid {
                GridRow {
                    NavigationLink(destination: CPUDetailedView()) {
                        MetricPanel(title: "CPU Usage", value: viewModel.cpuUsage, unit: "%")
                    }
                    NavigationLink(destination: MemoryDetailedView(memoryUsage: viewModel.memoryUsage)) {
                        MetricPanel(title: "Memory Usage", value: viewModel.memoryUsage, unit: "%")
                    }
                }
                GridRow {
                    NavigationLink(destination: DiskDetailedView(diskActivity: viewModel.diskActivity)) {
                        MetricPanel(title: "Disk Activity", value: viewModel.diskActivity, unit: "%")
                    }
                    NavigationLink(destination: ProcessDetailedView(processes: viewModel.runningProcesses)) {
                        ProcessPanel(title: "Running Processes", processes: viewModel.runningProcesses)
                    }
                }
            }
            .padding()
        }
    }
}

struct SystemMetricsDashboardMac_Previews: PreviewProvider {
    static var previews: some View {
        SystemMetricsDashboardMac()
    }
}
