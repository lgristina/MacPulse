import SwiftUI

// MARK: - Process List View

// Displays a list of running processes with sorting options by PID, CPU, or memory.
// Data is fetched locally on macOS or remotely via Multipeer Connectivity on iOS.
struct ProcessListView: View {
#if os(macOS)
    @ObservedObject private var viewModel = ProcessMonitor.shared // Local system monitor
#endif
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared // Remote monitor for iOS

    // Sorting criteria options
    enum SortCriteria {
        case pid, cpuUsage, memoryUsage
    }

    // Tracks which sorting option is selected
    @State private var sortCriteria: SortCriteria = .pid

    var body: some View {
        NavigationView {
            VStack {
                // Sorting menu with options
                Menu {
                    Button("Sort by PID") {
                        sortCriteria = .pid
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

                // Choose the correct process source based on platform
                #if os(macOS)
                    let processes = viewModel.runningProcesses
                #else
                    let processes = systemMonitor.remoteProcesses
                #endif

                // Sort the processes using the selected criteria
                let sortedProcesses = sortedProcesses(for: processes)

                // Display the sorted process list
                List(sortedProcesses) { process in
                    NavigationLink(destination: ProcessDetailView(process: process)) {
                        VStack(alignment: .leading) {
                            Text("PID: \(process.id)")
                                .font(.headline)
                            Text("CPU Usage: \(process.cpuUsage, specifier: "%.1f")%")
                                .foregroundColor(.blue)
                            Text("Memory Usage: \(process.memoryUsage, specifier: "%.1f") MB")
                                .foregroundColor(.green)
                        }
                        .padding(5)
                    }
                }
                .navigationTitle("Running Processes")
                .onAppear {
                    // Request process metrics from the Mac if a connection exists
                    if let manager = RemoteSystemMonitor.shared.connectionManager {
                        manager.send(.stopSending(typeToStop: 0))
                        print("REQUESTING PROCESS METRICS!")
                        manager.send(.sendProcessMetrics)
                    } else {
                        print("⚠️ Connection manager not set on RemoteSystemMonitor.shared")
                    }
                }
            }
        }
    }

    // MARK: - Sorting Function

    // Sorts the process array based on the selected sort criteria
    private func sortedProcesses(for processes: [CustomProcessInfo]) -> [CustomProcessInfo] {
        switch sortCriteria {
        case .pid:
            return processes.sorted { $0.id < $1.id }
        case .cpuUsage:
            return processes.sorted { $0.cpuUsage > $1.cpuUsage }
        case .memoryUsage:
            return processes.sorted { $0.memoryUsage > $1.memoryUsage }
        }
    }
}
