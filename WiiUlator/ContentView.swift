import SwiftUI
import UIKit
import Darwin
import UniformTypeIdentifiers


private enum WiiUFileTypes {
    static let zip = UTType(filenameExtension: "zip") ?? .data
    static let wua = UTType(filenameExtension: "wua") ?? .data
    static let wud = UTType(filenameExtension: "wud") ?? .data
    static let wux = UTType(filenameExtension: "wux") ?? .data
    static let rpx = UTType(filenameExtension: "rpx") ?? .data
    static let elf = UTType(filenameExtension: "elf") ?? .data

    static let supported: [UTType] = [zip, wua, wud, wux, rpx, elf]
}

private enum WiiUlatorBuildInfo {
    static let version = "1.0"
    static let identifier = "26W002"
}

struct ContentView: View {
    @State private var selectedTab: Tab = .library
    @AppStorage("appLanguage") private var appLanguage = ""

    enum Tab {
        case library
        case favorites
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2")
                }
                .tag(Tab.library)

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
                .tag(Tab.favorites)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .environment(\.locale, appLanguage.isEmpty ? Locale.current : Locale(identifier: appLanguage))
    }
}

struct LibraryView: View {
    @StateObject private var library = GameLibraryStore.shared
    @State private var selectedGameID: UUID?
    @State private var showingImporter = false
    @State private var searchText = ""

    private var filteredGames: [LibraryGame] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return library.games }
        return library.games.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.provider.localizedCaseInsensitiveContains(query) ||
            $0.version.localizedCaseInsensitiveContains(query)
        }
    }

    private var selectedGame: LibraryGame? {
        guard !filteredGames.isEmpty else { return nil }
        if let selectedGameID,
           let game = filteredGames.first(where: { $0.id == selectedGameID }) {
            return game
        }
        return filteredGames.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let selectedGame {
                    ScrollView {
                        VStack(spacing: 0) {
                            if filteredGames.count > 1 {
                                Text("Swipe to browse games")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                    .padding(.bottom, 10)
                            }

                            LibraryCarouselView(
                                games: filteredGames,
                                selectedGameID: $selectedGameID,
                                isFavorite: { library.isFavorite($0) },
                                onFavorite: { library.toggleFavorite($0) }
                            )
                            .frame(height: 500)
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: searchText.isEmpty ? "gamecontroller" : "magnifyingglass")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)

                        Text(searchText.isEmpty ? "No Games" : "No Results")
                            .font(.headline)

                        Text(searchText.isEmpty ? "Import Wii U homebrew to get started." : "Try a different search.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("Library")
            .searchable(text: $searchText, prompt: "Search games")
            .navigationBarItems(
                leading: Button {
                    showingImporter = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Import Game")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let selectedGame {
                        Button {
                            library.toggleFavorite(selectedGame)
                        } label: {
                            Image(systemName: library.isFavorite(selectedGame) ? "star.fill" : "star")
                        }
                        .accessibilityLabel(library.isFavorite(selectedGame) ? "Remove from Favorites" : "Add to Favorites")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: WiiUFileTypes.supported,
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
                if selectedGameID == nil {
                    selectedGameID = library.games.first?.id
                }
            }
            .onChange(of: library.games) { games in
                if let selectedGameID, games.contains(where: { $0.id == selectedGameID }) {
                    return
                }
                self.selectedGameID = games.first?.id
            }
        }
    }
}

private struct LibraryCarouselView: View {
    let games: [LibraryGame]
    @Binding var selectedGameID: UUID?
    let isFavorite: (LibraryGame) -> Bool
    let onFavorite: (LibraryGame) -> Void

    @State private var currentIndex = 0
    @State private var scrollTarget: UUID?
    @GestureState private var dragOffset: CGFloat = 0

    private let cardWidth: CGFloat = 285
    private let slotSpacing: CGFloat = 18

    private var selectedIndex: Int {
        guard let selectedGameID,
              let index = games.firstIndex(where: { $0.id == selectedGameID }) else {
            return min(currentIndex, max(games.count - 1, 0))
        }
        return index
    }

    var body: some View {
        GeometryReader { proxy in
            let sideInset = max((proxy.size.width - cardWidth) / 2, 18)

            ZStack(alignment: .top) {
                ScrollViewReader { reader in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: slotSpacing) {
                            ForEach(games) { game in
                                let index = games.firstIndex(of: game) ?? 0
                                let isSelected = index == selectedIndex

                                VStack(spacing: 0) {
                                    GameCoverView(game: game)
                                        .frame(width: cardWidth, height: cardWidth)
                                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                        .scaleEffect(isSelected ? 1.0 : 0.62)
                                        .shadow(
                                            color: .black.opacity(isSelected ? 0.18 : 0.10),
                                            radius: isSelected ? 18 : 8,
                                            y: isSelected ? 10 : 5
                                        )
                                }
                                .frame(width: cardWidth, height: 405, alignment: .top)
                                .id(game.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    select(index, reader: reader)
                                }
                            }
                        }
                        .padding(.horizontal, sideInset)
                    }
                    .scrollDisabled(true)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 12)
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                let threshold = cardWidth * 0.18
                                var next = selectedIndex

                                if value.translation.width < -threshold {
                                    next = min(selectedIndex + 1, games.count - 1)
                                } else if value.translation.width > threshold {
                                    next = max(selectedIndex - 1, 0)
                                }

                                withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.86)) {
                                    currentIndex = next
                                    selectedGameID = games[next].id
                                    reader.scrollTo(games[next].id, anchor: .center)
                                }
                            }
                    )
                    .onAppear {
                        guard let game = games[safe: selectedIndex] else { return }
                        DispatchQueue.main.async {
                            reader.scrollTo(game.id, anchor: .center)
                        }
                    }
                    .onChange(of: selectedGameID) { newValue in
                        guard let newValue else { return }
                        if let index = games.firstIndex(where: { $0.id == newValue }) {
                            currentIndex = index
                            withAnimation(.easeOut(duration: 0.22)) {
                                reader.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }

                if let selectedGame = games[safe: selectedIndex] {
                    GameCoverView(game: selectedGame)
                        .frame(width: cardWidth, height: cardWidth)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .scaleEffect(x: 1, y: -1)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.72), location: 0),
                                    .init(color: .white.opacity(0.22), location: 0.10),
                                    .init(color: .white.opacity(0.05), location: 0.28),
                                    .init(color: .clear, location: 0.48)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: cardWidth + 15)
                        .allowsHitTesting(false)
                }

                if let selectedGame = games[safe: selectedIndex] {
                    VStack(spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 7) {
                            Text(selectedGame.name)
                                .font(.title3.weight(.bold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)

                            if isFavorite(selectedGame) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }

                        Text(selectedGame.provider)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if !selectedGame.version.isEmpty {
                            Text("Version \(selectedGame.version)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        if let titleID = selectedGame.titleID, !titleID.isEmpty {
                            Text(titleID)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                        }

                        HStack(spacing: 10) {
                            NavigationLink {
                                DemoGameView(game: selectedGame)
                            } label: {
                                Label("Launch", systemImage: "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .stroke(.tint.opacity(0.28), lineWidth: 1)
                                    }
                            }
                            .foregroundStyle(.tint)
                            .buttonStyle(.plain)
                            .disabled(selectedGame.isDemo)

                            Button {
                                onFavorite(selectedGame)
                            } label: {
                                Image(systemName: isFavorite(selectedGame) ? "star.fill" : "star")
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 5)
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .background(.clear)
                    .offset(y: 300)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            if let index = games.firstIndex(where: { $0.id == selectedGameID }) {
                currentIndex = index
            } else if !games.isEmpty {
                currentIndex = 0
                selectedGameID = games[0].id
            }
        }
    }

    private func select(_ index: Int, reader: ScrollViewProxy) {
        guard games.indices.contains(index) else { return }
        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.86)) {
            currentIndex = index
            selectedGameID = games[index].id
            reader.scrollTo(games[index].id, anchor: .center)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private struct GameCoverView: View {
    let game: LibraryGame

    var body: some View {
        ZStack {
            if let coverURL = game.coverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.88), .black.opacity(0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 10) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(game.name)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 20)
            }
        }
    }
}

