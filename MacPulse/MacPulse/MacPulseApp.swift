//
//  MacPulseApp.swift
//  MacPulse
//
//  Created by Luca Gristina on 3/10/25.
//

import SwiftUI
import SwiftData

@main
struct MacPulseApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            SystemMetricsDashboard()
        }
        .modelContainer(sharedModelContainer)
        #elseif os(macOS)
        WindowGroup {
            ContentView()
            //SystemMetricsDashboardMac()
            //ProcessListView()
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
}
