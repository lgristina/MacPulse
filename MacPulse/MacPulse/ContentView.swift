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
        .init(title: "Home", imageName: "house"),
        .init(title: "System", imageName: "gear"),
        .init(title: "Process", imageName: "cpu"),
        .init(title: "Log", imageName: "doc.text"),
    ]
    
    @State private var selectedOption: Option? =  Option(title: "Home", imageName: "house")

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            sidebar
        } detail: {
            detailViewMac
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            LogManager.shared.logInfo("ContentView appeared - App Launched (macOS)")
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
                        detailViewiOS(for:option)
                    }
                }
        .task {
            LogManager.shared.logInfo("ContentView appeared - App Launched (iOS)")
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
        switch selectedOption?.title {
        case "Home":
            VStack {
                  Image("MacPulse")
                      .resizable()
                      .scaledToFill() // Ensures the image fills the entire view
                      .edgesIgnoringSafeArea(.all) // Makes the image fill the safe area of the screen
                      .padding(.bottom, 20)
              }
        case "System":
            ContentView.systemMetrics
        case "Process":
            ContentView.processMetrics
        case "Log":
            LogView()
        default:
            Text("Select an option")
        }
    }
    
    struct detailViewiOS: View {
        let option: Option
            
        init(for option: Option) {
            self.option = option
        }
        
        var body: some View {
                VStack {
                    Text("Detail for \(option.title)")
                        .font(.largeTitle)
                    // Replace with your actual content views.
                    if option.title == "Home" {
                        Image("MacPulse")
                            .resizable()
                            .scaledToFill() // Ensures the image fills the entire view
                            .edgesIgnoringSafeArea(.all) // Makes the image fill the safe area of the screen
                            .padding(.bottom, 20)
                    } else if option.title == "System" {
                        ContentView.systemMetrics
                    } else if option.title == "Process" {
                        ContentView.processMetrics
                    } else if option.title == "Log" {
                        LogView()
                    }
                    Spacer()
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
