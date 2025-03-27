import SwiftUI
import SwiftData

struct Option: Hashable {
    let title: String
    let imageName: String
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
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
            detailView
        }
        .frame(minWidth: 600, minHeight: 400)
        #else
        NavigationStack {
            sidebar
        }
        #endif
    }
    
    private var sidebar: some View {
        List(options, id: \.self, selection: $selectedOption) { option in
            NavigationLink(value: option) {
                Label(option.title, systemImage: option.imageName)
            }
        }
        .navigationTitle("MacPulse")
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedOption?.title {
        case "Home":
            Text("Home View")
        case "System":
            SystemMetricsDashboardMac()
        case "Process":
            ProcessListView()
        case "Log":
            LogView()
        default:
            Text("Select an option")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