struct FavoritesView: View {
    @StateObject private var library = GameLibraryStore.shared
    @State private var searchText = ""

    private var favoriteGames: [LibraryGame] {
        let favorites = library.games.filter { library.isFavorite($0) }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return favorites }
        return favorites.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.provider.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteGames.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: searchText.isEmpty ? "star" : "magnifyingglass")
                            .font(.system(size: 34))
                            .foregroundStyle(.secondary)

                        Text(searchText.isEmpty ? "No Favorites" : "No Results")
                            .font(.headline)

                        Text(searchText.isEmpty ? "Favourite games will appear here." : "Try a different search.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(favoriteGames) { game in
                            HStack(spacing: 12) {
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
                                        }
                                    }
                                }

                                Button {
                                    library.toggleFavorite(game)
                                } label: {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove from Favorites")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .searchable(text: $searchText, prompt: "Search favorites")
        }
    }
}

struct GameIconView: View {
    let game: LibraryGame

    private var iconURL: URL? {
        guard let titleID = game.titleID, !titleID.isEmpty else { return nil }
        return URL(string: "https://art.gametdb.com/wiiu/icon/US/\(titleID).png")
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
    @StateObject private var session = EmulatorSession()
    @AppStorage("debugOverlayEnabled") private var debugOverlayEnabled = false
    @Environment(\.dismiss) private var dismiss
    @State private var showingControls = true
    @State private var showingStopConfirmation = false
    @State private var showingRuntimeMenu = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            EmulatorVideoView(session: session)

            if showingControls {
                SimpleTouchControls(gamePad: session.core.gamePad)
                    .transition(.opacity)
            }

            if debugOverlayEnabled {
                EmulatorDebugOverlay(session: session)
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
                        showingRuntimeMenu = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
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
            "Emulation",
            isPresented: $showingRuntimeMenu,
            titleVisibility: .visible
        ) {
            if session.state == .running {
                Button("Pause") {
                    session.pause()
                }
            } else if session.state == .paused || session.state == .ready {
                Button("Resume") {
                    session.start()
                }
            }

            Button("Stop", role: .destructive) {
                showingStopConfirmation = true
            }

            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Stop emulation?",
            isPresented: $showingStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Stop", role: .destructive) {
                session.stop()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            LandscapeGameSession.begin()
            bootGame()
        }
        .onDisappear {
            session.stop()
            LandscapeGameSession.end()
        }
    }

