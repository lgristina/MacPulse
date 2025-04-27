//
//  LogManager.swift
//  MacPulse
//
//  Created by Austin Frank on 3/27/25.
//

import Foundation
import OSLog
import Combine

class LogManager: ObservableObject {
    static let shared = LogManager()
    
    private let logger = Logger(subsystem: "com.yourcompany.MacPulse", category: "General")
    
    @Published private(set) var logs: [String] = []
    
    private init() {}
    
    func logInfo(_ message: String) {
        logger.info("\(message, privacy: .public)")
        addToLog("[INFO] \(message)")
    }
    
    func logError(_ message: String) {
        logger.error("\(message, privacy: .public)")
        addToLog("[ERROR] \(message)")
    }
    
    func logWarning(_ message: String, category: String = "General") {
        logger.warning("\(message, privacy: .public)")
    }
    
    private func addToLog(_ entry: String) {
        DispatchQueue.main.async {
            self.logs.append(entry)
        }
    }
}



