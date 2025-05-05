//
//  DiskDetailView.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/29/25.
//

import SwiftUI
import Charts

// MARK: - Disk Detailed View

struct DiskDetailedView: View {
    @ObservedObject private var monitor = SystemMonitor.shared

    private var slices: [DiskSlice] {
        [
            DiskSlice(name: "Used", value: monitor.diskUsed),
            DiskSlice(name: "Free", value: monitor.diskFree)
        ]
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Disk Usage Breakdown")
                .font(.title2).bold()

            Chart {
                ForEach(slices) { slice in
                    SectorMark(
                        angle: .value("GB", slice.value),
                        innerRadius: .ratio(0.5),
                        outerRadius: .ratio(1.0)
                    )
                    .foregroundStyle(by: .value("Category", slice.name))
                    .annotation(position: .overlay) {
                        Text(slice.name)
                            .font(.caption2)
                    }
                }
            }
            .chartLegend(.visible)
            .frame(height: 280)
            .padding(.horizontal)

            HStack {
                Text("Used: \(String(format: "%.2f", monitor.diskUsed)) GB")
                Spacer()
                Text("Free: \(String(format: "%.2f", monitor.diskFree)) GB")
            }
            .font(.title2)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
        .padding(.top)
    }
}

private struct DiskSlice: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
}
