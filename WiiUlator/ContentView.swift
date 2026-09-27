import SwiftUI
import UIKit
import Darwin
import UniformTypeIdentifiers
import Darwin

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
                        GameIconView()
                            .frame(width: 64, height: 64)

                        VStack(alignment: .leading, spacing: 4) {
                            LabeledContent("Name", value: "Mario Kart 8")
                            LabeledContent("Provider", value: "Nintendo")
                            LabeledContent("Version", value: "1.0")
                        }
                        .font(.subheadline)
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

struct GameIconView: View {
    private let iconURL = URL(string: "https://art.gametdb.com/wiiu/icon/US/AMKE01.png")!

    var body: some View {
        AsyncImage(url: iconURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                RoundedRectangle(cornerRadius: 10)
                    .fill(.secondary.opacity(0.18))
                    .overlay {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.secondary.opacity(0.18), lineWidth: 1)
        }
    }
}

struct DemoGameView: View {
    @State private var showingControls = true

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if showingControls {
                SimpleTouchControls()
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
                            .foregroundStyle(.white.opacity(0.82))
                            .frame(width: 34, height: 34)
                            .background(.black.opacity(0.42), in: Circle())
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
        .onAppear {
            LandscapeGameSession.begin()
        }
        .onDisappear {
            LandscapeGameSession.end()
        }
    }
}

private enum LandscapeGameSession {
    static func begin() {
        OrientationController.lockLandscape()
        hideBottomBar()
    }

    static func end() {
        OrientationController.unlock()
        showBottomBar()
    }

    private static func hideBottomBar() {
        let selector = NSSelectorFromString("setTabBarHidden:animated:")
        guard let tabBar = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.tabBarController,
              tabBar.responds(to: selector) else { return }

        _ = tabBar.perform(selector, with: true, with: false)
    }

    private static func showBottomBar() {
        let selector = NSSelectorFromString("setTabBarHidden:animated:")
        guard let tabBar = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.tabBarController,
              tabBar.responds(to: selector) else { return }

        _ = tabBar.perform(selector, with: false, with: false)
    }
}

private enum OrientationController {
    static func lockLandscape() {
        if #available(iOS 16.0, *) {
            let mask: UIInterfaceOrientationMask = .landscape
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .forEach { scene in
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
                }
        }
    }

    static func unlock() {
        if #available(iOS 16.0, *) {
            let mask: UIInterfaceOrientationMask = .all
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .forEach { scene in
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
                }
        }
    }
}

struct SimpleTouchControls: View {
    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 700
            let buttonSize = compact ? CGFloat(40) : CGFloat(48)
            let stickSize = compact ? CGFloat(70) : CGFloat(82)

            ZStack {
                VStack {
                    HStack {
                        SimpleShoulderButton(title: "ZL")
                        Spacer()
                        SimpleShoulderButton(title: "ZR")
                    }
                    .padding(.horizontal, compact ? 18 : 28)
                    .padding(.top, compact ? 22 : 34)

                    Spacer()
                }

                HStack(alignment: .bottom) {
                    SimpleStick(size: stickSize)

                    Spacer()

                    SimpleDiamondButtons(size: buttonSize)
                }
                .padding(.horizontal, compact ? 20 : 32)
                .padding(.bottom, compact ? 20 : 30)

                VStack {
                    Spacer()
                    HStack {
                        SimpleDPad(size: buttonSize)
                        Spacer()
                    }
                    .padding(.leading, compact ? 20 : 32)
                    .padding(.bottom, compact ? 22 : 34)
                }
            }
        }
        .allowsHitTesting(true)
    }
}

struct SimpleStick: View {
    let size: CGFloat
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Circle()
            .fill(.white.opacity(0.10))
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
            .overlay {
                Circle()
                    .fill(.white.opacity(0.18))
                    .frame(width: size * 0.52, height: size * 0.52)
                    .offset(dragOffset)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let limit = size * 0.22
                        let x = max(-limit, min(limit, value.translation.width))
                        let y = max(-limit, min(limit, value.translation.height))
                        dragOffset = CGSize(width: x, height: y)
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.12)) {
                            dragOffset = .zero
                        }
                    }
            )
    }
}

struct SimpleDPad: View {
    let size: CGFloat
    @State private var pressed = false

    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: size * 0.72, weight: .semibold))
            .foregroundStyle(.white.opacity(0.32))
            .frame(width: size, height: size)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .scaleEffect(pressed ? 0.92 : 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

struct SimpleDiamondButtons: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            SimpleFaceButton(title: "X", size: size)
                .offset(y: -size * 0.58)

            SimpleFaceButton(title: "Y", size: size)
                .offset(x: -size * 0.58)

            SimpleFaceButton(title: "A", size: size)
                .offset(x: size * 0.58)

            SimpleFaceButton(title: "B", size: size)
                .offset(y: size * 0.58)
        }
        .frame(width: size * 2.35, height: size * 2.35)
    }
}

struct SimpleFaceButton: View {
    let title: String
    let size: CGFloat
    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.70))
            .frame(width: size, height: size)
            .background(.white.opacity(0.10), in: Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            }
            .scaleEffect(pressed ? 0.90 : 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressed = true }
                    .onEnded { _ in pressed = false }
            )
    }
}

struct SimpleShoulderButton: View {
    let title: String
    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.62))
            .frame(width: 48, height: 28)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.18), lineWidth: 1)
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
    private var deviceInfo: DeviceInfo {
        DeviceInfo.current
    }

    var body: some View {
        List {
            Section("WiiUlator") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Platform", value: "iOS & iPadOS")
                LabeledContent("Minimum iOS", value: "16.0")
            }

            Section("This Device") {
                LabeledContent("Device", value: deviceInfo.name)
                LabeledContent("Chip", value: deviceInfo.chip)
                LabeledContent("OS", value: deviceInfo.osVersion)
                LabeledContent("Architecture", value: deviceInfo.architecture)
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

            Section("Game Artwork") {
                Text("Wii U game artwork can be sourced from GameTDB. Wii U title pages provide the game metadata and artwork database.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

private struct DeviceInfo {
    let name: String
    let chip: String
    let osVersion: String
    let architecture: String

    static var current: DeviceInfo {
        let identifier = hardwareIdentifier()

        let name: String
        let chip: String

        switch identifier {
        case "iPhone14,5":
            name = "iPhone 13"
            chip = "Apple A15 Bionic"
        case "iPhone14,2":
            name = "iPhone 13 Pro"
            chip = "Apple A15 Bionic"
        case "iPhone14,3":
            name = "iPhone 13 Pro Max"
            chip = "Apple A15 Bionic"
        case "iPhone14,4":
            name = "iPhone 13 mini"
            chip = "Apple A15 Bionic"
        default:
            name = UIDevice.current.model
            chip = "Apple Silicon"
        }

        let version = UIDevice.current.systemVersion
        let architecture = MemoryLayout<Int>.size == 8 ? "ARM64" : "ARM"

        return DeviceInfo(
            name: name,
            chip: chip,
            osVersion: "\(UIDevice.current.systemName) \(version)",
            architecture: architecture
        )
    }

    private static func hardwareIdentifier() -> String {
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)

        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)

        return String(cString: machine)
    }
}

#Preview {
    ContentView()
}
