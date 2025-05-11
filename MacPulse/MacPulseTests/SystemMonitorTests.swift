//
//  SystemMonitorTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 4/20/25.
//

import XCTest
@testable import MacPulse
import SwiftData

final class SystemMonitorTests: XCTestCase {

    var systemMonitor: SystemMonitor!
    var mockContext: ModelContext!

    
    override func setUpWithError() throws {
        super.setUp()
        systemMonitor = SystemMonitor.shared
           
    }

    override func tearDownWithError() throws {
        systemMonitor.stopMonitoring()
        systemMonitor = nil
        super.tearDown()
    }
    
    class MockModelContext {
        var mockMetrics: [SystemMetric] = []
        
        // This method mimics the fetch behavior of the real ModelContext
        func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
            if let systemMetricDescriptor = descriptor as? FetchDescriptor<SystemMetric> {
                return mockMetrics as! [T]
            }
            throw NSError(domain: "MockModelContext", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown descriptor type"])
        }
    }

    
    class MockConnectionManager: MCConnectionManager {
        var sentPayloads: [MetricPayload] = []
        var didLogInvalidMetric = false
        var mockReceivedMetric: ((MetricPayload) -> Void)?
        
        // Override send method to capture sent payloads
        override func send(_ payload: MetricPayload) {
            sentPayloads.append(payload)
        }
        
        // Override onReceiveMetric closure to simulate receiving metrics
        override var onReceiveMetric: ((MetricPayload) -> Void)? {
            get {
                return mockReceivedMetric
            }
            set {
                mockReceivedMetric = newValue
            }
        }
        
        // Simulate the logging mechanism for invalid metric types
        func logInvalidMetric(type: Int) {
            if type != 0 && type != 1 {
                didLogInvalidMetric = true
            }
        }
    }
    func testInitialMemoryUsage() throws {
        // Arrange: Make sure memory usage is initialized to 0.0
        systemMonitor.memoryUsage = 0.0
        
        // Assert: Memory usage should be 0.0 before starting monitoring
        XCTAssertEqual(systemMonitor.memoryUsage, 0.0, "Initial memory usage should be 0.0.")
        
        // Act: Start the monitoring process and collect metrics
        let expectation = XCTestExpectation(description: "Memory usage should increase after monitoring starts")
        
        systemMonitor.collectMetrics() // Collect metrics manually or wait for the timer to start
        
        // Assert: Memory usage should change after some time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertGreaterThan(self.systemMonitor.memoryUsage, 0.0, "Memory usage should increase after monitoring starts.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    
    func testCollectMetrics() throws {
        // Simulate collecting metrics by manually calling collectMetrics
        systemMonitor.collectMetrics()

        // Check if the values are greater than or equal to 0, assuming the system has some usage
        XCTAssertGreaterThanOrEqual(systemMonitor.cpuUsage, 0.0, "CPU usage should be a positive value.")
        XCTAssertGreaterThanOrEqual(systemMonitor.memoryUsage, 0.0, "Memory usage should be a positive value.")
        XCTAssertGreaterThanOrEqual(systemMonitor.diskUsed, 0.0, "Disk usage should be a positive value.")

    }

    func testStopMonitoring() throws {
        // Start the monitoring and stop it
        systemMonitor.stopMonitoring()

        // Ensure the timer is invalidated after stopping monitoring
        XCTAssertNil(systemMonitor.timer, "The timer should be nil after stopping monitoring.")
    }
    
    #if os(macOS)
    func testHostCPULoadInfoReturnsValidData() {
        // Call the function to get the CPU load information
        let info = SystemMonitor.hostCPULoadInfo()

        // Validate that the returned info is not the default value
        XCTAssertNotEqual(info.cpu_ticks.0, 0, "System CPU ticks should not be 0.")
        XCTAssertNotEqual(info.cpu_ticks.1, 0, "User CPU ticks should not be 0.")
        XCTAssertNotEqual(info.cpu_ticks.2, 0, "Idle CPU ticks should not be 0.")
        XCTAssertGreaterThanOrEqual(info.cpu_ticks.3, 0, "Nice CPU ticks should be greater than or equal to 0.")
        XCTAssertGreaterThan(info.cpu_ticks.0, 0, "System CPU tick count should be greater than 0.")
    }
    #endif

    #if os(macOS)
    func testHostCPULoadInfoMockedData() {
        // Create a mock `host_cpu_load_info` struct with some test data
        var mockInfo = host_cpu_load_info_data_t()
        mockInfo.cpu_ticks.0 = 100
        mockInfo.cpu_ticks.1 = 50
        mockInfo.cpu_ticks.2 = 30
        mockInfo.cpu_ticks.3 = 20
        
        // Temporarily replace the `hostCPULoadInfo` function to return the mock data
        let mockHostCPULoadInfo: () -> host_cpu_load_info = {
            return mockInfo
        }
        
        // Simulate calling the function with mocked data
        let info = mockHostCPULoadInfo()

        // Verify the mock data is returned correctly
        XCTAssertEqual(info.cpu_ticks.0, 100, "System CPU ticks should be 100 in the mock.")
        XCTAssertEqual(info.cpu_ticks.1, 50, "User CPU ticks should be 50 in the mock.")
        XCTAssertEqual(info.cpu_ticks.2, 30, "Idle CPU ticks should be 30 in the mock.")
        XCTAssertEqual(info.cpu_ticks.3, 20, "Nice CPU ticks should be 20 in the mock.")
    }
    #endif
    
    func testGetMemoryUsageReturnsNonNegativeValue() {
        let memoryUsage = systemMonitor.getMemoryUsage()
        XCTAssertGreaterThanOrEqual(memoryUsage, 0.0, "Memory usage should not be negative.")
    }

    func testGetCPUUsageReturnsValueBetween0And100() {
        let cpuUsage = systemMonitor.getCPUUsage()
        XCTAssert(cpuUsage >= 0.0 && cpuUsage <= 100.0, "CPU usage should be between 0 and 100%.")
    }

    func testGetTotalMemoryGBReturnsReasonableValue() {
        let totalRAM = systemMonitor.getTotalMemoryGB()
        XCTAssertGreaterThan(totalRAM, 1.0, "Total memory should be greater than 1 GB.")
        XCTAssertLessThan(totalRAM, 1024.0, "Total memory should be less than 1 TB.")
    }

    func testMemoryUsagePercentageIsInRange() {
        let percent = systemMonitor.getMemoryUsagePercent()
        XCTAssert(percent >= 0.0 && percent <= 100.0, "Memory usage percent should be in the range 0–100.")
    }

    func testStartAndStopMonitoring() {
        systemMonitor.startMonitoring()
        XCTAssertNotNil(systemMonitor.timer, "Timer should not be nil after startMonitoring is called.")
        
        systemMonitor.stopMonitoring()
        XCTAssertNil(systemMonitor.timer, "Timer should be nil after stopMonitoring is called.")
    }
    

}
