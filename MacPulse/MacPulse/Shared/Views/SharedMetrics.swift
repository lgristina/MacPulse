import Charts
import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformColor = NSColor
#endif

// MARK: - Color Extension
extension Color {
    /// Matches the system’s background color on both iOS and macOS.
    static var cardBackground: Color {
        #if os(iOS)
        Color(PlatformColor.systemBackground)
        #elseif os(macOS)
        Color(PlatformColor.windowBackgroundColor)
        #endif
    }
}

// MARK: - Shared Protocol for Usage Data
protocol UsageData: Identifiable {
    var time: Date { get }
    var value: Double { get }
}

// MARK: - CPU & Memory Structs
/// Struct for storing CPU usage data.
struct CPUUsageData: UsageData {
    let id = UUID()
    let usage: Double
    let time: Date
    var value: Double { usage }
}

/// Struct for storing Memory usage data.
struct MemoryUsageData: UsageData {
    let id = UUID()
    let usage: Double
    let time: Date
    var value: Double { usage }
}

// MARK: - Metric Panel View
/// A panel to display a single metric with a title, value, and unit.
struct MetricPanel: View {
    let title: String
    let value: Double
    let unit: String

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text("\(value, specifier: "%.1f")\(unit)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)
        }
        .frame(width: 150, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 0.5).fill(Color.gray.opacity(0.2)))
    }
}

// MARK: - Detailed Usage View
/// A view that shows detailed usage data over time in a line chart.
struct DetailedUsageView<Data: UsageData>: View {
    let title: String
    let unit: String
    let lineColor: Color
    let currentUsage: Double
    let usagePublisher: Published<Double>.Publisher
    let makeData: (Double, Date) -> Data
    
    @Environment(\.modelContext) private var context

    @State private var usageHistory: [Data] = []

    init(
        title: String,
        unit: String,
        lineColor: Color,
        currentUsage: Double,
        usagePublisher: Published<Double>.Publisher,
        makeData: @escaping (Double, Date) -> Data
    ) {
        self.title = title
        self.unit = unit
        self.lineColor = lineColor
        self.currentUsage = currentUsage
        self.usagePublisher = usagePublisher
        self.makeData = makeData
    }

    var body: some View {
        VStack {
            Text("\(title) Detailed View")
                .font(.largeTitle)
                .padding(.bottom, 20)

            // Line chart to display historical usage data
            Chart(usageHistory) {
                LineMark(
                    x: .value("Time", $0.time),
                    y: .value(title, $0.value)
                )
                .foregroundStyle(lineColor)
            }
            .frame(height: 200)
            .padding()

            // Scrollable list showing the historical data points
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(usageHistory.reversed(), id: \.id) { data in
                        HStack {
                            Text(data.time, formatter: timeFormatter)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f %@", data.value, unit))
                                .font(.headline)
                                .foregroundColor(lineColor)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.cardBackground)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(lineColor.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .onAppear {
            if Data.self == CPUUsageData.self {
                // Reload from Core Data every time the view appears
                SystemMonitor.shared.loadCPUHistory(from: context)

                // Rebind state to fresh Core Data results
                usageHistory = SystemMonitor.shared.cpuUsageHistory as! [Data]
            }

            // Add the current value to live-update graph
            usageHistory.append(makeData(currentUsage, Date()))
        }
        .onReceive(usagePublisher) { newUsage in
            addUsage(newUsage)
        }
        .padding()
    }

    private func addUsage(_ usage: Double) {
        let newData = makeData(usage, Date())
        usageHistory.append(newData)
        if usageHistory.count > 50 { // Keep the history limited
            usageHistory.removeFirst()
        }
    }
}

// MARK: - Time Formatter
/// A DateFormatter to format time for displaying in usage history.
let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()
