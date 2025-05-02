//
//  SettingsView.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/30/25.
//

import SwiftUI

// MARK: - Settings View

/// View allowing users to customize alert thresholds and accessibility preferences
struct SettingsView: View {
    // —— Notification thresholds (in %)
    @AppStorage("cpuThreshold")    private var cpuThreshold: Double    = 80
    @AppStorage("memoryThreshold") private var memoryThreshold: Double = 80
    @AppStorage("diskThreshold")   private var diskThreshold: Double   = 90

    // —— Accessibility
    @AppStorage("invertColors") private var invertColors: Bool = false

    var body: some View {
        Form {
            // Notification settings section
            Section(header:
                Text("Notifications")
                    .font(.largeTitle)
                    .padding(.bottom, 10)
            ) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Alert when CPU ≥ \(Int(cpuThreshold))%")
                    Slider(value: $cpuThreshold, in: 0...100, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Alert when Memory ≥ \(Int(memoryThreshold))%")
                    Slider(value: $memoryThreshold, in: 0...100, step: 1)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Alert when Disk ≥ \(Int(diskThreshold))%")
                    Slider(value: $diskThreshold, in: 0...100, step: 1)
                }
                .padding(.vertical, 4)
            }

            // Accessibility preferences section
            Section(header:
                Text("Accessibility")
                    .font(.largeTitle)
                    .padding(.bottom, 10)
            ) {
                Toggle("Invert Colors", isOn: $invertColors)
            }
        }
        .frame(minWidth: 400)
        .padding()
        .colorInvertIfNeeded(invertColors) // Conditionally invert colors if setting is enabled
        .navigationTitle("Settings")
    }
}

// MARK: - Conditional Color Inversion

/// Applies colorInvert() only if the invertColors toggle is true
private extension View {
    @ViewBuilder
    func colorInvertIfNeeded(_ invert: Bool) -> some View {
        if invert {
            self.colorInvert()
        } else {
            self
        }
    }
}
