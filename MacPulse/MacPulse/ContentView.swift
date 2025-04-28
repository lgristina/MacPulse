import SwiftUI
import SwiftData

struct Option: Hashable {
    let title: String
    let imageName: String
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
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
            LogManager.shared.verbosityLevelForErrorAndDebug = .high
            LogManager.shared.verbosityLevelForSync = .high
            LogManager.shared.logInfo(.errorAndDebug, "ContentView appeared - App Launched (macOS)")
        }
        #else
        NavigationStack {
            List(options, id: \.self) { option in
                NavigationLink(value: option) {
                    Label(option.title, systemImage: option.imageName)
                }
            }
            .navigationTitle("MacPulse")
            .navigationDestination(for: Option.self) { option in
                DetailViewiOS(for: option)
            }
        }
        .task {
            // Set verbosity high so info logs show
            LogManager.shared.verbosityLevelForErrorAndDebug = LogVerbosityLevel.high
            LogManager.shared.verbosityLevelForSyncRetrieval = LogVerbosityLevel.high
            
            LogManager.shared.log(.errorAndDebug,level: .high, "ContentView appearded = App Launched macOS")
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

            Button("Add Test Log") {
                LogManager.shared.log(.errorAndDebug,level: .high, "Test log added at \(Date()) (macOS)")
            }
            .padding()
        }
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
                ContentView.systemMetrics
            case "Process":
                ContentView.processMetrics
            case "Log":
                LogView()
            default:
                Text("Unknown option")
            }

            Spacer()

            Button("Add Test Log") {
                LogManager.shared.logInfo(.errorAndDebug, "Test log added at \(Date()) (iOS)")
            }
            .padding()
        }
        .padding()
        .navigationTitle(option.title)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
