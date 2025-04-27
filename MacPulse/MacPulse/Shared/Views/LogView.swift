import SwiftUI

struct LogView: View {
    @ObservedObject private var logManager = LogManager.shared

    // UI state to select category filter
    @State private var selectedCategory: LogCategory = .errorAndDebug

    var filteredLogs: [LogEntry] {
        logManager.logs.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Log")
                .font(.largeTitle)
                .padding(.bottom, 10)

            // Category Picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(LogCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)

            if filteredLogs.isEmpty {
                Text("No logs yet.")
                    .foregroundColor(.secondary)
            } else {
                LogListView(logs: filteredLogs)
            }

            Spacer()
        }
        .padding()
    }
}

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
            // Auto-scroll to last log on new entry
            .onChange(of: logs.count) {
                if let last = logs.indices.last {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func logRow(_ log: LogEntry) -> some View {
        Text(log.formatted)
            .font(.system(size: 14, design: .monospaced))
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackgroundColor(for: log))
    }

    private func rowBackgroundColor(for log: LogEntry) -> Color {
        switch log.level {
        case .low:     return Color.red.opacity(0.1)
        case .medium:  return Color.yellow.opacity(0.1)
        case .high:    return Color.clear
        }
    }

    // Platform-specific background color
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemGroupedBackground)
        #endif
    }
}
