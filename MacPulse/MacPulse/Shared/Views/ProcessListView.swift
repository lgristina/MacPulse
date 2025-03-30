import SwiftUI

struct ProcessListView: View {
    @StateObject private var viewModel = ProcessMonitor()
    
    var body: some View {
        NavigationView {
            List(viewModel.runningProcesses) { process in
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
                viewModel.startMonitoring()
            }
        }
    }
}
