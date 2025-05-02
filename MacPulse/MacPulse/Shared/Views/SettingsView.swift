//
//  SettingsView.swift
//  MacPulse
//
//  Created by Luca Gristina on 4/30/25.
//

import SwiftUI

struct SettingsView: View {
    // —— Notification thresholds (in %)
    @AppStorage("cpuThreshold")    private var cpuThreshold: Double    = 80
    @AppStorage("memoryThreshold") private var memoryThreshold: Double = 80
    @AppStorage("diskThreshold")   private var diskThreshold: Double   = 90

    // —— Accessibility
    @AppStorage("invertColors") private var invertColors: Bool = false
    @AppStorage("fontSize")     private var fontSize: Double  = 14

    var body: some View {
        Form {
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

            Section(header:
                Text("Accessibility")
                    .font(.largeTitle)
                    .padding(.bottom, 10)
            ) {
                Toggle("Invert Colors", isOn: $invertColors)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Base Font Size: \(Int(fontSize)) pt")
                    Slider(value: $fontSize, in: 10...24, step: 1)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(minWidth: 400)
        .padding()
        // Conditionally invert all colors
        .colorInvertIfNeeded(invertColors)
        .navigationTitle("Settings")
    }
}

private extension View {
    /// Only applies colorInvert() when the toggle is on
    @ViewBuilder
    func colorInvertIfNeeded(_ invert: Bool) -> some View {
        if invert { self.colorInvert() }
        else     { self }
    }
}
