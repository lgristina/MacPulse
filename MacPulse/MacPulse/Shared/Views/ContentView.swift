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
    private static var systemMetrics = SystemMetricsDashboardMac()
#else
    private static var systemMetrics = SystemMetricsDashboardiOS()
#endif
    private static var processMetrics = ProcessListView()

    let options: [Option] = [
        .init(title: "System", imageName: "gear"),
        .init(title: "Process", imageName: "cpu"),
        .init(title: "Log", imageName: "doc.text"),
    ]

    @State private var selectedOption: Option? = Option(title: "System", imageName: "gear")

    var body: some View {
#if os(macOS)
        NavigationSplitView {
            sidebar
        } detail: {
            detailViewMac
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            // Set verbosity high so info logs show
            LogManager.shared.verbosityLevelForErrorAndDebug = .high
            LogManager.shared.verbosityLevelForSync = .high

            LogManager.shared.logInfo(.errorAndDebug, "ContentView appeared - App Launched (macOS)")
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
                detailViewiOS(for: option)
            }
        }
        .environmentObject(syncService)
        .task {
            // Set verbosity high so info logs show
            LogManager.shared.verbosityLevelForErrorAndDebug = .high
            LogManager.shared.verbosityLevelForSync = .high

            LogManager.shared.logInfo(.errorAndDebug, "ContentView appeared - App Launched (iOS)")
        }
#endif
    }
    private var sidebar: some View {
        List(options, id: \.self, selection: $selectedOption) { option in
            NavigationLink(value: option) {
                Label(option.title, systemImage: option.imageName)
            }
            .accessibilityIdentifier(option.title)
        }
        .navigationTitle("MacPulse")
    }

    @ViewBuilder
    private var detailViewMac: some View {
        VStack {
            switch selectedOption?.title {
            case "System":
                ContentView.systemMetrics
            case "Process":
                ContentView.processMetrics
            case "Log":
                LogView()
            default:
                Text("Select an option")
            }

            Spacer()

            // Add Test Log button
            Button("Add Test Log") {
                LogManager.shared.logInfo(.errorAndDebug, "Test log added at \(Date()) (macOS)")
            }
            .padding()
        }
    }

    struct detailViewiOS: View {
        let option: Option
        
        init(for option: Option) {
            self.option = option
        }

        var body: some View {
            VStack {
                if option.title == "System" {
                    ContentView.systemMetrics
                } else if option.title == "Process" {
                    ContentView.processMetrics
                } else if option.title == "Log" {
                    LogView()
                }

                Spacer()

                // Add Test Log button
                Button("Add Test Log") {
                    LogManager.shared.logInfo(.errorAndDebug, "Test log added at \(Date()) (iOS)")
                }
                .padding()
            }
            .padding()
            .navigationTitle(option.title)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
