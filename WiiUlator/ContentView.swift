import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .library

    enum Tab {
        case library
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2")
                }
                .tag(Tab.library)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
    }
}

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("WiiUlator") {
                    Label("Games", systemImage: "gamecontroller")
                    Label("Recent Games", systemImage: "clock")
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
            .navigationTitle("Library")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Emulation") {
                    Label("Graphics", systemImage: "display")
                    Label("Controls", systemImage: "gamecontroller.fill")
                    Label("Audio", systemImage: "speaker.wave.2")
                    Label("System", systemImage: "gearshape")
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section("WiiUlator") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Platform", value: "iOS & iPadOS")
                LabeledContent("Minimum iOS", value: "16.0")
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    ContentView()
}
