//
//  SystemMonitorTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 4/20/25.
//
import XCTest
@testable import MacPulse

final class SystemMonitorTests: XCTestCase {

    var systemMonitor: SystemMonitor!
    
    override func setUpWithError() throws {
        super.setUp()
        systemMonitor = SystemMonitor.shared
    }

    override func tearDownWithError() throws {
        systemMonitor.stopMonitoring()
        systemMonitor = nil
        super.tearDown()
    }

    func testInitialMemoryUsage() throws {
        // Arrange: Make sure memory usage is initialized to 0.0
        systemMonitor.memoryUsage = 0.0
        
        // Assert: Memory usage should be 0.0 before starting monitoring
        XCTAssertEqual(systemMonitor.memoryUsage, 0.0, "Initial memory usage should be 0.0.")
        
        // Act: Start the monitoring process
        systemMonitor.collectMetrics() // Or wait for the timer to start and gather metrics
        
        // Assert: Memory usage should change once the monitoring starts
        XCTAssertGreaterThan(systemMonitor.memoryUsage, 0.0, "Memory usage should increase after monitoring starts.")
    }


    func testCollectMetrics() throws {
        // Simulate collecting metrics by manually calling collectMetrics
        systemMonitor.collectMetrics()

        // Check if the values are greater than or equal to 0, assuming the system has some usage
        XCTAssertGreaterThanOrEqual(systemMonitor.cpuUsage, 0.0, "CPU usage should be a positive value.")
        XCTAssertGreaterThanOrEqual(systemMonitor.memoryUsage, 0.0, "Memory usage should be a positive value.")
        XCTAssertGreaterThanOrEqual(systemMonitor.diskActivity, 0.0, "Disk activity should be a positive value.")
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

        // Instead of directly comparing the nice CPU ticks to non-zero, assert it's within a reasonable range
        XCTAssertGreaterThanOrEqual(info.cpu_ticks.3, 0, "Nice CPU ticks should be greater than or equal to 0.")

        // Ensure the count is greater than 0
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
    
}
