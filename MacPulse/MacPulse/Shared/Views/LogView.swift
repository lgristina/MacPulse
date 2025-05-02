import SwiftUI

// MARK: - LogView

/// A SwiftUI view that displays logs managed by `LogManager`.
/// Users can filter logs by category using a segmented picker and view real-time updates.
struct LogView: View {
    /// Observes the shared singleton instance of `LogManager`.
    @ObservedObject private var logManager = LogManager.shared

    /// The currently selected category to filter the logs displayed.
    @State private var selectedCategory: LogCategory = .errorAndDebug

    /// Computed property to filter logs by the selected category.
    var filteredLogs: [LogEntry] {
        logManager.logs.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(alignment: .leading) {
            // View Title
            Text("Log")
                .font(.largeTitle)
                .padding(.bottom, 10)

            // Picker for selecting the log category
            Picker("Category", selection: $selectedCategory) {
                ForEach(LogCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)

            // Log content or fallback if empty
            Spacer()

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

// MARK: - LogListView

/// Displays a scrollable and auto-updating list of log entries.
/// Applies styling and highlights based on log level.
struct LogListView: View {
    /// The list of logs to be displayed.
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
            // Automatically scroll to the latest entry when a new log appears
            .onChange(of: logs.count) {
                if let last = logs.indices.last {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    /// Builds a single row of the log with appropriate font and background color.
    @ViewBuilder
    private func logRow(_ log: LogEntry) -> some View {
        Text(log.formatted)
            .font(.system(size: 14, design: .monospaced))
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackgroundColor(for: log))
    }

    /// Determines the background color based on the log’s verbosity level.
    private func rowBackgroundColor(for log: LogEntry) -> Color {
        switch log.level {
        case .low:
            return Color.red.opacity(0.1)       // For errors
        case .medium:
            return Color.yellow.opacity(0.1)    // For warnings/info
        case .high:
            return Color.clear                  // For verbose/debug
        }
    }

    /// Provides platform-specific background color for the log container.
    private var backgroundColor: Color {
#if os(macOS)
        return Color(NSColor.windowBackgroundColor)
#else
        return Color(.systemGroupedBackground)
#endif
    }
}
