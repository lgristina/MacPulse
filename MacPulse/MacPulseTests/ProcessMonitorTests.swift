//
//  ProcessMonitorTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 4/20/25.
//
import XCTest
@testable import MacPulse

final class ProcessMonitorTests: XCTestCase {

    var processMonitor: ProcessMonitor!
    
    override func setUpWithError() throws {
        super.setUp()
        processMonitor = ProcessMonitor.shared
    }

    override func tearDownWithError() throws {
        processMonitor.stopMonitoring()
        processMonitor = nil
        super.tearDown()
    }
    
    class MockProcessMonitor: ProcessMonitor {
        var mockProcesses: [CustomProcessInfo] = []
        
        override func getRunningProcesses() -> [CustomProcessInfo] {
            return mockProcesses
        }
    }
    
    

    func testStartMonitoring() {
        // Before starting the monitoring, check initial process count
        let initialProcessCount = processMonitor.runningProcesses.count

        // Start monitoring
        processMonitor.startMonitoring()
        
        // Wait for a short time (give the timer a chance to update)
        let expectation = XCTestExpectation(description: "Waiting for processes to be collected")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        // Check if running processes have increased
        let updatedProcessCount = self.processMonitor.runningProcesses.count
        XCTAssertGreaterThanOrEqual(updatedProcessCount, initialProcessCount, "The running processes should have increased after monitoring started.")
        
        expectation.fulfill()
        }

        // Wait for the expectation to fulfill (up to 10 seconds)
        wait(for: [expectation], timeout: 10)
    }


    
    
    func testStopMonitoring() throws {
        processMonitor.startMonitoring()
        
        // Ensure that monitoring stops when stopMonitoring is called
        processMonitor.stopMonitoring()
        
        // The timer should be invalidated
        XCTAssertNil(processMonitor.timer, "The timer should be nil after stopping monitoring.")
    }


    func testGetRunningProcesses() throws {
        let processes = processMonitor.getRunningProcesses()
        
        XCTAssertGreaterThan(processes.count, 0, "There should be at least one process fetched.")
        
        if let firstProcess = processes.first {
            XCTAssertTrue(firstProcess.id > 0, "Process ID should be greater than 0.")
            XCTAssertGreaterThanOrEqual(firstProcess.cpuUsage, 0, "CPU usage should be greater than 0.")
            XCTAssertGreaterThan(firstProcess.memoryUsage, 0, "Memory usage should be greater than 0.")
        }
    }
    
    // Test macOS-specific behavior (on a real macOS machine)
    #if os(macOS)
    func testGetRunningProcessesMacOS() throws {
        let processes = processMonitor.getRunningProcesses()
        XCTAssertGreaterThan(processes.count, 0, "There should be running processes fetched on macOS.")
    }
    #endif
    
    
}
