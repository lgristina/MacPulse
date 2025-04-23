import SwiftUI

struct ProcessListView: View {
    #if os(macOS)
    @ObservedObject private var viewModel = ProcessMonitor.shared
    #endif
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared

    
    
    var body: some View {
        NavigationView {
            #if os(macOS)
            let processes = viewModel.runningProcesses
            #else
            let processes = systemMonitor.remoteProcesses
            #endif
            List(processes) { process in
                NavigationLink(destination: ProcessDetailView(process: process)) {
                    VStack(alignment: .leading) {
                        #if os(macOS)
                        Text("PID: \(process.id)").font(.title2)
                        #else
                        Text("PID: \(process.id)").font(.headline)
                        #endif
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
                #if os(iOS)
                if let manager = RemoteSystemMonitor.shared.connectionManager {
                    manager.send(.stopSending(typeToStop: 0))
                    print("REQUESTING PROCESS METRICS!")
                    manager.send(.sendProcessMetrics)
                } else {
                    print("⚠️ Connection manager not set on RemoteSystemMonitor.shared")
                }
                #endif
            }
        }
    }
}
