import SwiftUI
import UIKit
import Darwin
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
    @StateObject private var library = GameLibraryStore.shared
    @State private var showingImporter = false
    @State private var searchText = ""

    private var filteredGames: [LibraryGame] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return library.games }
        return library.games.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.provider.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredGames.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Games" : "No Results",
                        systemImage: searchText.isEmpty ? "gamecontroller" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Import a Wii U game to get started." : "Try a different search.")
                    )
                } else {
                    List {
                        ForEach(filteredGames) { game in
                            NavigationLink {
                                DemoGameView(game: game)
                            } label: {
                                HStack(spacing: 12) {
                                    GameIconView(game: game)
                                        .frame(width: 64, height: 64)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(game.name)
                                            .font(.headline)

                                        LabeledContent("Provider", value: game.provider)
                                            .font(.subheadline)

                                        if !game.version.isEmpty {
                                            LabeledContent("Version", value: game.version)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            library.remove(at: offsets, from: filteredGames)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search games")
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
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        library.importGame(from: url)
                    }
                case .failure:
                    break
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Image(systemName: "folder")
                    Text("Games: games")
                    Spacer()
                    Text("\(library.games.count)")
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .onAppear {
                library.prepareGamesFolder()
            }
        }
    }
}

struct GameIconView: View {
    let game: LibraryGame

    private var iconURL: URL? {
        guard let titleID = game.titleID, !titleID.isEmpty else { return nil }
        return URL(string: "https://art.gametdb.com/wiiu/icon/US/\\(titleID).png")
    }

    var body: some View {
        Group {
            if let iconURL {
                AsyncImage(url: iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.secondary.opacity(0.18), lineWidth: 1)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.secondary.opacity(0.18))
            .overlay {
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(.secondary)
            }
    }
}

struct DemoGameView: View {
    let game: LibraryGame
    @AppStorage("debugOverlayEnabled") private var debugOverlayEnabled = false
    @Environment(\.dismiss) private var dismiss
    @State private var showingControls = true
    @State private var showingStopConfirmation = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if showingControls {
                SimpleTouchControls()
                    .transition(.opacity)
            }

            if debugOverlayEnabled {
                DebugOverlay()
                    .padding(.top, 10)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
            }

            VStack {
                HStack(spacing: 8) {
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

                    Button {
                        showingStopConfirmation = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.82))
                            .frame(width: 34, height: 34)
                            .background(.black.opacity(0.42), in: Circle())
                    }
                }
                .padding(12)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            "Are you sure you wanna stop the emulation?",
            isPresented: $showingStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                endEmulation()
            }
            Button("No", role: .cancel) { }
        }
        .onAppear {
            LandscapeGameSession.begin()
        }
        .onDisappear {
            LandscapeGameSession.end()
        }
    }

    private func endEmulation() {
        dismiss()
    }
}

private enum LandscapeGameSession {
    static func begin() {
        OrientationController.lockLandscape()
    }

    static func end() {
        OrientationController.unlock()
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
            let buttonSize = compact ? CGFloat(54) : CGFloat(62)
            let stickSize = compact ? CGFloat(78) : CGFloat(92)

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
        LazyVGrid(
            columns: [
                GridItem(.fixed(size), spacing: size * 0.12),
                GridItem(.fixed(size), spacing: size * 0.12)
            ],
            spacing: size * 0.12
        ) {
            SimpleFaceButton(title: "X", size: size)
            SimpleFaceButton(title: "Y", size: size)
            SimpleFaceButton(title: "A", size: size)
            SimpleFaceButton(title: "B", size: size)
        }
        .frame(width: size * 2.12, height: size * 2.12)
    }
}

struct SimpleFaceButton: View {
    let title: String
    let size: CGFloat
    @State private var pressed = false

