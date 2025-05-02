//
//  ProcessDetailView.swift
//  MacPulse
//
//  Created by Austin Frank on 3/12/25.
//

import SwiftUI

// MARK: - Process Detail View

/// Displays detailed information for a single running process,
/// including PID, CPU usage, and memory usage.
struct ProcessDetailView: View {
    let process: CustomProcessInfo

    var body: some View {
        VStack(spacing: 15) {
            // View title
            Text("Process Details")
                .font(.largeTitle)
                .bold()

            // Process ID row
            HStack {
                Text("Process name:")
                    .font(.headline)
                Spacer()
                Text("\(process.fullProcessName)")
            }
            
            HStack {
                Text("Process ID:")
                    .font(.headline)
                Spacer()
                Text("\(process.id)")
            }

            // CPU usage row
            HStack {
                Text("CPU Usage:")
                    .font(.headline)
                Spacer()
                Text("\(process.cpuUsage, specifier: "%.2f")%")
                    .foregroundColor(.blue)
            }

            // Memory usage row
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
