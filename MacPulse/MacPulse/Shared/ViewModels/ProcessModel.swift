//
//  ProcessModel.swift
//  MacPulse
//
//  Created by Austin Frank on 3/12/25.
//

import Foundation
import SwiftUI

class ProcessModel: ObservableObject {
    @Published var runningProcesses: [ProcessInfo] = []
    init() {
        fetchRunningProcesses()
    }
    func fetchRunningProcesses() {
        DispatchQueue.global(qos: .background).async {
            let processes = ProcessMonitor.shared.getRunningProcesses()
            DispatchQueue.main.async {
                self.runningProcesses = processes
            }
        }
    }
}
