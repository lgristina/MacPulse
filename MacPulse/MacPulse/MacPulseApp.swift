// MARK: MACPULSE APP
/*  This is the entry point for both the macOS and
 iOS MacPulse applications. It checks the currently
 running operating system to dispatch the applicable
 version of the application. In both cases, it will
 kick off the landing page of the MacPulse app. */

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
    
//    var sharedModelContainer: ModelContainer = {
//           let schema = Schema([
//               SystemMetric.self,
//               CustomProcessInfo.self
//           ])
//           
//           let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//           
//           do {
//               return try ModelContainer(for: schema, configurations: [modelConfiguration])
//           } catch {
//               fatalError("Could not create ModelContainer: \(error)")
//           }
//    }()
    
    var sharedModelContainer: ModelContainer = {
        // ⚠️ DEV ONLY – remove before release
        let fileManager = FileManager.default
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = supportDir.appendingPathComponent("default.store")

        if fileManager.fileExists(atPath: storeURL.path) {
            do {
                try fileManager.removeItem(at: storeURL)
                print("🧹 Deleted persistent store at \(storeURL.path)")
            } catch {
                print("❌ Failed to delete persistent store: \(error)")
            }
        }

        let schema = Schema([
            SystemMetric.self,
            CustomProcessInfo.self
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
        .modelContainer(sharedModelContainer)
    }
}
