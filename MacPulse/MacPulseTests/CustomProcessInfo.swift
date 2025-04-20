//
//  CustomProcessInfo.swift
//  MacPulseTests
//
//  Created by Marguerite McGahay on 4/20/25.
//
import XCTest
@testable import MacPulse

final class CustomProcessInfoTests: XCTestCase {

    func testInitialization() {
        let date = Date()
        let process = CustomProcessInfo(id: 1234, timestamp: date, cpuUsage: 42.0, memoryUsage: 128.0)
        
        XCTAssertEqual(process.id, 1234)
        XCTAssertEqual(process.timestamp, date)
        XCTAssertEqual(process.cpuUsage, 42.0)
        XCTAssertEqual(process.memoryUsage, 128.0)
    }

    func testToString() {
        let date = Date(timeIntervalSince1970: 0)
        let process = CustomProcessInfo(id: 1, timestamp: date, cpuUsage: 12.5, memoryUsage: 64.0)
        let result = process.toString()
        
        XCTAssertTrue(result.contains("ID: 1"))
        XCTAssertTrue(result.contains("CPU: 12.5"))
        XCTAssertTrue(result.contains("MEM: 64.0"))
    }
    
    func testCustomProcessInfoEncoding() throws {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let process = CustomProcessInfo(id: 1001, timestamp: date, cpuUsage: 45.6, memoryUsage: 128.0)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(process)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"id\":1001"))
        XCTAssertTrue(jsonString!.contains("\"cpuUsage\":45.6"))
    }

    func testCustomProcessInfoDecoding() throws {
        let json = """
        {
            "id": 2002,
            "timestamp": "2001-09-09T01:46:40Z",
            "cpuUsage": 55.5,
            "memoryUsage": 256.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(CustomProcessInfo.self, from: json)

        // Check for equality of timestamp to within a small accuracy, if comparing time intervals
        XCTAssertEqual(decoded.id, 2002)
        XCTAssertEqual(decoded.cpuUsage, 55.5)
        XCTAssertEqual(decoded.memoryUsage, 256.0)
        
        // Use time interval (in seconds) for comparison instead of directly comparing Date objects
        let expectedTimestamp = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, expectedTimestamp.timeIntervalSince1970, accuracy: 0.1)
    }


    func testCustomProcessInfoDecodeMissingFieldsFails() {
        let invalidJson = """
        {
            "id": 3003,
            "cpuUsage": 10.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(CustomProcessInfo.self, from: invalidJson)) { error in
            print("❌ Decoding failed as expected: \(error)")
        }
    }

}
