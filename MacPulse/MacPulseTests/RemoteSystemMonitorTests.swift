import XCTest
@testable import MacPulse

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
        let mockManager = MockConnectionManager(yourName: "test")
        let monitor = RemoteSystemMonitor(connectionManager: mockManager)
        
        // Start sending process metrics
        monitor.startSendingMetrics(type: 1)
        
        // Simulate a short delay to allow the timer to fire
        let expectation = XCTestExpectation(description: "Wait for process metric sending")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Check that a process metric payload has been sent
            XCTAssertEqual(mockManager.sentPayloads.count, 1)
            if case .process(let processes) = mockManager.sentPayloads.first {
                XCTAssertTrue(processes.count > 0) // Check if some process metrics are being sent
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
