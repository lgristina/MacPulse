//
//  Persistence.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 3/14/25.
//

import SwiftData

struct EncryptedContainer {
    static let shared = EncryptedContainer()
    
    let container: ModelContainer
    
    init() {
        do {
            self.container = try ModelContainer(for: SystemMetric.self)

        } catch {
            fatalError("Failed to initialize the database: \(error)")
        }
    }
}
