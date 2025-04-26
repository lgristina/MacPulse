//
//  MetricPayload.swift
//  MacPulse
//
//  Created by Austin Frank on 4/17/25.
//

import Foundation

enum MetricPayload: Codable {
    case system(SystemMetric)
    case process([CustomProcessInfo])
    case logs([String]) // Placeholder for now
    case sendSystemMetrics
    case sendProcessMetrics
    case stopSending(typeToStop: Int)

    enum CodingKeys: String, CodingKey {
        case type, payload
    }

    enum PayloadType: String, Codable {
        case system, process, logs, sendSystemMetrics, sendProcessMetrics, stopSending
    }

    // MARK: - Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .system(let systemMetric):
            try container.encode(PayloadType.system, forKey: .type)
            try container.encode(systemMetric, forKey: .payload)
        case .process(let customProcessInfo):
            try container.encode(PayloadType.process, forKey: .type)
            try container.encode(customProcessInfo, forKey: .payload)
        case .logs(let logs):
            try container.encode(PayloadType.logs, forKey: .type)
            try container.encode(logs, forKey: .payload)
        case .sendSystemMetrics:
            try container.encode(PayloadType.sendSystemMetrics, forKey: .type)
        case .sendProcessMetrics:
            try container.encode(PayloadType.sendProcessMetrics, forKey: .type)
        case .stopSending(let typeToStop):
            try container.encode(PayloadType.stopSending, forKey: .type)
            try container.encode(typeToStop, forKey: .payload)
        }
    }

    // MARK: - Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PayloadType.self, forKey: .type)

        switch type {
        case .system:
            let metric = try container.decode(SystemMetric.self, forKey: .payload)
            self = .system(metric)
        case .process:
            let processes = try container.decode([CustomProcessInfo].self, forKey: .payload)
            self = .process(processes)
        case .logs:
            let logs = try container.decode([String].self, forKey: .payload)
            self = .logs(logs)
        case .sendSystemMetrics:
            self = .sendSystemMetrics
        case .sendProcessMetrics:
            self = .sendProcessMetrics
        case .stopSending:
            let typeToStop = try container.decode(Int.self, forKey: .payload)
            self = .stopSending(typeToStop: typeToStop)  // Properly assign typeToStop
        }
    }
}