    private func bootGame() {
        let sourceURL = URL(fileURLWithPath: game.path)
        let executableURL: URL

        if sourceURL.hasDirectoryPath {
            guard let found = findExecutable(in: sourceURL) else {
                return
            }
            executableURL = found
        } else {
            let ext = sourceURL.pathExtension.lowercased()
            if ["zip", "wua", "wud", "wux"].contains(ext) {
                session.fail("This \(ext.uppercased()) container is imported, but container-backed launching is not implemented yet.")
                return
            }
            executableURL = sourceURL
        }

        session.boot(url: executableURL)

        if session.state == .ready {
            session.start()
        }
    }

    private func findExecutable(in directory: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let candidate as URL in enumerator {
            let ext = candidate.pathExtension.lowercased()
            if ext == "rpx" || ext == "elf" {
                return candidate
            }
        }

        return nil
    }
}

struct EmulatorVideoView: View {
    @ObservedObject var session: EmulatorSession
    @AppStorage("displayAspectRatio") private var displayAspectRatio = "16:9"

    private var isFailed: Bool {
        if case .failed = session.state {
            return true
        }
        return false
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
            GeometryReader { proxy in
                ZStack {
                    Color.black

                    VStack(spacing: 8) {
                    Image(systemName: isFailed ? "exclamationmark.triangle" : "gamecontroller")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.white.opacity(0.32))

                    Text(session.state.label)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.78))

                    if case .failed(let message) = session.state {
                        Text(message)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else if session.state == .running {
                        Text("PowerPC execution active")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    }
                    .aspectRatio(displayAspectRatio == "4:3" ? 4.0 / 3.0 : 16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                }
            }
            .onAppear {
                session.runFrame()
            }
            .onChange(of: session.state) { _ in
                session.runFrame()
            }
        }
        .ignoresSafeArea()
    }
}

struct EmulatorDebugOverlay: View {
    @ObservedObject var session: EmulatorSession

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("WiiUlator DEBUG")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            Text(String(format: "PC          %08X", session.programCounter))
            Text("State       \(session.state.label)")
            Text("Instructions \(session.instructionCount)")
            Text("CPU         PowerPC")
            Text("Renderer    Metal / pending")
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.white.opacity(0.82))
        .padding(8)
        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 8))
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
    let gamePad: WiiUGamePad
    @AppStorage("britishEnglishUnlocked") private var britishEnglishUnlocked = false
    @State private var lastButtonBits: UInt16 = 0
    @State private var codeIndex = 0
    @State private var showingBritishUnlock = false

    private let britishCode: [WiiUGamePadButton] = [
        .dpadUp, .dpadUp, .dpadDown, .dpadDown,
        .dpadLeft, .dpadRight, .dpadLeft, .dpadRight,
        .a, .b, .plus, .minus
    ]

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.width < 700
            let buttonSize = compact ? CGFloat(54) : CGFloat(62)
            let stickSize = compact ? CGFloat(78) : CGFloat(92)

            ZStack {
                VStack {
                    HStack {
                        SimpleShoulderButton(title: "ZL", button: .zl, gamePad: gamePad)
                        Spacer()
                        SimpleShoulderButton(title: "ZR", button: .zr, gamePad: gamePad)
                    }
                    .padding(.horizontal, compact ? 18 : 28)
                    .padding(.top, compact ? 22 : 34)

                    Spacer()
                }

                HStack(alignment: .bottom) {
                    SimpleStick(size: stickSize)

                    Spacer()

                    SimpleDiamondButtons(size: buttonSize, gamePad: gamePad)
                }
                .padding(.horizontal, compact ? 20 : 32)
                .padding(.bottom, compact ? 20 : 30)

                VStack {
                    Spacer()
                    HStack {
                        SimpleDPad(size: buttonSize, gamePad: gamePad)
                        Spacer()
                    }
                    .padding(.leading, compact ? 20 : 32)
                    .padding(.bottom, compact ? 22 : 34)
                }
            }
        }
        .allowsHitTesting(true)
        .onReceive(gamePad.$state) { state in
            guard !britishEnglishUnlocked else {
                lastButtonBits = state.buttons
                return
            }

            let newlyPressed = state.buttons & ~lastButtonBits
            lastButtonBits = state.buttons

            guard newlyPressed != 0 else { return }

            for expected in britishCode {
                if newlyPressed & expected.rawValue != 0 {
                    if expected == britishCode[codeIndex] {
                        codeIndex += 1

                        if codeIndex == britishCode.count {
                            britishEnglishUnlocked = true
                            codeIndex = 0
                            showingBritishUnlock = true
                        }
                    } else {
                        codeIndex = expected == britishCode[0] ? 1 : 0
                    }
                    break
                }
            }
        }
        .alert("English (UK) ☕ Unlocked", isPresented: $showingBritishUnlock) {
            Button("Brilliant") { }
        } message: {
            Text("I hereby declare that the aforementioned language option has been unlocked.")
        }
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
    let gamePad: WiiUGamePad

    var body: some View {
        ZStack {
            dpadButton("chevron.up", .dpadUp)
                .offset(y: -size * 0.27)
            dpadButton("chevron.down", .dpadDown)
                .offset(y: size * 0.27)
            dpadButton("chevron.left", .dpadLeft)
                .offset(x: -size * 0.27)
            dpadButton("chevron.right", .dpadRight)
                .offset(x: size * 0.27)
        }
        .frame(width: size * 1.45, height: size * 1.45)
    }

    private func dpadButton(_ icon: String, _ button: WiiUGamePadButton) -> some View {
        GamePadButton(gamePad: gamePad, button: button) {
            Image(systemName: icon)
                .font(.system(size: size * 0.22, weight: .bold))
        }
        .frame(width: size * 0.52, height: size * 0.52)
    }
}

