import SwiftUI
import SwiftData


func getPeerName() -> String {
    #if os(macOS)
    return Host.current().localizedName ?? "MacPulse"
    #elseif os(iOS)
    return UIDevice.current.name
    #else
    return "MacPulse"
    #endif
}

@main
struct MacPulseApp: App {
    
    @StateObject private var syncService: MCConnectionManager
    @State private var hasStarted: Bool = false
    
    init() {
        let peerName = getPeerName()
        let manager = MCConnectionManager(yourName: peerName)
        _syncService = StateObject(wrappedValue: manager)

        RemoteSystemMonitor.shared = RemoteSystemMonitor(connectionManager: manager)
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SystemMetric.self, // Add your model types here
            CustomProcessInfo.self  // Add ProcessMetric if it is part of your app's data model
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if hasStarted {
                ContentView()
                    .environmentObject(syncService)
            }
            else {
                LandingView(hasStarted: $hasStarted)
                    .environmentObject(syncService)
            }
        }
        .modelContainer(sharedModelContainer)  // Attach the sharedModelContainer to the app’s window group
    }
}
