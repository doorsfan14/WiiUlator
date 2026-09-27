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
            List {
                NavigationLink {
                    DemoGameView()
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.gradient)
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Mario Kart 8")
                                .font(.headline)

                            Text("GamePad Overlay Demo")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
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
            .safeAreaInset(edge: .bottom) {
                Text("Demo entry — no game files are included with WiiUlator.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            }
        }
    }
}

struct DemoGameView: View {
    @State private var showingGamePad = true

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    GameDisplay()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .ignoresSafeArea()

                    if showingGamePad {
                        GamePadOverlay()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }

                    VStack {
                        HStack {
                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingGamePad.toggle()
                                }
                            } label: {
                                Image(systemName: showingGamePad ? "gamecontroller.fill" : "gamecontroller")
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(.black.opacity(0.55), in: Circle())
                            }
                            .foregroundStyle(.white)
                            .padding()
                        }

                        Spacer()
                    }
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

struct GameDisplay: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue, .purple, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 64))

                Text("MARIO KART 8")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))

                Text("Wii U emulator display")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
        }
    }
}

struct GamePadOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 700
            let scale = min(proxy.size.width / 1024, proxy.size.height / 768)
            let padWidth = min(proxy.size.width * 0.92, 920 * scale)
            let padHeight = padWidth * 0.42

            VStack {
                Spacer()

                WiiUGamePadSurface(compact: compact)
                    .frame(width: padWidth, height: padHeight)
                    .shadow(radius: 18)
                    .padding(.bottom, compact ? 12 : 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(true)
    }
}

struct WiiUGamePadSurface: View {
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let screenWidth = w * (compact ? 0.32 : 0.34)

            ZStack {
                RoundedRectangle(cornerRadius: h * 0.20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.98), .gray.opacity(0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: h * 0.20, style: .continuous)
                    .stroke(.black.opacity(0.35), lineWidth: 2)

                HStack(spacing: 0) {
                    GamePadControlsLeft(compact: compact)
                        .frame(width: (w - screenWidth) / 2)

                    RoundedRectangle(cornerRadius: h * 0.08)
                        .fill(.black)
                        .frame(width: screenWidth, height: h * 0.72)
                        .overlay {
                            RoundedRectangle(cornerRadius: h * 0.08)
                                .stroke(.gray.opacity(0.7), lineWidth: 2)

                            VStack(spacing: 4) {
                                Text("Wii U")
                                    .font(.system(size: max(9, h * 0.075), weight: .semibold, design: .rounded))
                                Text("GAMEPAD")
                                    .font(.system(size: max(7, h * 0.045), weight: .medium))
                                    .foregroundStyle(.gray)
                            }
                            .foregroundStyle(.white)
                        }

                    GamePadControlsRight(compact: compact)
                        .frame(width: (w - screenWidth) / 2)
                }
                .padding(.horizontal, w * 0.025)
            }
        }
    }
}

struct GamePadControlsLeft: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 8 : 18) {
            GamePadStick(label: "L", size: compact ? 46 : 58)

            GamePadDPad(size: compact ? 40 : 52)
        }
    }
}

struct GamePadControlsRight: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 8 : 18) {
            GamePadButtons(size: compact ? 34 : 46)

            GamePadStick(label: "R", size: compact ? 46 : 58)
        }
    }
}

struct GamePadStick: View {
    let label: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.78))
                    .frame(width: size, height: size)

                Circle()
                    .fill(.gray.opacity(0.55))
                    .frame(width: size * 0.72, height: size * 0.72)

                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .frame(width: size * 0.72, height: size * 0.72)
            }

            Text(label)
                .font(.system(size: max(8, size * 0.18), weight: .semibold))
                .foregroundStyle(.black.opacity(0.6))
        }
    }
}

struct GamePadDPad: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(.black.opacity(0.82))
                .frame(width: size * 0.34, height: size)

            RoundedRectangle(cornerRadius: 5)
                .fill(.black.opacity(0.82))
                .frame(width: size, height: size * 0.34)
        }
        .overlay {
            Image(systemName: "plus")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(.white.opacity(0.18))
        }
    }
}

struct GamePadButtons: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            GamePadFaceButton("X", x: 0, y: -size * 0.72)
            GamePadFaceButton("Y", x: -size * 0.72, y: 0)
            GamePadFaceButton("A", x: size * 0.72, y: 0)
            GamePadFaceButton("B", x: 0, y: size * 0.72)
        }
        .frame(width: size * 2.3, height: size * 2.3)
    }
}

struct GamePadFaceButton: View {
    let title: String
    let x: CGFloat
    let y: CGFloat

    init(_ title: String, x: CGFloat, y: CGFloat) {
        self.title = title
        self.x = x
        self.y = y
    }

    var body: some View {
        Circle()
            .fill(.black.opacity(0.82))
            .frame(width: 30, height: 30)
            .overlay {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .offset(x: x, y: y)
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
                    }

                    NavigationLink {
                        ControlsSettingsView()
                    } label: {
                        Label("Controls", systemImage: "gamecontroller.fill")
                    }

                    NavigationLink {
                        AudioSettingsView()
                    } label: {
                        Label("Audio", systemImage: "speaker.wave.2")
                    }

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