struct SimpleDiamondButtons: View {
    let size: CGFloat
    let gamePad: WiiUGamePad

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(size), spacing: size * 0.12),
                GridItem(.fixed(size), spacing: size * 0.12)
            ],
            spacing: size * 0.12
        ) {
            SimpleFaceButton(title: "X", button: .x, size: size, gamePad: gamePad)
            SimpleFaceButton(title: "Y", button: .y, size: size, gamePad: gamePad)
            SimpleFaceButton(title: "A", button: .a, size: size, gamePad: gamePad)
            SimpleFaceButton(title: "B", button: .b, size: size, gamePad: gamePad)
        }
        .frame(width: size * 2.12, height: size * 2.12)
    }
}

struct SimpleFaceButton: View {
    let title: String
    let button: WiiUGamePadButton
    let size: CGFloat
    let gamePad: WiiUGamePad

    var body: some View {
        GamePadButton(gamePad: gamePad, button: button) {
            Text(title)
                .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
        }
        .frame(width: size * 0.88, height: size * 0.72)
    }
}

struct GamePadButton<Content: View>: View {
    let gamePad: WiiUGamePad
    let button: WiiUGamePadButton
    @ViewBuilder let content: () -> Content
    @State private var pressed = false

    var body: some View {
        content()
            .foregroundStyle(.white.opacity(pressed ? 0.9 : 0.70))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white.opacity(pressed ? 0.18 : 0.10), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            }
            .scaleEffect(pressed ? 0.90 : 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            gamePad.setButton(button, pressed: true)
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        gamePad.setButton(button, pressed: false)
                    }
            )
    }
}

struct SimpleShoulderButton: View {
    let title: String
    let button: WiiUGamePadButton
    let gamePad: WiiUGamePad
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
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            gamePad.setButton(button, pressed: true)
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        gamePad.setButton(button, pressed: false)
                    }
            )
    }
}

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = ""
    @AppStorage("britishEnglishUnlocked") private var britishEnglishUnlocked = false

    var body: some View {
        NavigationStack {
            List {
                Section("Language") {
                    Picker("Language", selection: $appLanguage) {
                        Text("System Language").tag("")
                        Text("Spanish").tag("es")
                        Text("Portuguese").tag("pt")
                        Text("Japanese").tag("ja")
                        Text("Chinese").tag("zh-Hans")
                        Text("French").tag("fr")

                        if britishEnglishUnlocked {
                            Text("English (UK) ☕").tag("en-GB")
                        }
                    }
                }

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

                    NavigationLink {
                        WiiUSystemUpdateView()
                    } label: {
                        Label("System Update", systemImage: "arrow.down.circle")
                    }
                }

                Section("Developer") {
                    NavigationLink {
                        DebugSettingsView()
                    } label: {
                        Label("Debugging", systemImage: "ladybug")
                    }
                }

                Section("Storage") {
                    NavigationLink {
                        GamesFolderView()
                    } label: {
                        Label("Games Folder", systemImage: "folder")
                    }
                }

                Section("Credits") {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: "https://github.com/doorsfan14.png")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(.secondary)
                                    .padding(3)
                            }
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())

                        Text("doorsfan14")
                            .font(.body)

                        Spacer()

                        Text("Main Developer")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 2)
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }

                    Button {
                        // Donation link will be connected when Team Celeste has a public support page.
                    } label: {
                        Label("Buy us a coffee", systemImage: "cup.and.saucer")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}



