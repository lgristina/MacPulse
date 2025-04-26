//
//  SharedMetrics.swift
//  MacPulse
//
//  Created by Austin Frank on 4/17/25.
//

import SwiftUI
import Charts

// MARK: - Shared Protocol
protocol UsageData: Identifiable {
    var time: Date { get }
    var value: Double { get }
}

// MARK: - CPU & Memory Structs
struct CPUUsageData: UsageData {
    let id = UUID()
    let usage: Double
    let time: Date
    var value: Double { usage }
}

struct MemoryUsageData: UsageData {
    let id = UUID()
    let usage: Double
    let time: Date
    var value: Double { usage }
}

// MARK: - Metric Panel
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
        .background(RoundedRectangle(cornerRadius: 0.5).fill(Color.gray.opacity(0.2)))
    }
}

// MARK: - Detailed Usage View
struct DetailedUsageView<Data: UsageData>: View {
    let title: String
    let unit: String
    let lineColor: Color
    let currentUsage: Double
    let usagePublisher: Published<Double>.Publisher
    let makeData: (Double, Date) -> Data

    @State private var usageHistory: [Data] = []

    var body: some View {
        VStack {
            Text("\(title) Detailed View")
                .font(.largeTitle)
                .padding(.bottom, 20)

            Chart(usageHistory) {
                LineMark(
                    x: .value("Time", $0.time),
                    y: .value(title, $0.value)
                )
                .foregroundStyle(lineColor)
            }
            .frame(height: 200)
            .padding()

            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(usageHistory.reversed(), id: \.id) { data in
                        HStack {
                            Text("\(data.time, formatter: timeFormatter)")
                            Spacer()
                            Text("\(data.value, specifier: "%.1f") \(unit)")
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .onAppear {
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
        if usageHistory.count > 50 {
            usageHistory.removeFirst()
        }
    }
}

// MARK: - Time Formatter
let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    return formatter
}()
