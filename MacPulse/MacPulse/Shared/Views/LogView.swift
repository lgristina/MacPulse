import SwiftUI

struct LogView: View {
    @ObservedObject private var logManager = LogManager.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Log View")
                .font(.largeTitle)
                .padding(.bottom, 10)

            if logManager.logs.isEmpty {
                Text("No logs yet.")
                    .foregroundColor(.secondary)
            } else {
                LogListView(logs: logManager.logs)
            }

            Spacer()
        }
        .padding()
    }
}

struct LogListView: View {
    let logs: [String]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(logs.indices, id: \.self) { index in
                    logRow(logs[index], index: index)
                }
            }
            .padding()
        }
        .background(backgroundColor)
        .cornerRadius(10)
    }

    @ViewBuilder
    private func logRow(_ log: String, index: Int) -> some View {
        Text(log)
            .font(.system(size: 14, design: .monospaced))
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(index.isMultiple(of: 2) ? rowBackgroundColor : Color.clear)
    }

    // Platform-specific background color
    private var backgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color(.systemGroupedBackground)
        #endif
    }

    private var rowBackgroundColor: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #else
        return Color(.systemGray6)
        #endif
    }
}
