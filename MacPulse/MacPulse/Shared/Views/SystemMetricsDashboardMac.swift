//  SystemMetricsDashboardMac.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/12/25.
//

import SwiftUI
import Charts

struct SystemMetricsDashboardMac: View {
    @ObservedObject var viewModel = SystemMonitor()
    @ObservedObject var processModel = ProcessModel()
    
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
                        MetricPanel(title: "Memory Usage", value: viewModel.memoryUsage, unit: "MB")
                    }
                }
                GridRow {
                    NavigationLink(destination: DiskDetailedView(diskActivity: viewModel.diskActivity)) {
                        MetricPanel(title: "Disk Activity", value: viewModel.diskActivity, unit: "MB")
                    }
                    NavigationLink(destination: ProcessDetailedView(processes: processModel.runningProcesses)) {
                        ProcessPanel(title: "Running Processes", processes: processModel.runningProcesses)
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
