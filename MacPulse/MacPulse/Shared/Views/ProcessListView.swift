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
    @Binding var selectedProcessID: Int?
    @ObservedObject private var viewModel = ProcessMonitor.shared
    #else
    @ObservedObject var systemMonitor = RemoteSystemMonitor.shared
    @State private var selectedProcessID: Int? = nil
    #endif
    
    @State private var hasInitialized = false
    @State private var showingProcessDetail = false
    @State private var currentProcessID: Int? = nil

    /// Sorting options for the process list.
    enum SortCriteria {
        case shortProcessName, cpuUsage, memoryUsage
    }

    @State private var sortCriteria: SortCriteria = .shortProcessName

    var body: some View {
        VStack(spacing: 0) {
            // Sorting Dropdown Menu
            Menu {
                Button("Sort by Process Name") { sortCriteria = .shortProcessName }
                Button("Sort by CPU Usage") { sortCriteria = .cpuUsage }
                Button("Sort by Memory Usage") { sortCriteria = .memoryUsage }
            } label: {
                Label("Sort by", systemImage: "arrow.up.arrow.down.circle")
                    .font(.title2)
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("SortByMenu")
            #if os(macOS)
            .background(Color(nsColor: .windowBackgroundColor)) // macOS background
            #else
            .background(Color(uiColor: .systemBackground)) // iOS background
            #endif
            
            // Select correct source of processes depending on platform
            #if os(macOS)
            let processes = viewModel.runningProcesses
            #else
            let processes = systemMonitor.runningProcesses
            #endif

            // Display sorted list
            let sortedProcesses = sortedProcesses(for: processes)

            List(sortedProcesses) { process in
                #if os(macOS)
                Button {
                    currentProcessID = process.id
                    showingProcessDetail = true
                } label: {
                    processRowContent(for: process)
                }
                .buttonStyle(.plain)
                #else
                NavigationLink(value: process.id) {
                    processRowContent(for: process)
                }
                #endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1) // Prioritize List height over Menu
            .navigationTitle("Running Processes")
            .accessibilityIdentifier("ProcessList")
            #if os(iOS)
            .ignoresSafeArea(.container, edges: .bottom) // Maximize height on iOS
            .navigationDestination(for: Int.self) { processID in
                ProcessDetailView(processID: processID)
            }
            #endif
            #if os(macOS)
            .sheet(isPresented: $showingProcessDetail) {
                if let id = currentProcessID {
                    ProcessDetailView(processID: id)
                }
            }
            #endif
            .onAppear {
                if !hasInitialized {
                    hasInitialized = true
                    #if os(iOS)
                    if let manager = RemoteSystemMonitor.shared.connectionManager {
                        manager.send(.stopSending(typeToStop: 0)) // Stop previous data stream
                        manager.send(.sendProcessMetrics) // Request new metrics
                    } else {
                        LogManager.shared.log(.errorAndDebug, level: LogVerbosityLevel.high, "⚠️ Connection manager not set on RemoteSystemMonitor.shared")
                    }
                    #endif
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Extracted common row content
    @ViewBuilder
    private func processRowContent(for process: CustomProcessInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Process: \(process.shortProcessName)")
                .font(.headline)
            Text("CPU Usage: \(process.cpuUsage, specifier: "%.1f")%")
                .foregroundColor(.blue)
                .font(.subheadline)
            Text("Memory Usage: \(process.memoryUsage, specifier: "%.1f") MB")
                .foregroundColor(.green)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
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
