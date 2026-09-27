import SwiftUI
import UniformTypeIdentifiers

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
    @State private var showingImporter = false

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Games",
                systemImage: "gamecontroller",
                description: Text("Import a Wii U game to add it to your library.")
            )
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Import Game")
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.data, .folder],
                allowsMultipleSelection: false
            ) { _ in
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Emulation") {
                    NavigationLink {
                        GraphicsSettingsView()
                    } label: {
                        Label("Graphics", systemImage: "display")

                    NavigationLink {
                        ControlsSettingsView()
                    } label: {
                        Label("Controls", systemImage: "gamecontroller.fill")
                    }

                    NavigationLink {
                        AudioSettingsView()
                    } label: {
                        Label("Audio", systemImage: "speaker.wave.2")

                    NavigationLink {
                        SystemSettingsView()
                    } label: {
                        Label("System", systemImage: "gearshape")
                    }
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

struct GraphicsSettingsView: View {
    @AppStorage("graphicsBackend") private var graphicsBackend = "Metal"
    @AppStorage("graphicsQuality") private var graphicsQuality = "Auto"
    @AppStorage("performanceMode") private var performanceMode = false
    @AppStorage("thirtyFPSFullSpeed") private var thirtyFPSFullSpeed = true

    var body: some View {
        Form {
            Section("Graphics Backend") {
                Picker("Backend", selection: $graphicsBackend) {
                    Text("Metal").tag("Metal")
                    Text("Vulkan (Experimental)").tag("Vulkan")
                }
            }

            Section("Rendering") {
                Picker("Quality", selection: $graphicsQuality) {
                    Text("Auto").tag("Auto")
                    Text("Low").tag("Low")
                    Text("Medium").tag("Medium")
                    Text("High").tag("High")
                }

                Toggle("Performance Mode", isOn: $performanceMode)
                Toggle("30 FPS = Full Emulation Speed", isOn: $thirtyFPSFullSpeed)
            }

            Section {
                Text("Metal is the primary graphics backend. Vulkan is experimental and may not be available on every device or iOS version.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Graphics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ControlsSettingsView: View {
    @AppStorage("controllerType") private var controllerType = "Wii U GamePad"
    @AppStorage("rumbleEnabled") private var rumbleEnabled = true

    var body: some View {
        Form {
            Section("Controller") {
                Picker("Controller", selection: $controllerType) {
                    Text("Wii U GamePad").tag("Wii U GamePad")
                    Text("Pro Controller").tag("Pro Controller")
                    Text("Touch Controls").tag("Touch Controls")
                }

                Toggle("Rumble", isOn: $rumbleEnabled)
            }

            Section("Layout") {
                NavigationLink("Configure Controls") {
                    ControlLayoutView()
                }
            }
        }
        .navigationTitle("Controls")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ControlLayoutView: View {
    var body: some View {
        Form {
            Section("Buttons") {
                LabeledContent("A", value: "A")
                LabeledContent("B", value: "B")
                LabeledContent("X", value: "X")
                LabeledContent("Y", value: "Y")
                LabeledContent("D-Pad", value: "D-Pad")
            }

            Section {
                Text("Custom button mapping will be available as the emulator input system is implemented.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Configure Controls")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AudioSettingsView: View {
    @AppStorage("audioEnabled") private var audioEnabled = true
    @AppStorage("audioVolume") private var audioVolume = 1.0

    var body: some View {
        Form {
            Section("Game Audio") {
                Toggle("Enable Audio", isOn: $audioEnabled)

                VStack(alignment: .leading) {
                    Text("Volume")
                    Slider(value: $audioVolume, in: 0...1)
                }
                .disabled(!audioEnabled)
            }

            Section {
                Text("WiiUlator does not use interface sound effects. Audio settings apply to emulated games.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Audio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SystemSettingsView: View {
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("confirmExit") private var confirmExit = true

    var body: some View {
        Form {
            Section("System") {
                Toggle("Auto Save", isOn: $autoSave)
                Toggle("Confirm Before Exit", isOn: $confirmExit)
            }

            Section("Performance") {
                LabeledContent("Architecture", value: "ARM64")
                LabeledContent("Minimum iOS", value: "16.0")
                LabeledContent("Graphics", value: "Metal")
            }
        }
        .navigationTitle("System")
        .navigationBarTitleDisplayMode(.inline)
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

            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.tint)

                        Text("WiiUlator")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Made with ❤️ by Team Celeste")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
            }

            Section("Open Source") {
                Text("WiiUlator is open source and developed by Team Celeste.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
