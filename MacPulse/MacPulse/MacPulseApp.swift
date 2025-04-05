import SwiftUI
import SwiftData

@main
struct MacPulseApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SystemMetric.self, // Add your model types here
            ProcessInfo.self  // Add ProcessMetric if it is part of your app's data model
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
            DataManager.shared.startPruningTimer()
        }
    var body: some Scene {
        #if os(iOS)
        WindowGroup {
            SystemMetricsDashboard()
        }
        .modelContainer(sharedModelContainer)  // Attach the sharedModelContainer to the app’s window group
        #elseif os(macOS)
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)  // Attach the sharedModelContainer to the app’s window group
        #endif
    }
}
