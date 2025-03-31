// Persistence.swift
import SwiftData

// Unified ModelContainer for both SystemMetric and ProcessMetric
struct MetricContainer {
    static let shared = MetricContainer()
    let container: ModelContainer

    init() {
        do {
            // Initialize the container for both SystemMetric and ProcessMetric
            self.container = try ModelContainer(for: SystemMetric.self, ProcessInfo.self)
        } catch {
            fatalError("Failed to initialize Metric container: \(error)")
        }
    }
}
