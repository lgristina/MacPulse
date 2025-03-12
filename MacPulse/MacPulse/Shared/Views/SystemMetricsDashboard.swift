//
//  SystemMetricsDashboard.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/11/25.
//


import SwiftUI
import Charts


struct SystemMetricsDashboard: View {
    @ObservedObject var viewModel = SystemMonitor()
    @ObservedObject var processModel = ProcessModel()
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack(spacing: 20) {
                    Text("Mac Performance Dashboard")
                        .font(.title)
                        .bold()
                    
                    NavigationLink(destination: CPUDetailedView()) {
                        MetricPanel(title: "CPU Usage", value: viewModel.cpuUsage, unit: "%")
                    }
                    
                    NavigationLink(destination: MemoryDetailedView(memoryUsage: viewModel.memoryUsage)) {
                        MetricPanel(title: "Memory Usage", value: viewModel.memoryUsage, unit: "%")
                    }
                    
                    NavigationLink(destination: DiskDetailedView(diskActivity: viewModel.diskActivity)) {
                        MetricPanel(title: "Disk Activity", value: viewModel.diskActivity, unit: "%")
                    }
                    
                    NavigationLink(destination: ProcessDetailedView(processes: processModel.runningProcesses)) {
                        ProcessPanel(title: "Running Processes", processes: processModel.runningProcesses)
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
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.2)))
    }
}

struct ProcessPanel: View {
    let title: String
    let processes: [ProcessInfo]

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            List(processes, id: \.id) { process in
                Text(String(process.id))
            }
        }
        .frame(width: 200, height: 120)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.2)))
    }
}

// MARK: - Detailed Views
struct CPUDetailedView: View {
    @State private var cpuUsageHistory: [CPUUsageData] = []
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

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

            // 📋 List of CPU Usage Percentages
            List(cpuUsageHistory.reversed(), id: \.id) { data in
                HStack {
                    Text("\(data.time, formatter: timeFormatter)")
                    Spacer()
                    Text("\(data.usage, specifier: "%.1f")%")
                        .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            addCPUUsage()
        }
        .onReceive(timer) { _ in
            addCPUUsage()
        }
        .padding()
    }

    // Function to simulate CPU usage data collection
    private func addCPUUsage() {
        let newUsage = Double.random(in: 20.0...80.0)  // Simulated data
        let newData = CPUUsageData(usage: newUsage, time: Date())
        cpuUsageHistory.append(newData)

        if cpuUsageHistory.count > 50 {
            cpuUsageHistory.removeFirst()  // Keep history manageable
        }
    }
}

// Model for CPU Usage Data
struct CPUUsageData: Identifiable {
    let id = UUID()
    let usage: Double
    let time: Date
}

// Formatter for displaying time in the list
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()

struct MemoryDetailedView: View {
    let memoryUsage: Double
    
    var body: some View {
        VStack {
            Text("Memory Detailed View")
                .font(.largeTitle)
            Text("Current Memory Usage: \(memoryUsage, specifier: "%.1f")%")
                .font(.title)
            // Additional detailed memory metrics here
        }
        .padding()
    }
}

struct DiskDetailedView: View {
    let diskActivity: Double
    
    var body: some View {
        VStack {
            Text("Disk Activity Detailed View")
                .font(.largeTitle)
            Text("Current Disk Activity: \(diskActivity, specifier: "%.1f")%")
                .font(.title)
            // Additional detailed disk metrics here
        }
        .padding()
    }
}

struct ProcessDetailedView: View {
    let processes: [ProcessInfo]
    
    var body: some View {
        VStack {
            Text("Running Processes Detailed View")
                .font(.largeTitle)
            List(processes, id: \.self) { process in
                Text(String(process.id))
            }
        }
        .padding()
    }
}

struct SystemMetricsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        SystemMetricsDashboard()
            .previewDevice("iPhone 16 Pro")
    }
}
