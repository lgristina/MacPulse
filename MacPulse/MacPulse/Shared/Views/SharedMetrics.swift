//
//  SharedMetrics.swift
//  MacPulse
//
//  Created by Austin Frank on 4/17/25.
//

import Charts
import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformColor = NSColor
#endif

extension Color {
    /// Matches the system’s background color on both iOS and macOS
    static var cardBackground: Color {
        #if os(iOS)
        Color(PlatformColor.systemBackground)
        #elseif os(macOS)
        Color(PlatformColor.windowBackgroundColor)
        #endif
    }
}

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
        .background(
            RoundedRectangle(cornerRadius: 0.5).fill(Color.gray.opacity(0.2)))
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
