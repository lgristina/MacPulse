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
    @AppStorage("invertColors")    private var invertColors: Bool     = false

    var body: some View {
        #if os(macOS)
        // — macOS: native Form with empty‐row padding disabled
        Form {
            Section(header:
                Text("Notification")
                    .font(.largeTitle)
                    .padding(.bottom, 8)
            ) {
                ThresholdSlider(label: "CPU",    value: $cpuThreshold)
                ThresholdSlider(label: "Memory", value: $memoryThreshold)
                ThresholdSlider(label: "Disk",   value: $diskThreshold)
            }

            Section(header:
                Text("Accessibility")
                    .font(.largeTitle)
                    .padding(.bottom, 8)
            ) {
                Toggle("Invert Colors", isOn: $invertColors)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollDisabled(true)                     // stop the Form from padding out empty rows
        .navigationTitle("Settings")
        .colorInvertIfNeeded(invertColors)
        .frame(minWidth: 400)
        .padding()

        #else
        // — iOS: simple VStack so everything always fits
        VStack(alignment: .leading, spacing: 32) {
            // 1) Notification sliders (static, not scrollable)
            VStack(alignment: .leading, spacing: 16) {
                Text("Notifications")
                    .font(.title2)

                ThresholdSlider(label: "CPU",    value: $cpuThreshold)
                ThresholdSlider(label: "Memory", value: $memoryThreshold)
                ThresholdSlider(label: "Disk",   value: $diskThreshold)
            }
            .padding(.horizontal)

            // 2) Accessibility toggle (always visible)
            VStack(alignment: .leading, spacing: 16) {
                Text("Accessibility")
                    .font(.title2)

                Toggle("Invert Colors", isOn: $invertColors)
            }
            .padding(.horizontal)

            Spacer()   // pushes content up so there’s no bottom gap
        }
        .padding(.top)
        .navigationTitle("Settings")
        .background(Color(UIColor.systemGroupedBackground))
        .colorInvertIfNeeded(invertColors)
        #endif
    }
}


/// A reusable slider + label row
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


/// Conditionally invert colors across the entire view hierarchy
private extension View {
    @ViewBuilder
    func colorInvertIfNeeded(_ invert: Bool) -> some View {
        if invert { colorInvert() }
        else      { self }
    }
}
