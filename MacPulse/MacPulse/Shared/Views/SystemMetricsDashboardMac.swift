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
        NavigationStack{
            VStack {
                Text("Mac Performance Dashboard")
                    .font(.title)
                    .bold()
                    .padding()
                
                Grid {
                    GridRow {
                        NavigationLink(destination: CPUDetailedView()) {
                            MetricPanel(title: "CPU Usage", value: systemMonitor.cpuUsage, unit: "%")
                        }
                        NavigationLink(destination: MemoryDetailedView()) {
                            MetricPanel(title: "Memory Usage", value: systemMonitor.memoryUsage, unit: "MB")
                        }
                        NavigationLink(destination: DiskDetailedView(diskActivity: systemMonitor.diskActivity)) {
                            MetricPanel(title: "Disk Activity", value: systemMonitor.diskActivity, unit: "GB")
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct MetricPanel: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text("\(value, specifier: "%.1f")\(unit)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)
        }
        .frame(width: 150, height: 120)
        .background(RoundedRectangle(cornerRadius: 0.5).fill(Color.gray.opacity(0.2)))
    }
}

struct CPUDetailedView: View {
    @ObservedObject var systemMonitor = SystemMonitor.shared
    @State private var cpuUsageHistory: [CPUUsageData] = []
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("CPU Usage Detailed View")
                .font(.largeTitle)
                .padding(.bottom, 20)

            // 📊 CPU Usage Chart
            Chart(cpuUsageHistory) {
                LineMark(
                    x: .value("Time", $0.time),
                    y: .value("CPU Usage", $0.usage)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 200)
            .padding()

            // 📋 Scrollable List of CPU Usage Percentages
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(cpuUsageHistory.reversed(), id: \.id) { data in
                        HStack {
                            Text("\(data.time, formatter: timeFormatter)")
                            Spacer()
                            Text("\(data.usage, specifier: "%.1f")%")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 300) // Set a limit to keep UI structured
        }
        .onAppear {
            cpuUsageHistory.append(CPUUsageData(usage: systemMonitor.cpuUsage, time: Date())) // ✅ Add initial value
        }
        .onReceive(systemMonitor.$cpuUsage) { newUsage in
            addCPUUsage(newUsage) // ✅ Now updates with live data
        }
        .padding()
    }

    // Function to store CPU usage history
    private func addCPUUsage(_ usage: Double) {
        let newData = CPUUsageData(usage: usage, time: Date())
        cpuUsageHistory.append(newData)

        if cpuUsageHistory.count > 50 {
            cpuUsageHistory.removeFirst()  // Keep history manageable
        }
    }
}


// 🕒 Date Formatter
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()

// 🆔 CPU Usage Data Model
struct CPUUsageData: Identifiable {
    let id = UUID()
    let usage: Double
    let time: Date
}

struct MemoryDetailedView: View {
    @ObservedObject var systemMonitor = SystemMonitor.shared
    @State private var memoryUsageHistory: [MemoryUsageData] = []
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("Memory Usage Detailed View")
                .font(.largeTitle)
                .padding(.bottom, 20)

            // 📊 Memory Usage Chart
            Chart(memoryUsageHistory) {
                LineMark(
                    x: .value("Time", $0.time),
                    y: .value("Memory Usage", $0.usage)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 200)
            .padding()

            // 📋 Scrollable List of Memory Usage Percentages
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(memoryUsageHistory.reversed(), id: \.id) { data in
                        HStack {
                            Text("\(data.time, formatter: timeFormatter)")
                            Spacer()
                            Text("\(data.usage, specifier: "%.1f") MB")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 300) // Set a limit to keep UI structured
        }
        .onAppear {
            memoryUsageHistory.append(MemoryUsageData(usage: systemMonitor.memoryUsage, time: Date())) // ✅ Initial data point
        }
        .onReceive(systemMonitor.$memoryUsage) { newUsage in
            addMemoryUsage(newUsage) // ✅ Updates live
        }
        .padding()
    }

    // Function to store memory usage history
    private func addMemoryUsage(_ usage: Double) {
        let newData = MemoryUsageData(usage: usage, time: Date())
        memoryUsageHistory.append(newData)

        if memoryUsageHistory.count > 50 {
            memoryUsageHistory.removeFirst()  // Keep history manageable
        }
    }
}

// 🆔 Memory Usage Data Model
struct MemoryUsageData: Identifiable {
    let id = UUID()
    let usage: Double
    let time: Date
}


struct SystemMetricsDashboardMac_Previews: PreviewProvider {
    static var previews: some View {
        SystemMetricsDashboardMac()
        
    }
}
