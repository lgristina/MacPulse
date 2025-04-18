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

                        NavigationLink(destination: DiskDetailedView()) {
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

// 🕒 Date Formatter
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()

protocol UsageData: Identifiable {
    var time: Date { get }
    var value: Double { get }
}

struct CPUUsageData: UsageData {
    let id = UUID()
    let usage: Double
    let time: Date
    var value: Double { usage }
}

struct MemoryUsageData: UsageData {
    let id = UUID()
    let usage: Double
    let time: Date
    var value: Double { usage }
}

struct DetailedUsageView<Data: UsageData>: View {
    let title: String
    let unit: String
    let lineColor: Color
    let currentUsage: Double
    let usagePublisher: Published<Double>.Publisher
    // Closure to create a new data point for the history log.
    let makeData: (Double, Date) -> Data

    @State private var usageHistory: [Data] = []

    var body: some View {
        VStack {
            Text("\(title) Detailed View")
                .font(.largeTitle)
                .padding(.bottom, 20)

            // Usage Chart
            Chart(usageHistory) {
                LineMark(
                    x: .value("Time", $0.time),
                    y: .value(title, $0.value)
                )
                .foregroundStyle(lineColor)
            }
            .frame(height: 200)
            .padding()

            // Scrollable List of Usage Data
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(usageHistory.reversed(), id: \.id) { data in
                        HStack {
                            Text("\(data.time, formatter: timeFormatter)")
                            Spacer()
                            Text("\(data.value, specifier: "%.1f") \(unit)")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .onAppear {
            // Add an initial data point from the current value
            usageHistory.append(makeData(currentUsage, Date()))
        }
        .onReceive(usagePublisher) { newUsage in
            addUsage(newUsage)
        }
        .padding()
    }

    // Append new data and maintain history count.
    private func addUsage(_ usage: Double) {
        let newData = makeData(usage, Date())
        usageHistory.append(newData)
        if usageHistory.count > 50 {
            usageHistory.removeFirst()
        }
    }
}

struct DiskDetailedView: View {
    @ObservedObject var systemMonitor = SystemMonitor.shared
    @State var diskUsageData: [DiskActivityData] = []
    
    var body: some View {
        Text("Disk Detailed View")
    }
}

struct DiskActivityData: Identifiable {
    let id = UUID()
    
}

struct SystemMetricsDashboardMac_Previews: PreviewProvider {
    static var previews: some View {
        SystemMetricsDashboardMac()
        
    }
}
