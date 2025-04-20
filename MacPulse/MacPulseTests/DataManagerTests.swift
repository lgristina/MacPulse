//
//  DataManagerTests.swift
//  MacPulse
//
//  Created by Marguerite McGahay on 4/19/25.
//


import SwiftData
import XCTest
@testable import MacPulse

final class DataManagerTests: XCTestCase {
    
    var dataManager: DataManager!
    var context: ModelContext!

    func testSaveSystemMetrics() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SystemMetric.self,
                 CustomProcessInfo.self,
            configurations: config
        )
        let context = await container.mainContext
        let manager = await DataManager(testingContext: context)

        let before = try context.fetch(FetchDescriptor<SystemMetric>()).count
        await manager.saveSystemMetrics(cpu: 23.4, memory: 45.2, disk: 5.0)
        let after = try context.fetch(FetchDescriptor<SystemMetric>()).count

        XCTAssertEqual(after, before + 1)
    }

    func testPruneOldSystemMetrics() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: SystemMetric.self,
                 CustomProcessInfo.self,
            configurations: config
        )
        let context = await container.mainContext
        let manager = await DataManager(testingContext: context)

        let oldDate = Calendar.current.date(byAdding: .minute, value: -20, to: Date())!
        let recent = SystemMetric(timestamp: Date(), cpuUsage: 1, memoryUsage: 1, diskActivity: 1)
        let old    = SystemMetric(timestamp: oldDate, cpuUsage: 2, memoryUsage: 2, diskActivity: 2)

        context.insert(recent)
        context.insert(old)
        try context.save()

        await manager.pruneOldSystemMetrics()
        let remaining = try context.fetch(FetchDescriptor<SystemMetric>())

        XCTAssertTrue(remaining.allSatisfy { $0.timestamp >= Calendar.current.date(byAdding: .minute, value: -10, to: Date())! })
    }
    
}

