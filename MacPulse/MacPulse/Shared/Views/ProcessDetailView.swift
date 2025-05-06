//
//  ProcessDetailView.swift
//  MacPulse
//
//  Created by Austin Frank on 3/12/25.
//

import SwiftUI

// MARK: - Process Detail View

/// Displays detailed information about a specific running process,
/// including its name, ID, CPU usage, and memory usage.
///
/// Intended to be shown when a user selects a process from the process list view.
struct ProcessDetailView: View {
    /// Custom model representing a system process and its associated metrics.
    @ObservedObject var viewModel = ProcessMonitor.shared
    let processID: Int

    var body: some View {
        if let process = viewModel.runningProcesses.first(where: { $0.id == processID }) {
            VStack(spacing: 15) {
                // MARK: - Header
                Text("Process Details")
                    .font(.largeTitle)
                    .bold()
                
                // MARK: - Process Name
                HStack {
                    Text("Process name:")
                        .font(.headline)
                    Spacer()
                    Text("\(process.fullProcessName)")
                }
                
                // MARK: - Process ID
                HStack {
                    Text("Process ID:")
                        .font(.headline)
                    Spacer()
                    Text("\(process.id)")
                }
                
                // MARK: - CPU Usage
                HStack {
                    Text("CPU Usage:")
                        .font(.headline)
                    Spacer()
                    Text("\(process.cpuUsage, specifier: "%.2f")%")
                        .foregroundColor(.blue)
                }
                
                // MARK: - Memory Usage
                HStack {
                    Text("Memory Usage:")
                        .font(.headline)
                    Spacer()
                    Text("\(process.memoryUsage, specifier: "%.2f") MB")
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Process \(process.id)")
        }
    }
}
