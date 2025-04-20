//
//  SystemMetricsTests.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 4/20/25.
//
import XCTest
@testable import MacPulse

final class SystemMetricTests: XCTestCase {

    func testInitialization() {
        let date = Date()
        let metric = SystemMetric(timestamp: date, cpuUsage: 50.0, memoryUsage: 60.0, diskActivity: 70.0)

        XCTAssertEqual(metric.timestamp, date)
        XCTAssertEqual(metric.cpuUsage, 50.0)
        XCTAssertEqual(metric.memoryUsage, 60.0)
        XCTAssertEqual(metric.diskActivity, 70.0)
    }

    func testToString() {
        let date = ISO8601DateFormatter().date(from: "2025-04-20T12:34:56Z")!
        let metric = SystemMetric(timestamp: date, cpuUsage: 23.5, memoryUsage: 50.2, diskActivity: 75.0)
        let string = metric.toString()

        XCTAssertTrue(string.contains("CPU: 23.5%"))
        XCTAssertTrue(string.contains("MEM: 50.2%"))
        XCTAssertTrue(string.contains("DISK: 75.0%"))
        XCTAssertTrue(string.contains("Time:"))
    }

    func testDescriptionMatchesToString() {
        let metric = SystemMetric(timestamp: Date(), cpuUsage: 10, memoryUsage: 20, diskActivity: 30)
        XCTAssertEqual(metric.description, metric.toString())
    }

    func testEncodingAndDecoding() throws {
        let originalDate = Date(timeIntervalSince1970: 1_745_178_210) // fixed to remove sub‑second noise
        let original = SystemMetric(timestamp: originalDate, cpuUsage: 88.8, memoryUsage: 77.7, diskActivity: 66.6)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SystemMetric.self, from: data)

        let origSec = original.timestamp.timeIntervalSince1970.rounded()
        let decSec  = decoded.timestamp.timeIntervalSince1970.rounded()

        XCTAssertEqual(decoded.cpuUsage, original.cpuUsage, accuracy: 0.01)
        XCTAssertEqual(decoded.memoryUsage, original.memoryUsage, accuracy: 0.01)
        XCTAssertEqual(decoded.diskActivity, original.diskActivity, accuracy: 0.01)
        XCTAssertEqual(decSec, origSec)
    }
}
