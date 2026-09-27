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
    @State private var showingControls = true

    var body: some View {
        ZStack {
            EmulatorScene()

            if showingControls {
                TouchControls()
                    .transition(.opacity)
            }

            VStack {
                HStack {
                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showingControls.toggle()
                        }
                    } label: {
                        Image(systemName: showingControls ? "gamecontroller.fill" : "gamecontroller")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(.black.opacity(0.38), in: Circle())
                    }
                    .padding(12)
                }

                Spacer()
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

struct EmulatorScene: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.16, blue: 0.25),
                        Color(red: 0.12, green: 0.31, blue: 0.28),
                        Color(red: 0.03, green: 0.08, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Rectangle()
                    .fill(.black.opacity(0.18))
                    .frame(height: proxy.size.height * 0.34)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.25)

                VStack {
                    Spacer()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MARIO KART 8")
                                .font(.system(size: 17, weight: .heavy, design: .rounded))
                            Text("1st   •   3 / 3 LAPS")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .opacity(0.82)
                        }
                        .foregroundStyle(.white)

                        Spacer()

                        Text("03:21.842")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }

                VStack(spacing: 8) {
                    Text("Wii U")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))

                    Text("GAME RENDERER DEMO")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
        }
    }
}

struct TouchControls: View {
    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 700
            let button = compact ? CGFloat(46) : CGFloat(58)
            let stick = compact ? CGFloat(74) : CGFloat(92)

            ZStack {
                VStack {
                    Spacer()

                    HStack(alignment: .bottom) {
                        VStack(spacing: compact ? 16 : 22) {
                            TouchStick(size: stick)
                            TouchDPad(size: button)
                        }

                        Spacer()

                        TouchGamePadScreen()
                            .frame(
                                width: compact ? 112 : 150,
                                height: compact ? 70 : 92
                            )

                        Spacer()

                        TouchFaceButtons(size: button)
                    }
                    .padding(.horizontal, compact ? 18 : 32)
                    .padding(.bottom, compact ? 18 : 30)
                }

                VStack {
                    HStack {
                        TouchShoulderButton(title: "ZL")
                        Spacer()
                        TouchShoulderButton(title: "ZR")
                    }
                    .padding(.horizontal, compact ? 22 : 38)
                    .padding(.top, compact ? 30 : 48)

                    Spacer()
                }
            }
        }
        .allowsHitTesting(true)
    }
}

struct TouchStick: View {
    let size: CGFloat
    @State private var pressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.30))
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                }

            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: size * 0.56, height: size * 0.56)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.32), lineWidth: 1)
                }
                .scaleEffect(pressed ? 0.9 : 1)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: size * 0.32, height: size * 0.32)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

struct TouchDPad: View {
    let size: CGFloat
    @State private var pressed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7)
                .fill(.black.opacity(0.30))
                .frame(width: size * 0.38, height: size)

            RoundedRectangle(cornerRadius: 7)
                .fill(.black.opacity(0.30))
                .frame(width: size, height: size * 0.38)

            Image(systemName: "plus")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(.white.opacity(0.42))
        }
        .scaleEffect(pressed ? 0.94 : 1)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

struct TouchFaceButtons: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            TouchFaceButton(title: "X", offset: CGSize(width: 0, height: -size * 0.55))
            TouchFaceButton(title: "Y", offset: CGSize(width: -size * 0.55, height: 0))
            TouchFaceButton(title: "A", offset: CGSize(width: size * 0.55, height: 0))
            TouchFaceButton(title: "B", offset: CGSize(width: 0, height: size * 0.55))
        }
        .frame(width: size * 2.2, height: size * 2.2)
    }
}

struct TouchFaceButton: View {
    let title: String
    let offset: CGSize
    @State private var pressed = false

    var body: some View {
        Circle()
            .fill(.black.opacity(0.34))
            .frame(width: 38, height: 38)
            .overlay {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
            .offset(offset)
            .scaleEffect(pressed ? 0.9 : 1)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

struct TouchGamePadScreen: View {
    @State private var pressed = false

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.black.opacity(0.42))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            }
            .overlay {
                VStack(spacing: 5) {
                    Image(systemName: "rectangle.and.hand.point.up.left")
                        .font(.system(size: 17))
                    Text("GAMEPAD")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.58))
            }
            .scaleEffect(pressed ? 0.96 : 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

struct TouchShoulderButton: View {
    let title: String
    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.65))
            .frame(width: 52, height: 30)
            .background(.black.opacity(0.28), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            }
            .scaleEffect(pressed ? 0.92 : 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
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
    @AppStorage("gameResolution") private var gameResolution = "Native"
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

            Section("Game Resolution") {
                Picker("Resolution", selection: $gameResolution) {
                    Text("Native").tag("Native")
                    Text("1280 × 720").tag("1280x720")
                    Text("1600 × 900").tag("1600x900")
                    Text("1920 × 1080").tag("1920x1080")
                    Text("2560 × 1440").tag("2560x1440")
                }

                Text("This controls the internal emulated render resolution. It does not change the iPhone's physical display resolution.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
