import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("WiiUlator") {
                    Label("Games", systemImage: "gamecontroller")
                    Label("Recent Games", systemImage: "clock")
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Section("Settings") {
                    Label("Graphics", systemImage: "display")
                    Label("Controls", systemImage: "gamecontroller.fill")
                    Label("Audio", systemImage: "speaker.wave.2")
                    Label("System", systemImage: "gearshape")
                }
            }
            .navigationTitle("WiiUlator")
        }
    }
}

#Preview {
    ContentView()
}
