import SwiftUI
import SwiftData

struct Option: Hashable {
    let title: String
    let imageName: String
}

@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var syncService: MCConnectionManager
    @Query private var items: [Item]
    #if os(macOS)
    @State private var selectedProcessID: Int? = nil
    #endif
    
    let options: [Option] = [
        .init(title: "System", imageName: "desktopcomputer"),
        .init(title: "Process", imageName: "cpu"),
        .init(title: "Log", imageName: "doc.text"),
        .init(title: "Settings", imageName: "gear")
    ]

    @State private var selectedOption: Option? = Option(title: "System", imageName: "desktopcomputer")

    var body: some View {
#if os(macOS)
        NavigationSplitView {
            sidebar
        } detail: {
            detailViewMac
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            LogManager.shared.verbosityLevelForErrorAndDebug = .high
            LogManager.shared.verbosityLevelForSyncRetrieval = .high
            LogManager.shared.verbosityLevelForSyncConnection = .high
            LogManager.shared.verbosityLevelForSyncTransmission = .high
            LogManager.shared.log(.errorAndDebug, level: LogVerbosityLevel.high, "ContentView appeared - App Launched (macOS)")

            // Register CPU history response handler for macOS
            syncService.onRequestCpuHistory = {
                guard !syncService.session.connectedPeers.isEmpty else {
                    LogManager.shared.log(.syncTransmission, level: .low, "⚠️ No peers connected — cannot send CPU history.")
                    return
                }

                SystemMonitor.shared.loadCPUHistory(from: modelContext)

                let history = SystemMonitor.shared.cpuUsageHistory
                let payload = MetricPayload.cpuUsageHistory(history)
                syncService.send(payload)

                LogManager.shared.log(.syncTransmission, level: .medium, "📤 Sent CPU history to peer.")
            }
        }
#else
        NavigationStack {
            List {
                if let connectedPeer = syncService.session.connectedPeers.first {
                    Section {
                        Text("Connected to: \(connectedPeer.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                Section {
                    ForEach(options, id: \.self) { option in
                        NavigationLink(value: option) {
                            Label(option.title, systemImage: option.imageName)
                        }
                    }
                }
            }
            .navigationTitle("MacPulse Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Option.self) { option in
                DetailViewiOS(for: option)
            }
            .navigationDestination(for: Int.self) { processID in
                ProcessDetailView(processID: processID)
            }
        }
        .environmentObject(syncService)
        .task {
            // Set verbosity high so info logs show
            LogManager.shared.verbosityLevelForErrorAndDebug = .high
            LogManager.shared.verbosityLevelForSyncRetrieval = .high
            
            LogManager.shared.log(.errorAndDebug, level: .high, "ContentView appeared - App Launched (iOS)")
        }
#endif
    }

    private var sidebar: some View {
        List(options, id: \.self, selection: $selectedOption) { option in
            NavigationLink(value: option) {
                Label(option.title, systemImage: option.imageName)
            }
            .accessibilityIdentifier(option.title)
            .accessibilityAddTraits(.isButton)
        }
        .navigationTitle("MacPulse")
    }

    @ViewBuilder
    private var detailViewMac: some View {
        VStack {
            switch selectedOption?.title {
            case "System":
                SystemMetricsDashboard()
            case "Process":
                #if os(macOS)
                ProcessListView(selectedProcessID: $selectedProcessID)
                #endif
            case "Log":
                LogView()
            case "Settings":
                SettingsView()
            default:
                Text("Select an option")
            }
            Spacer()
        }
        .padding()
    }
}

struct DetailViewiOS: View {
    let option: Option

    init(for option: Option) {
        self.option = option
    }

    @ViewBuilder
    var body: some View {
        VStack {
            switch option.title {
            case "System":
                SystemMetricsDashboard()
            case "Process":
                #if os(iOS)
                ProcessListView()
                #endif
            case "Log":
                LogView()
            case "Settings":
                SettingsView()
            default:
                Text("Unknown option")
            }
            Spacer()
        }
        .padding()
        .navigationTitle(option.title)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
