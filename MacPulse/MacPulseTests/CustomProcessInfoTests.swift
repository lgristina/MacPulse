import XCTest
@testable import MacPulse

final class CustomProcessInfoTests: XCTestCase {

    // Test initialization of the new properties
    func testInitialization() {
        let date = Date()
        let process = CustomProcessInfo(id: 1234, timestamp: date, cpuUsage: 42.0, memoryUsage: 128.0, shortProcessName: "Process A", fullProcessName: "Process Full A")
        
        XCTAssertEqual(process.id, 1234)
        XCTAssertEqual(process.timestamp, date)
        XCTAssertEqual(process.cpuUsage, 42.0)
        XCTAssertEqual(process.memoryUsage, 128.0)
        XCTAssertEqual(process.shortProcessName, "Process A")
        XCTAssertEqual(process.fullProcessName, "Process Full A")
    }

    // Test that the description property includes the new properties
    func testDescription() {
        let date = Date(timeIntervalSince1970: 0)
        let process = CustomProcessInfo(id: 1, timestamp: date, cpuUsage: 12.5, memoryUsage: 64.0, shortProcessName: "TestProcess", fullProcessName: "Test Full Process")
        let result = process.description
        
        XCTAssertTrue(result.contains("ID: 1"))
        XCTAssertTrue(result.contains("CPU: 12.5"))
        XCTAssertTrue(result.contains("MEM: 64.0"))
        XCTAssertTrue(result.contains("Short: TestProcess"))
        XCTAssertTrue(result.contains("Full: Test Full Process"))
    }
    
    // Test encoding the object including the new properties
    func testCustomProcessInfoEncoding() throws {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let process = CustomProcessInfo(id: 1001, timestamp: date, cpuUsage: 45.6, memoryUsage: 128.0, shortProcessName: "Test", fullProcessName: "Test Full Process")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(process)
        let jsonString = String(data: data, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"id\":1001"))
        XCTAssertTrue(jsonString!.contains("\"cpuUsage\":45.6"))
        XCTAssertTrue(jsonString!.contains("\"shortProcessName\":\"Test\""))
        XCTAssertTrue(jsonString!.contains("\"fullProcessName\":\"Test Full Process\""))
    }

    // Test decoding the object including the new properties
    func testCustomProcessInfoDecoding() throws {
        let json = """
        {
            "id": 2002,
            "timestamp": "2001-09-09T01:46:40Z",
            "cpuUsage": 55.5,
            "memoryUsage": 256.0,
            "shortProcessName": "ProcessB",
            "fullProcessName": "Full Process B"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(CustomProcessInfo.self, from: json)

        // Check for equality of id, cpuUsage, memoryUsage, shortProcessName, and fullProcessName
        XCTAssertEqual(decoded.id, 2002)
        XCTAssertEqual(decoded.cpuUsage, 55.5)
        XCTAssertEqual(decoded.memoryUsage, 256.0)
        XCTAssertEqual(decoded.shortProcessName, "ProcessB")
        XCTAssertEqual(decoded.fullProcessName, "Full Process B")
        
        // Use time interval (in seconds) for comparison instead of directly comparing Date objects
        let expectedTimestamp = decoded.timestamp
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, expectedTimestamp.timeIntervalSince1970, accuracy: 0.1)
    }

    // Test decoding failure when fields are missing (new properties)
    func testCustomProcessInfoDecodeMissingFieldsFails() {
        let invalidJson = """
        {
            "id": 3003,
            "cpuUsage": 10.0,
            "memoryUsage": 64.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(CustomProcessInfo.self, from: invalidJson)) { error in
            print("❌ Decoding failed as expected: \(error)")
        }
    }
}
