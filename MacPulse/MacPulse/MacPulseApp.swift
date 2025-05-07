// MARK: MACPULSE APP
/*  This is the entry point for both the macOS and
 iOS MacPulse applications. It checks the currently
 running operating system to dispatch the applicable
 version of the application. In both cases, it will
 kick off the landing page of the MacPulse app. */

import SwiftUI
import SwiftData

// MARK: – Color Inversion Modifier
/// Conditionally inverts all colors in the view hierarchy
struct InvertColorsModifier: ViewModifier {
    let isInverted: Bool
    func body(content: Content) -> some View {
        Group {
            if isInverted {
                content.colorInvert()
            } else {
                content
            }
        }
    }
}

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
    
    @AppStorage("invertColors") private var invertColors: Bool = false
    
    @StateObject private var syncService: MCConnectionManager
    @State private var hasStarted: Bool = false
    
    init() {
        
        let peerName = getPeerName()
        let manager = MCConnectionManager(yourName: peerName)
        _syncService = StateObject(wrappedValue: manager)
        
        // Configure the singleton once when the app starts
        RemoteSystemMonitor.shared.configure(connectionManager: manager)
    }
    
    var sharedModelContainer: ModelContainer = {
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
            Group {
                if hasStarted {
                    ContentView()
                } else {
                    LandingView(hasStarted: $hasStarted)
                }
            }
            .environmentObject(syncService)
            .environment(\.colorScheme, invertColors ? .light : .dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
