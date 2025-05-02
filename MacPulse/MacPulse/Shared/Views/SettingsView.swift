//
//  SettingsView.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/30/25.
//

import SwiftUI

// MARK: - Settings View

/// Provides sliders and toggles for adjusting system alert thresholds and accessibility settings.
struct SettingsView: View {
    
    // MARK: - Stored Properties

    // Notification thresholds (in %)
    @AppStorage("cpuThreshold")    private var cpuThreshold: Double    = 80
    @AppStorage("memoryThreshold") private var memoryThreshold: Double = 80
    @AppStorage("diskThreshold")   private var diskThreshold: Double   = 90

    // Accessibility options
    @AppStorage("invertColors") private var invertColors: Bool = false

    // MARK: - View Body

    var body: some View {
        Form {
            // MARK: Notification Settings
            Section(header:
                Text("Notification")
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

            // MARK: Accessibility Settings
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
        .navigationTitle("Settings")
        .colorInvertIfNeeded(invertColors)
    }
}

// MARK: - View Extension

private extension View {
    /// Conditionally applies `.colorInvert()` if accessibility toggle is enabled.
    @ViewBuilder
    func colorInvertIfNeeded(_ invert: Bool) -> some View {
        if invert { self.colorInvert() }
        else      { self }
    }
}
