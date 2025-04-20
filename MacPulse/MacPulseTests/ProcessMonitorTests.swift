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

    func testStartMonitoring() throws {
        // Ensure that monitoring starts and sets a timer
        let initialRunningProcessesCount = processMonitor.runningProcesses.count
        processMonitor.startMonitoring()
        
        // Wait for a little while to ensure the timer has time to fire
        let expectation = self.expectation(description: "Monitoring started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            XCTAssertGreaterThan(self.processMonitor.runningProcesses.count, initialRunningProcessesCount, "The running processes should have increased after monitoring started.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    
    func testStopMonitoring() throws {
        processMonitor.startMonitoring()
        
        // Ensure that monitoring stops when stopMonitoring is called
        processMonitor.stopMonitoring()
        
        // The timer should be invalidated
        XCTAssertNil(processMonitor.timer, "The timer should be nil after stopping monitoring.")
    }

    func testCollectAndSaveProcesses() throws {
        let expectation = XCTestExpectation(description: "Processes collected and assigned")

        // Simulate collecting and saving processes
        processMonitor.collectAndSaveProcesses()

        // Delay just long enough for the async Task { @MainActor in ... } to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.processMonitor.runningProcesses.isEmpty, "There should be running processes after collectAndSaveProcesses is called.")

            let firstProcess = self.processMonitor.runningProcesses.first
            XCTAssertNotNil(firstProcess, "First process should not be nil.")
            XCTAssertGreaterThan(firstProcess?.cpuUsage ?? 0, 0, "CPU usage should be greater than 0.")
            XCTAssertGreaterThan(firstProcess?.memoryUsage ?? 0, 0, "Memory usage should be greater than 0.")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }


    func testGetRunningProcesses() throws {
        let processes = processMonitor.getRunningProcesses()
        
        XCTAssertGreaterThan(processes.count, 0, "There should be at least one process fetched.")
        
        if let firstProcess = processes.first {
            XCTAssertTrue(firstProcess.id > 0, "Process ID should be greater than 0.")
            XCTAssertGreaterThan(firstProcess.cpuUsage, 0, "CPU usage should be greater than 0.")
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
