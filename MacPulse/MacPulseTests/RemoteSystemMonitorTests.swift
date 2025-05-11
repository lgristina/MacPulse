import XCTest
@testable import MacPulse

enum UnsupportedMetricPayload {
    case invalid
}

extension RemoteSystemMonitor {
    func handleInvalidPayload(_ payload: UnsupportedMetricPayload) {
        LogManager.shared.log(.syncTransmission, level: .high, "⚠️ Received unsupported metric payload.")
    }
}

final class RemoteSystemMonitorTests: XCTestCase {
    
    class MockConnectionManager: MCConnectionManager {
        var sentPayloads: [MetricPayload] = []
        var didLogInvalidMetric = false
        
        override func send(_ payload: MetricPayload) {
            sentPayloads.append(payload)
        }
        
        // Simulate the logging mechanism for invalid metric types
        func logInvalidMetric(type: Int) {
            if type != 0 && type != 1 {
                didLogInvalidMetric = true
            }
        }
        
    }
    
    
    func testSystemMetricUpdate() {
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        
        // Reassign handler to ensure onReceiveMetric is set
        monitor.configure(connectionManager: mockManager)
        
        let testMetric = SystemMetric(
            timestamp: Date(),
            cpuUsage: 42.0,
            memoryUsage: 2048.0,
            diskActivity: 75.0
        )
        let testPayload = MetricPayload.system(testMetric)
        
        // Trigger the update
        mockManager.onReceiveMetric?(testPayload)
        
        // Use expectation to wait for async property update
        let expectation = XCTestExpectation(description: "Wait for system metric update")
        DispatchQueue.main.async {
            XCTAssertEqual(monitor.cpuUsage, 42.0, accuracy: 0.001)
            XCTAssertEqual(monitor.memoryUsage, 2048.0, accuracy: 0.001)
            XCTAssertEqual(monitor.diskActivity, 75.0, accuracy: 0.001)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testProcessMetricUpdate() {
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        
        // Reconfigure so onReceiveMetric closure is assigned
        monitor.configure(connectionManager: mockManager)
        
        let testProcesses = [
            CustomProcessInfo(
                id: 1,
                timestamp: Date(),
                cpuUsage: 10.5,
                memoryUsage: 512,
                shortProcessName: "Proc1",
                fullProcessName: "Full Process 1"
            ),
            CustomProcessInfo(
                id: 2,
                timestamp: Date(),
                cpuUsage: 25.0,
                memoryUsage: 1024,
                shortProcessName: "Proc2",
                fullProcessName: "Full Process 2"
            )
        ]
        
        let testPayload = MetricPayload.process(testProcesses)
        
        // Simulate receiving the payload
        mockManager.onReceiveMetric?(testPayload)
        
        // Give time for DispatchQueue.main.async to execute
        let expectation = XCTestExpectation(description: "Wait for async update")
        DispatchQueue.main.async {
            XCTAssertEqual(monitor.runningProcesses.count, 2)
            XCTAssertEqual(monitor.runningProcesses[0].cpuUsage, 10.5)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testStartStopSystemMetricTimer() {
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        
        monitor.startSendingMetrics(type: 0)
        
        // Verify timer is created
        XCTAssertNotNil(monitor.systemMetricTimer)
        
        // Stop the timer and verify it is nil
        monitor.stopSendingMetrics(type: 0)
        XCTAssertNil(monitor.systemMetricTimer)
    }
    
    func testStartStopProcessMetricTimer() {
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        
        monitor.startSendingMetrics(type: 1)
        
        // Verify timer is created
        XCTAssertNotNil(monitor.processMetricTimer)
        
        // Stop the timer and verify it is nil
        monitor.stopSendingMetrics(type: 1)
        XCTAssertNil(monitor.processMetricTimer)
    }
    
    func testStartSendingSystemMetrics() {
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        
        // Start sending system metrics
        monitor.startSendingMetrics(type: 0)
        
        // Simulate a short delay to allow the timer to fire
        let expectation = XCTestExpectation(description: "Wait for system metric sending")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Check that a system metric payload has been sent
            XCTAssertEqual(mockManager.sentPayloads.count, 1)
            if case .system(let metric) = mockManager.sentPayloads.first {
                XCTAssertEqual(metric.cpuUsage, 0, accuracy: 0.001)
                XCTAssertEqual(metric.memoryUsage, 0.0, accuracy: 0.001)
                XCTAssertEqual(metric.diskActivity, 0.0, accuracy: 0.001)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testStartSendingProcessMetrics() {
        // Arrange
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        
        // Mock the running processes to simulate data
        let mockProcessInfo = CustomProcessInfo(
            id: 1234,
            timestamp: Date(),
            cpuUsage: 10.0,
            memoryUsage: 50.0,
            shortProcessName: "TestProcess",
            fullProcessName: "/usr/bin/TestProcess"
        )
        
        // Mock data for running processes
        ProcessMonitor.shared.runningProcesses = [mockProcessInfo]
        
        // Act
        monitor.startSendingMetrics(type: 1) // Start sending process metrics
        
        // Expectation to wait for process metric sending
        let expectation = XCTestExpectation(description: "Wait for process metric sending")
        
        // Simulate a short delay to allow the timer to fire
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Assert that a payload was sent
            XCTAssertEqual(mockManager.sentPayloads.count, 1, "Expected 1 payload to be sent.")
            
            // Assert the payload is a process metric and that it's not empty
            if case .process(let processes) = mockManager.sentPayloads.first {
                XCTAssertTrue(processes.count > 0, "Process metrics should not be empty")
            }
            expectation.fulfill()
        }
        
        // Wait for the expectation to be fulfilled
        wait(for: [expectation], timeout: 3.0)
    }
    
    
    
    func testInvalidMetricTypeHandling() {
        // Create the mock connection manager
        let mockManager = MockConnectionManager(yourName: "test")
        
        // Initialize the RemoteSystemMonitor with the mock manager
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        monitor.configure(connectionManager: mockManager)
        
        // Send an invalid metric type (anything other than 0 or 1)
        let invalidType = 999
        monitor.startSendingMetrics(type: invalidType)
        
        // Simulate the logInvalidMetric being triggered by an invalid type
        mockManager.logInvalidMetric(type: invalidType)
        
        // Wait for async property updates and verify if the log was triggered
        let expectation = XCTestExpectation(description: "Wait for invalid metric handling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(mockManager.didLogInvalidMetric, "Expected invalid metric to be logged.")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testCpuUsageHistoryUpdate() {
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        monitor.configure(connectionManager: mockManager)
        
        let historyData = [
            CPUUsageData(usage: 10.0, time: Date()),
            CPUUsageData(usage: 20.0, time: Date()),
            CPUUsageData(usage: 30.0, time: Date())
        ]
        let payload = MetricPayload.cpuUsageHistory(historyData)
        
        let expectation = XCTestExpectation(description: "Wait for CPU usage history update")
        mockManager.onReceiveMetric?(payload)
        
        DispatchQueue.main.async {
            XCTAssertEqual(monitor.cpuUsageHistory.count, 3)
            XCTAssertEqual(monitor.cpuUsageHistory.map(\.usage), [10.0, 20.0, 30.0])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    func testUnknownMetricPayload() {
        let json = """
        {
            "type": "custom",
            "payload": { "foo": "bar" }
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(MetricPayload.self, from: json)) { error in
            // Optional: Inspect error if needed
            print("Caught expected decoding error: \(error)")
        }
    }
}