struct WiiUSystemUpdateView: View {
    @State private var region = "USA"
    @State private var status = "Not checked"
    @State private var isChecking = false
    @State private var availableTitles = 0
    @State private var latestVersions: [WiiUSystemUpdater.TitleVersion] = []

    private let regions = ["USA", "EUR", "JPN"]

    var body: some View {
        Form {
            Section("Wii U Region") {
                Picker("Region", selection: $region) {
                    ForEach(regions, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
            }

            Section("Nintendo Update Service") {
                Button {
                    checkForUpdate()
                } label: {
                    HStack {
                        Label("Check for Updates", systemImage: "arrow.down.circle")
                        Spacer()
                        if isChecking {
                            ProgressView()
                        }
                    }
                }
                .disabled(isChecking)

                LabeledContent("Source", value: "Nintendo Wii U NUS")
                LabeledContent("Build", value: WiiUlatorBuildInfo.identifier)
            }

            Section("Status") {
                LabeledContent("Region", value: region)
                LabeledContent("Result", value: status)

                if availableTitles > 0 {
                    LabeledContent("Title Entries", value: String(availableTitles))
                }
            }

            if !latestVersions.isEmpty {
                Section("Nintendo Title Versions") {
                    ForEach(latestVersions.prefix(12)) { title in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title.titleID)
                                .font(.system(.subheadline, design: .monospaced))
                            Text("Version \(title.version)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if latestVersions.count > 12 {
                        Text("\(latestVersions.count - 12) more title entries received.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text("Nintendo documents Wii U system updates as Internet-delivered updates, with version 5.5.6 U listed as the latest system-menu release. WiiUlator queries Nintendo's Wii U NUS service for update metadata. Proprietary system software is not bundled with WiiUlator and is not silently copied into the app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("System Update")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkForUpdate() {
        isChecking = true
        status = "Contacting Nintendo..."
        availableTitles = 0
        latestVersions = []

        Task {
            let result = await WiiUSystemUpdater.check(region: region)
            await MainActor.run {
                isChecking = false
                status = result.message
                availableTitles = result.titles.count
                latestVersions = result.titles
            }
        }
    }
}

private enum WiiUSystemUpdater {
    struct TitleVersion: Identifiable {
        let titleID: String
        let version: Int

        var id: String {
            "\(titleID)-\(version)"
        }
    }

    struct Result {
        let titles: [TitleVersion]
        let message: String
    }

    static func check(region: String) async -> Result {
        guard let url = URL(string: "https://nus.wup.shop.nintendo.net/nus/services/NetUpdateSOAP") else {
            return Result(titles: [], message: "Invalid Nintendo update service URL")
        }

        let countryCode: String
        switch region {
        case "EUR":
            countryCode = "EU"
        case "JPN":
            countryCode = "JP"
        default:
            countryCode = "US"
        }

        let messageID = UUID().uuidString
        let body = """
        <?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
          xmlns:xsd="http://www.w3.org/2001/XMLSchema"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <soapenv:Body>
            <GetSystemUpdateRequest xmlns="urn:nus.wsapi.broadon.com">
              <Version>1.0</Version>
              <MessageId>\(messageID)</MessageId>
              <DeviceId>0</DeviceId>
              <RegionId>\(region)</RegionId>
              <CountryCode>\(countryCode)</CountryCode>
              <Attribute>1</Attribute>
              <AuditData></AuditData>
            </GetSystemUpdateRequest>
          </soapenv:Body>
        </soapenv:Envelope>
        """

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("\"urn:nus.wsapi.broadon.com/GetSystemUpdate\"", forHTTPHeaderField: "SOAPAction")
        request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("EVL NUP 040800 Sep 18 2012 20:20:02", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                return Result(titles: [], message: "Invalid Nintendo server response")
            }

            guard (200..<300).contains(http.statusCode) else {
                return Result(titles: [], message: "Nintendo server returned HTTP \(http.statusCode)")
            }

            let xml = String(decoding: data, as: UTF8.self)
            let errorCode = firstTagValue("ErrorCode", in: xml)

            if let errorCode, errorCode != "0" {
                return Result(titles: [], message: "Nintendo NUS error \(errorCode)")
            }

            let titleIDs = allTagValues("TitleId", in: xml)
            let versions = allTagValues("Version", in: xml).dropFirst()

            let titles = zip(titleIDs, versions).compactMap { titleID, versionText -> TitleVersion? in
                guard let version = Int(versionText) else { return nil }
                return TitleVersion(titleID: titleID, version: version)
            }

            guard !titles.isEmpty else {
                return Result(titles: [], message: "Nintendo returned no system-title metadata")
            }

            return Result(
                titles: titles,
                message: "Nintendo update metadata received"
            )
        } catch {
            return Result(titles: [], message: "Connection to Nintendo NUS failed")
        }
    }

    private static func firstTagValue(_ tag: String, in xml: String) -> String? {
        let values = allTagValues(tag, in: xml)
        return values.first
    }

    private static func allTagValues(_ tag: String, in xml: String) -> [String] {
        let pattern = "<(?:[A-Za-z0-9_]+:)?\(tag)>(.*?)</(?:[A-Za-z0-9_]+:)?\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
        return regex.matches(in: xml, range: range).compactMap { match in
            guard let valueRange = Range(match.range(at: 1), in: xml) else {
                return nil
            }
            return String(xml[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
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
    @AppStorage("displayAspectRatio") private var displayAspectRatio = "16:9"
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

            Section("Display") {
                Picker("Aspect Ratio", selection: $displayAspectRatio) {
                    Text("16:9").tag("16:9")
                    Text("4:3").tag("4:3")
                }

                Text("Wii U games normally use 16:9. Select 4:3 for games or content designed for that display shape.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

private enum EmulatorMemoryPolicy {
    static let minimumMB = 512
    static let stepMB = 256

    static var physicalMemoryMB: Int {
        let bytes = ProcessInfo.processInfo.physicalMemory
        return max(minimumMB, Int(bytes / (1024 * 1024)))
    }

    static var maximumMB: Int {
        physicalMemoryMB
    }

    static var recommendedMB: Int {
        let total = physicalMemoryMB
        let reserved = total <= 4096 ? 1536 : 2048
        let available = max(minimumMB, total - reserved)
        let percentage = Int(Double(total) * (total <= 4096 ? 0.50 : 0.60))
        let recommended = min(available, percentage)
        return max(minimumMB, (recommended / stepMB) * stepMB)
    }

    static func clamped(_ value: Int) -> Int {
        let rounded = max(minimumMB, min(maximumMB, value))
        return (rounded / stepMB) * stepMB
    }

    static func format(_ megabytes: Int) -> String {
        if megabytes >= 1024 {
            let gigabytes = Double(megabytes) / 1024.0
            return gigabytes.rounded() == gigabytes
                ? String(format: "%.0f GB", gigabytes)
                : String(format: "%.1f GB", gigabytes)
        }
        return "\(megabytes) MB"
    }
}

struct SystemSettingsView: View {
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("confirmExit") private var confirmExit = true
    @AppStorage("maximumRAMMB") private var maximumRAMMB = EmulatorMemoryPolicy.recommendedMB
    @State private var showingRAMWarning = false
    @State private var isAdjustingRAM = false

    private var jitEnabled: Bool {
        JITStatus.isEnabled
    }

    private var ramValue: Binding<Double> {
        Binding(
            get: {
                Double(EmulatorMemoryPolicy.clamped(maximumRAMMB))
            },
            set: {
                maximumRAMMB = EmulatorMemoryPolicy.clamped(Int($0))
            }
        )
    }

    private var exceedsRecommendation: Bool {
        maximumRAMMB > EmulatorMemoryPolicy.recommendedMB
    }

    var body: some View {
        Form {
            Section("System") {
                Toggle("Auto Save", isOn: $autoSave)
                Toggle("Confirm Before Exit", isOn: $confirmExit)
            }

            Section("Memory") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Maximum RAM")
                        Spacer()
                        Text(EmulatorMemoryPolicy.format(maximumRAMMB))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(
                        value: ramValue,
                        in: Double(EmulatorMemoryPolicy.minimumMB)...Double(EmulatorMemoryPolicy.maximumMB),
                        step: Double(EmulatorMemoryPolicy.stepMB),
                        onEditingChanged: { editing in
                            isAdjustingRAM = editing
                        }
                    )
                    .accessibilityValue(EmulatorMemoryPolicy.format(maximumRAMMB))

                    HStack {
                        Text("512 MB")
                        Spacer()
                        Text(EmulatorMemoryPolicy.format(EmulatorMemoryPolicy.maximumMB))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                LabeledContent(
                    "Recommended",
                    value: EmulatorMemoryPolicy.format(EmulatorMemoryPolicy.recommendedMB)
                )

                Text("The recommendation is calculated from this device’s physical memory, leaving headroom for iOS and WiiUlator itself.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
        .onAppear {
            maximumRAMMB = EmulatorMemoryPolicy.clamped(maximumRAMMB)
        }
        .onChange(of: isAdjustingRAM) { adjusting in
            if !adjusting && maximumRAMMB > EmulatorMemoryPolicy.recommendedMB {
                showingRAMWarning = true
            }
        }
        .alert("High RAM Allocation", isPresented: $showingRAMWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Putting a higher RAM amount than your device’s recommended memory will most likely cause crashes and game instability.")
        }
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

struct WiiUGameMetadata {
    let name: String
    let provider: String
    let version: String
    let titleID: String?
}

enum WiiUGameMetadataService {
    static func lookup(gameCode: String) async -> WiiUGameMetadata? {
        guard gameCode.count == 6 else { return nil }
        guard let url = URL(string: "https://www.gametdb.com/WiiU/\(gameCode)") else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("WiiUlator/1.0", forHTTPHeaderField: "User-Agent")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode,
              let html = String(data: data, encoding: .utf8) else {
            return nil
        }

        let title = extractTableValue("title (EN)", from: html)
            ?? extractTableValue("title", from: html)
            ?? extractTitleFromHeading(html)
        let publisher = extractTableValue("publisher", from: html)
        let developer = extractTableValue("developer", from: html)
        let version = extractTableValue("version", from: html)

        guard let title, !title.isEmpty else { return nil }

        return WiiUGameMetadata(
            name: title,
            provider: publisher?.isEmpty == false ? publisher! : (developer?.isEmpty == false ? developer! : "GameTDB"),
            version: version ?? "",
            titleID: gameCode
        )
    }

    private static func extractTableValue(_ label: String, from html: String) -> String? {
        let escapedLabel = NSRegularExpression.escapedPattern(for: label)
        let patterns = [
            "(?is)<th[^>]*>\\s*\(escapedLabel)\\s*</th>\\s*<td[^>]*>\\s*(.*?)\\s*</td>",
            "(?is)<td[^>]*>\\s*\(escapedLabel)\\s*</td>\\s*<td[^>]*>\\s*(.*?)\\s*</td>"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            guard let match = regex.firstMatch(in: html, range: range),
                  let valueRange = Range(match.range(at: 1), in: html) else { continue }

            let raw = String(html[valueRange])
            let stripped = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            let decoded = stripped
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&nbsp;", with: " ")

            let value = decoded.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty { return value }
        }

        return nil
    }

    private static func extractTitleFromHeading(_ html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "(?is)<h1[^>]*>\\s*(.*?)\\s*</h1>") else { return nil }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let valueRange = Range(match.range(at: 1), in: html) else { return nil }

        let raw = String(html[valueRange])
        let stripped = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
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

    var coverURL: URL? {
        switch titleID {
        case "0005000010145D00":
            return URL(string: "https://www.mariowiki.com/Special:Redirect/file/Super_Mario_3D_World-menu_icon.png")
        case "000500001010EC00":
            return URL(string: "https://www.mariowiki.com/Special:Redirect/file/Mario_Kart_8-menu_icon.png")
        case "0005000010176A00":
            return URL(string: "https://www.mariowiki.com/Special:Redirect/file/Splatoon-menu_icon.png")
        default:
            return nil
        }
    }

    var coverStyle: Int {
        if isDemo {
            switch name {
            case "Super Mario 3D World": return 0
            case "Mario Kart 8": return 1
            default: return 2
            }
        }
        return abs(name.hashValue) % 3
    }

    var coverSymbol: String {
        if isDemo {
            switch name {
            case "Super Mario 3D World": return "star.fill"
            case "Mario Kart 8": return "car.fill"
            default: return "paintbrush.fill"
            }
        }
        return "gamecontroller.fill"
    }

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
    @Published private(set) var favoriteIDs: Set<UUID> = []

    private let favoritesKey = "wiiulator.library.favorites"

    static var gamesFolderURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("games", isDirectory: true)
    }

    private init() {
        load()
        loadFavorites()
        prepareGamesFolder()
        seedDemoGamesIfNeeded()
    }

    private func seedDemoGamesIfNeeded() {
        guard games.isEmpty else { return }

        games = [
            LibraryGame(
                name: "Super Mario 3D World",
                provider: "Nintendo",
                version: "1.0.0",
                titleID: "0005000010145D00",
                path: Self.gamesFolderURL.appendingPathComponent("Demo-Super-Mario-3D-World.rpx").path,
                isDemo: true
            ),
            LibraryGame(
                name: "Mario Kart 8",
                provider: "Nintendo",
                version: "1.0.0",
                titleID: "000500001010EC00",
                path: Self.gamesFolderURL.appendingPathComponent("Demo-Mario-Kart-8.rpx").path,
                isDemo: true
            ),
            LibraryGame(
                name: "Splatoon",
                provider: "Nintendo",
                version: "1.0.0",
                titleID: "0005000010176900",
                path: Self.gamesFolderURL.appendingPathComponent("Demo-Splatoon.rpx").path,
                isDemo: true
            )
        ]
        save()
    }

    func isFavorite(_ game: LibraryGame) -> Bool {
        favoriteIDs.contains(game.id)
    }

    func toggleFavorite(_ game: LibraryGame) {
        if favoriteIDs.contains(game.id) {
            favoriteIDs.remove(game.id)
        } else {
            favoriteIDs.insert(game.id)
        }
        saveFavorites()
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) else {
            favoriteIDs = []
            return
        }
        favoriteIDs = decoded
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteIDs) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
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

        let extensionName = url.pathExtension.lowercased()
        let isWiiUContainer = ["zip", "wua", "wud", "wux"].contains(extensionName)

        if !url.hasDirectoryPath && isWiiUContainer {
            importContainer(from: url, kind: extensionName)
            return
        }

        guard let executableURL = findWiiUExecutable(in: url),
              (try? WiiUExecutableLoader().inspect(url: executableURL)) != nil else {
            return
        }

        let destination = Self.gamesFolderURL.appendingPathComponent(url.lastPathComponent, isDirectory: url.hasDirectoryPath)
        var finalDestination = destination
        if FileManager.default.fileExists(atPath: finalDestination.path) {
            finalDestination = Self.gamesFolderURL.appendingPathComponent("\(UUID().uuidString)-\(url.lastPathComponent)", isDirectory: url.hasDirectoryPath)
        }

        do {
            try FileManager.default.copyItem(at: url, to: finalDestination)

            let importedExecutable = url.hasDirectoryPath
                ? finalDestination.appendingPathComponent(executableURL.pathComponents.dropFirst(url.pathComponents.count).joined(separator: "/"))
                : finalDestination

            let metadata = try WiiUExecutableLoader().inspect(url: importedExecutable)
            let displayName = url.deletingPathExtension().lastPathComponent

            let gameID = extractGameCode(from: importedExecutable) ?? extractGameCode(from: finalDestination)
            let game = LibraryGame(
                name: displayName.isEmpty ? url.lastPathComponent : displayName,
                provider: "Wii U Homebrew",
                version: "",
                titleID: gameID,
                path: finalDestination.path
            )

            _ = metadata
            games.append(game)
            save()

            if let gameID {
                enrichMetadata(for: game.id, gameCode: gameID)
            }
        } catch {
            try? FileManager.default.removeItem(at: finalDestination)
        }
    }

    private func extractGameCode(from url: URL) -> String? {
        let candidates: [URL] = [
            url.deletingLastPathComponent().appendingPathComponent("meta.xml"),
            url.deletingLastPathComponent().appendingPathComponent("meta").appendingPathComponent("meta.xml")
        ]

        for candidate in candidates where FileManager.default.fileExists(atPath: candidate.path) {
            guard let data = try? Data(contentsOf: candidate),
                  let xml = String(data: data, encoding: .utf8) else { continue }

            let patterns = [
                "<product_code>\\s*WUP-[A-Z]-([A-Z0-9]{4})\\s*</product_code>",
                "<game_id>\\s*([A-Z0-9]{6})\\s*</game_id>",
                "<title_id>\\s*([A-Z0-9]{6})\\s*</title_id>"
            ]

            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
                let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)
                if let match = regex.firstMatch(in: xml, range: range),
                   let valueRange = Range(match.range(at: 1), in: xml) {
                    let code = String(xml[valueRange]).uppercased()
                    if code.count == 6 {
                        return code
                    }
                }
            }
        }

        return nil
    }

    private func enrichMetadata(for gameID: UUID, gameCode: String) {
        Task { @MainActor in
            guard let metadata = await WiiUGameMetadataService.lookup(gameCode: gameCode),
                  let index = games.firstIndex(where: { $0.id == gameID }) else {
                return
            }

            games[index].name = metadata.name
            games[index].provider = metadata.provider
            games[index].version = metadata.version
            games[index].titleID = metadata.titleID
            save()
        }
    }

    private func importContainer(from url: URL, kind: String) {
        let destination = Self.gamesFolderURL.appendingPathComponent(url.lastPathComponent)
        var finalDestination = destination

        if FileManager.default.fileExists(atPath: finalDestination.path) {
            finalDestination = Self.gamesFolderURL.appendingPathComponent("\(UUID().uuidString)-\(url.lastPathComponent)")
        }

        do {
            try FileManager.default.copyItem(at: url, to: finalDestination)

            let formatName: String
            switch kind {
            case "zip":
                formatName = "ZIP archive"
            case "wua":
                formatName = "Wii U Archive"
            case "wud":
                formatName = "Wii U disc image"
            case "wux":
                formatName = "Wii U compressed disc image"
            default:
                formatName = "Wii U container"
            }

            let game = LibraryGame(
                name: url.deletingPathExtension().lastPathComponent,
                provider: formatName,
                version: "",
                titleID: nil,
                path: finalDestination.path
            )

            games.append(game)
            save()
        } catch {
            try? FileManager.default.removeItem(at: finalDestination)
        }
    }

    private func findWiiUExecutable(in url: URL) -> URL? {
        if !url.hasDirectoryPath {
            let ext = url.pathExtension.lowercased()
            return ext == "rpx" || ext == "elf" ? url : nil
        }

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let candidate as URL in enumerator {
            let ext = candidate.pathExtension.lowercased()
            if ext == "rpx" || ext == "elf" {
                return candidate
            }
        }

        return nil
    }

    func remove(at offsets: IndexSet, from visibleGames: [LibraryGame]) {
        for index in offsets {
            guard index < visibleGames.count else { continue }
            let game = visibleGames[index]
            if let storedIndex = games.firstIndex(where: { $0.id == game.id }) {
                let url = URL(fileURLWithPath: games[storedIndex].path)
                try? FileManager.default.removeItem(at: url)
                favoriteIDs.remove(game.id)
                games.remove(at: storedIndex)
            }
        }
        save()
        saveFavorites()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([LibraryGame].self, from: data) else {
            games = []
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
                LabeledContent("Version", value: WiiUlatorBuildInfo.version)
                LabeledContent("Build Identifier", value: WiiUlatorBuildInfo.identifier)
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
