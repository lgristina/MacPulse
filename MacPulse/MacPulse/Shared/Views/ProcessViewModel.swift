//
//  ProcessViewModel.swift
//  MacPulse
//
//  Created by Austin Frank on 3/12/25.
//

import Foundation

class ProcessViewModel: ObservableObject {
    @Published var runningProcesses: [ProcessInfo] = []
    
    func fetchProcesses() {
        let fetchedProcesses = ProcessMonitor.shared.getRunningProcesses()
        DispatchQueue.main.async {
            self.runningProcesses = fetchedProcesses
        }
    }
}
