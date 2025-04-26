import SwiftUI

struct ProcessListView: View {
    #if os(macOS)
    @ObservedObject private var viewModel = ProcessMonitor.shared
    #endif
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared
    
    // Enum to define sorting criteria
    enum SortCriteria {
        case pid, cpuUsage, memoryUsage
    }
    
    // Property to track the selected sorting criteria
    @State private var sortCriteria: SortCriteria = .pid
    
    var body: some View {
        NavigationView {
            VStack {
                // Dropdown menu for sorting
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

                #if os(macOS)
                let processes = viewModel.runningProcesses
                #else
                let processes = systemMonitor.remoteProcesses
                #endif
                
                // Sorting the list based on selected criteria
                let sortedProcesses = sortedProcesses(for: processes)
                
                List(sortedProcesses) { process in
                    NavigationLink(destination: ProcessDetailView(process: process)) {
                        VStack(alignment: .leading) {
                            Text("PID: \(process.id)").font(.headline)
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
    
    // Function to sort processes based on the selected criteria
    private func sortedProcesses(for processes: [CustomProcessInfo]) -> [CustomProcessInfo] {
        switch sortCriteria {
        case .pid:
            return processes.sorted { $0.id < $1.id }
        case .cpuUsage:
            return processes.sorted { $0.cpuUsage > $1.cpuUsage } // Sort descending by CPU usage
        case .memoryUsage:
            return processes.sorted { $0.memoryUsage > $1.memoryUsage } // Sort descending by Memory usage
        }
    }
}
