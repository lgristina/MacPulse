//
//  MetricPayloadTests.swift
//  MacPulseTests
//

import XCTest
@testable import MacPulse

final class MetricPayloadTests: XCTestCase {
    private struct MockSystemMetric: Codable, Equatable {
        var timestamp: Date
        var cpuUsage: Double
        var memoryUsage: Double
    }

    private struct MockCustomProcessInfo: Codable, Equatable {
        var pid: Int
        var name: String
        var cpu: Double
    }

    private struct MockCPUUsageData: Codable, Equatable {
        var timestamp: Date
        var usage: Double
    }

    private enum MockMetricPayload: Codable, Equatable {
        case system(MockSystemMetric)
        case process([MockCustomProcessInfo])
        case cpuUsageHistory([MockCPUUsageData])
        case logs([String])
        case sendSystemMetrics
        case sendCpuHistory
        case sendProcessMetrics
        case stopSending(typeToStop: Int)
        
        enum CodingKeys: String, CodingKey {
            case type, payload
        }

        enum PayloadType: String, Codable {
            case system, process,
                 cpuUsageHistory,
                 logs,
                 sendSystemMetrics,
                 sendCpuHistory,
                 sendProcessMetrics,
                 stopSending
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .system(let metric):
                try container.encode(PayloadType.system, forKey: .type)
                try container.encode(metric, forKey: .payload)
            case .process(let processes):
                try container.encode(PayloadType.process, forKey: .type)
                try container.encode(processes, forKey: .payload)
            case .cpuUsageHistory(let history):
                try container.encode(PayloadType.cpuUsageHistory, forKey: .type)
                try container.encode(history, forKey: .payload)
            case .logs(let logs):
                try container.encode(PayloadType.logs, forKey: .type)
                try container.encode(logs, forKey: .payload)
            case .sendSystemMetrics:
                try container.encode(PayloadType.sendSystemMetrics, forKey: .type)
            case .sendCpuHistory:
                try container.encode(PayloadType.sendCpuHistory, forKey: .type)
            case .sendProcessMetrics:
                try container.encode(PayloadType.sendProcessMetrics, forKey: .type)
            case .stopSending(let typeToStop):
                try container.encode(PayloadType.stopSending, forKey: .type)
                try container.encode(typeToStop, forKey: .payload)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(PayloadType.self, forKey: .type)

            switch type {
            case .system:
                self = .system(try container.decode(MockSystemMetric.self, forKey: .payload))
            case .process:
                self = .process(try container.decode([MockCustomProcessInfo].self, forKey: .payload))
            case .cpuUsageHistory:
                self = .cpuUsageHistory(try container.decode([MockCPUUsageData].self, forKey: .payload))
            case .logs:
                self = .logs(try container.decode([String].self, forKey: .payload))
            case .sendSystemMetrics:
                self = .sendSystemMetrics
            case .sendCpuHistory:
                self = .sendCpuHistory
            case .sendProcessMetrics:
                self = .sendProcessMetrics
            case .stopSending:
                self = .stopSending(typeToStop: try container.decode(Int.self, forKey: .payload))
            }
        }
    }

    
    func testSystemMetricEncodingDecoding() throws {
        let payload: MockMetricPayload = .system(MockSystemMetric(timestamp: .now, cpuUsage: 50.0, memoryUsage: 1024.0))
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(MockMetricPayload.self, from: data)
        XCTAssertEqual(payload, decoded)
    }

    func testProcessEncodingDecoding() throws {
        let payload: MockMetricPayload = .process([
            MockCustomProcessInfo(pid: 123, name: "MockProcess", cpu: 75.0)
        ])
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(MockMetricPayload.self, from: data)
        XCTAssertEqual(payload, decoded)
    }

    func testCpuHistoryEncodingDecoding() throws {
        let payload: MockMetricPayload = .cpuUsageHistory([
            MockCPUUsageData(timestamp: .now, usage: 42.0)
        ])
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(MockMetricPayload.self, from: data)
        XCTAssertEqual(payload, decoded)
    }

    func testLogsEncodingDecoding() throws {
        let payload: MockMetricPayload = .logs(["Log A", "Log B"])
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(MockMetricPayload.self, from: data)
        XCTAssertEqual(payload, decoded)
    }

    func testSimpleCommandEncodingDecoding() throws {
        let payloads: [MockMetricPayload] = [
            .sendSystemMetrics,
            .sendCpuHistory,
            .sendProcessMetrics,
            .stopSending(typeToStop: 2)
        ]
        
        for payload in payloads {
            let data = try JSONEncoder().encode(payload)
            let decoded = try JSONDecoder().decode(MockMetricPayload.self, from: data)
            XCTAssertEqual(payload, decoded)
        }
    }
}
