//
//  ProcessDetailView.swift
//  MacPulse
//
//  Created by Austin Frank on 3/12/25.
//

import SwiftUI

struct ProcessDetailView: View {
    let process: CustomProcessInfo  // Updated to use CustomProcessInfo
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Process Details")
                .font(.largeTitle)
                .bold()
            
            HStack {
                Text("Process ID:")
                    .font(.headline)
                Spacer()
                Text("\(process.id)")
            }
            
            HStack {
                Text("CPU Usage:")
                    .font(.headline)
                Spacer()
                Text("\(process.cpuUsage, specifier: "%.2f")%")
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Memory Usage:")
                    .font(.headline)
                Spacer()
                Text("\(process.memoryUsage, specifier: "%.2f") MB")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Process \(process.id)")
    }
}

