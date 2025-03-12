//
//  SystemMetricsViewModel.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/11/25.
//

//import SwiftUI
//import Combine
//
//class SystemMetricsViewModel: ObservableObject {
//    @Published var cpuUsage: Double = 0.0
//    @Published var memoryUsage: Double = 0.0
//    @Published var diskActivity: Double = 0.0
//    @Published var runningProcesses: [String] = [] // Placeholder for process list
//
//    private var timer: Timer?
//    
//    init() {
//        startMonitoring()
//    }
//    
//    func startMonitoring() {
//        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
//            self.updateMetrics()
//        }
//    }
//    
//    func updateMetrics() {
//        self.cpuUsage = SystemMonitor.getCPUUsage()
//        self.memoryUsage = SystemMonitor.getMemoryUsage()
//        self.diskActivity = SystemMonitor.getDiskActivity()
//        self.runningProcesses = SystemMonitor.getRunningProcesses() // Fetch process list
//    }
//}
