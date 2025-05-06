//
//  ProcessListView.swift
//  MacPulse
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

/// Displays a list of running processes along with CPU and memory usage metrics.
/// Supports platform-specific data sources (local for macOS, remote for iOS),
/// and provides a dropdown menu to sort the list by name, CPU, or memory usage.
struct ProcessListView: View {
    #if os(macOS)
    @ObservedObject private var viewModel = ProcessMonitor.shared
    #endif
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared

    /// Sorting options for the process list.
    enum SortCriteria {
        case shortProcessName, cpuUsage, memoryUsage
    }

    @State private var sortCriteria: SortCriteria = .shortProcessName

    var body: some View {
        NavigationView {
            VStack {
                // Sorting Dropdown Menu
                Menu {
                    Button("Sort by Process Name") {
                        sortCriteria = .shortProcessName
                    }
                    Button("Sort by CPU Usage") {
                        sortCriteria = .cpuUsage
                    }
                    Button("Sort by Memory Usage") {
                        sortCriteria = .memoryUsage
                    }
                } label: {
                    Label("Sort by", systemImage: "arrow.up.arrow.down.circle")
                        .font(.title2)
                        .padding()
                }

                // Select correct source of processes depending on platform
                #if os(macOS)
                let processes = viewModel.runningProcesses
                #else
                let processes = systemMonitor.remoteProcesses
                #endif

                // Display sorted list
                let sortedProcesses = sortedProcesses(for: processes)

                List(sortedProcesses) { process in
                    NavigationLink(destination: ProcessDetailView(processID: process.id)) {
                        VStack(alignment: .leading) {
                            Text("Process: \(process.shortProcessName)")
                                .font(.headline)
                            Text("CPU Usage: \(process.cpuUsage, specifier: "%.1f")%")
                                .foregroundColor(.blue)
                            Text("Memory Usage: \(process.memoryUsage, specifier: "%.1f") MB")
                                .foregroundColor(.green)
                        }
                        .padding(5)
                        .frame(maxHeight: .infinity)
                    }
                }
                .navigationTitle("Running Processes")
                .onAppear {
                    if let manager = RemoteSystemMonitor.shared.connectionManager {
                        manager.send(.stopSending(typeToStop: 0)) // Stop previous data stream
                        print("REQUESTING PROCESS METRICS!")
                        manager.send(.sendProcessMetrics) // Request new metrics
                    } else {
                        print("⚠️ Connection manager not set on RemoteSystemMonitor.shared")
                    }
                }

                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
    }

    /// Returns a new list of processes sorted according to the selected criteria.
    private func sortedProcesses(for processes: [CustomProcessInfo]) -> [CustomProcessInfo] {
        switch sortCriteria {
        case .shortProcessName:
            return processes.sorted { $0.shortProcessName < $1.shortProcessName }
        case .cpuUsage:
            return processes.sorted { $0.cpuUsage > $1.cpuUsage }
        case .memoryUsage:
            return processes.sorted { $0.memoryUsage > $1.memoryUsage }
        }
    }
}
