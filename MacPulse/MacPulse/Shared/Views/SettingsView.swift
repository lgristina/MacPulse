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
    
    // Notification thresholds (in %)
    @AppStorage("cpuThreshold")    private var cpuThreshold: Double    = 80
    @AppStorage("memoryThreshold") private var memoryThreshold: Double = 80
    @AppStorage("diskThreshold")   private var diskThreshold: Double   = 90

    // Accessibility options
    @AppStorage("invertColors") private var invertColors: Bool = false

    var body: some View {
        #if os(macOS)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)   // allow Form to fill & scroll
        .navigationTitle("Settings")
        .colorInvertIfNeeded(invertColors)
        .frame(minWidth: 400)                                // keep your macOS min-width only there
        .padding()                                           // and macOS padding

        #else
        // iOS-only layout
        ScrollView {
            VStack(spacing: 32) {
                // Notifications Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notifications")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ThresholdSlider(label: "CPU",    value: $cpuThreshold)
                    ThresholdSlider(label: "Memory", value: $memoryThreshold)
                    ThresholdSlider(label: "Disk",   value: $diskThreshold)
                }

                // Accessibility Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Accessibility")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Toggle("Invert Colors", isOn: $invertColors)
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
        .background(Color(UIColor.systemGroupedBackground))
        .colorInvertIfNeeded(invertColors)
        #endif
    }
}

// MARK: - Reusable slider row for iOS
private struct ThresholdSlider: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(label) Alert ≥ \(Int(value))%")
            Slider(value: $value, in: 0...100, step: 1)
        }
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
