//
//  MacPulseTests.swift
//  MacPulseTests
//
//  Created by Luca Gristina on 3/10/25.
//

import Testing
@testable import MacPulse
import SwiftData

struct MacPulseTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testModelContainerInitializes() throws {
            let schema = Schema([SystemMetric.self, CustomProcessInfo.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true) // use memory only for testing
            
            let container = try ModelContainer(for: schema, configurations: [config])
            
            #expect(container != nil)
        }

}
