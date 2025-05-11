//
//  LogView.swift
//  MacPulse
//
//  Created by [Your Name] on [Date].
//

import SwiftUI

// MARK: - Main Log View

/// Displays application logs filtered by category (e.g., Error, Debug, Sync).
/// Allows users to inspect real-time logs with severity highlighting and category filtering.
struct LogView: View {
    /// Shared log manager instance to observe log updates.
    @ObservedObject private var logManager = LogManager.shared

    /// Selected category filter (default: error and debug logs).
    @State private var selectedCategory: LogCategory = .errorAndDebug

    /// Computed property that returns only the logs matching the selected category.
    var filteredLogs: [LogEntry] {
        logManager.logs.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: - Header
            Text("Log")
                .font(.largeTitle)
                .padding(.bottom, 10)

            // MARK: - Category Picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(LogCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                        .accessibilityIdentifier("\(category.rawValue)Segment")
                        .accessibilityAddTraits(
                            selectedCategory == category ? .isSelected : []
                              )
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)

            Spacer()

            // MARK: - Log Output
            if filteredLogs.isEmpty {
                Text("No logs yet.")
                    .foregroundColor(.secondary)
            } else {
                LogListView(logs: filteredLogs)
                    .frame(maxHeight: .infinity)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Log List View

/// Renders a scrollable list of log entries with severity-based styling.
struct LogListView: View {
    let logs: [LogEntry]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(logs) { log in
                        logRow(log)
                            .id(log.id)
                    }
                }
                .padding()
            }
            .background(backgroundColor)
            .cornerRadius(10)
            // Scrolls to the bottom automatically when a new log is added.
            .onChange(of: logs.count) {
                if let last = logs.indices.last {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Individual Log Row

    /// Renders a single log entry using monospaced font and background color based on severity.
    @ViewBuilder
    private func logRow(_ log: LogEntry) -> some View {
        Text(log.formatted)
            .font(.system(size: 14, design: .monospaced))
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackgroundColor(for: log))
    }

    /// Highlights row background color based on log severity level.
    private func rowBackgroundColor(for log: LogEntry) -> Color {
        switch log.level {
        case .low:     return Color.red.opacity(0.1)
        case .medium:  return Color.yellow.opacity(0.1)
        case .high:    return Color.clear
        }
    }

    /// Sets platform-specific background color for the entire log list.
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemGroupedBackground)
        #endif
    }
}