    var body: some View {
        Text(title)
            .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.70))
            .frame(width: size * 0.88, height: size * 0.72)
            .background(.white.opacity(0.10), in: Capsule())
            .overlay {
                Capsule()
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

struct DebugSettingsView: View {
    @AppStorage("debugOverlayEnabled") private var debugOverlayEnabled = false
    @AppStorage("debugLoggingEnabled") private var debugLoggingEnabled = false

    var body: some View {
        Form {
            Section("Developer Tools") {
                Toggle("Performance Overlay", isOn: $debugOverlayEnabled)
                Toggle("Debug Logging", isOn: $debugLoggingEnabled)
            }

            Section("Overlay") {
                LabeledContent("Display FPS", value: "Live")
                LabeledContent("Emulation Speed", value: "100%")
                LabeledContent("Frame Time", value: "Live")
                LabeledContent("Renderer", value: "Metal")
                LabeledContent("CPU", value: "ARM64")
                LabeledContent("JIT Support", value: JITStatus.isEnabled ? "Available" : "Unavailable")
            }

            Section {
                Text("The performance overlay appears over the game while emulating. Metrics become emulator-backed as the CPU, GPU, audio, and frame scheduler are implemented.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Debugging")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DebugOverlay: View {
    @State private var displayFPS = 60.0
    @State private var frameTime = 16.67

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("WiiUlator DEBUG")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            Text(String(format: "Display FPS  %.1f", displayFPS))
            Text(String(format: "Frame Time   %.2f ms", frameTime))
            Text("Emulation    100.0%")
            Text("Renderer     Metal")
            Text("CPU          ARM64")
            Text(JITStatus.isEnabled ? "JIT          available" : "JIT          unavailable")
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.white)
        .padding(8)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                let fps = UIScreen.main.maximumFramesPerSecond > 0 ? Double(UIScreen.main.maximumFramesPerSecond) : 60
                displayFPS = fps
                frameTime = 1000.0 / fps
            }
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
    private var jitEnabled: Bool {
        JITStatus.isEnabled
    }

    var body: some View {
        Form {
            Section("System") {
                Toggle("Auto Save", isOn: $autoSave)
                Toggle("Confirm Before Exit", isOn: $confirmExit)
            }

            Section("JIT") {
                HStack {
                    Text("JIT")
                    Spacer()
                    Text(jitEnabled ? "• Enabled" : "• Not Enabled")
                        .foregroundStyle(jitEnabled ? .green : .red)
                }
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

struct GamesFolderView: View {
    private var gamesURL: URL { GameLibraryStore.gamesFolderURL }

    var body: some View {
        Form {
            Section("Location") {
                LabeledContent("Folder", value: "games")
                Text(gamesURL.path)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Section {
                Text("Imported games are copied into WiiUlator's app container at Documents/games. Game files are not included with WiiUlator.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Games Folder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            GameLibraryStore.shared.prepareGamesFolder()
        }
    }
}

struct LibraryGame: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var provider: String
    var version: String
    var titleID: String?
    var path: String
    var isDemo: Bool

    init(id: UUID = UUID(), name: String, provider: String = "Unknown", version: String = "", titleID: String? = nil, path: String, isDemo: Bool = false) {
        self.id = id
        self.name = name
        self.provider = provider
        self.version = version
        self.titleID = titleID
        self.path = path
        self.isDemo = isDemo
    }
}

@MainActor
final class GameLibraryStore: ObservableObject {
    static let shared = GameLibraryStore()
    private let key = "wiiulator.library.games"

    @Published private(set) var games: [LibraryGame] = []

    static var gamesFolderURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("games", isDirectory: true)
    }

    private init() {
        load()
        prepareGamesFolder()
    }

    func prepareGamesFolder() {
        try? FileManager.default.createDirectory(at: Self.gamesFolderURL, withIntermediateDirectories: true)
    }

    func importGame(from url: URL) {
        prepareGamesFolder()

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let destination = Self.gamesFolderURL.appendingPathComponent(url.lastPathComponent, isDirectory: true)
        var finalDestination = destination
        if FileManager.default.fileExists(atPath: finalDestination.path) {
            finalDestination = Self.gamesFolderURL.appendingPathComponent("\(UUID().uuidString)-\(url.lastPathComponent)", isDirectory: true)
        }

        do {
            try FileManager.default.copyItem(at: url, to: finalDestination)
            let displayName = url.deletingPathExtension().lastPathComponent
            let game = LibraryGame(
                name: displayName.isEmpty ? url.lastPathComponent : displayName,
                path: finalDestination.path
            )
            games.append(game)
            save()
        } catch {
            // Import failures are intentionally non-fatal; the library remains unchanged.
        }
    }

    func remove(at offsets: IndexSet, from visibleGames: [LibraryGame]) {
        for index in offsets {
            guard index < visibleGames.count else { continue }
            let game = visibleGames[index]
            if let storedIndex = games.firstIndex(where: { $0.id == game.id }) {
                let url = URL(fileURLWithPath: games[storedIndex].path)
                try? FileManager.default.removeItem(at: url)
                games.remove(at: storedIndex)
            }
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([LibraryGame].self, from: data) else {
            games = [
                LibraryGame(
                    name: "Mario Kart 8",
                    provider: "Nintendo",
                    version: "1.0",
                    titleID: "AMKE01",
                    path: Self.gamesFolderURL.appendingPathComponent("Demo-Mario-Kart-8").path,
                    isDemo: true
                )
            ]
            save()
            return
        }
        games = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: key)
        }
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
                Text("WiiUlator uses GameTDB-compatible square Wii U artwork when a title ID is available. Imported games without recognized metadata use a local placeholder until game metadata parsing is implemented.")
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

private enum JITStatus {
    static var isEnabled: Bool {
        let pageSize = Int(getpagesize())
        let memory = mmap(
            nil,
            pageSize,
            PROT_READ | PROT_WRITE | PROT_EXEC,
            MAP_PRIVATE | MAP_ANON | MAP_JIT,
            -1,
            0
        )

        guard memory != MAP_FAILED else {
            return false
        }

        munmap(memory, pageSize)
        return true
    }
}

#Preview {
    ContentView()
}
