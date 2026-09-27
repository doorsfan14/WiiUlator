import Foundation
import Combine

struct EmulatorProgram {
    let entryPoint: UInt32
    let imageAddress: UInt32
    let imageSize: Int
}

enum EmulatorState: Equatable {
    case stopped
    case ready
    case running
    case paused
    case failed(String)

    var label: String {
        switch self {
        case .stopped: return "Stopped"
        case .ready: return "Ready"
        case .running: return "Running"
        case .paused: return "Paused"
        case .failed(let message): return message
        }
    }
}

final class EmulatorCore {
    let memory: EmulatorMemory
    let cpu: PowerPCCPU
    let gamePad: WiiUGamePad
    private(set) var loadedProgram: EmulatorProgram?
    private(set) var instructionCount: UInt64 = 0

    init(memorySize: Int = 64 * 1024 * 1024) {
        self.memory = EmulatorMemory(size: memorySize)
        self.cpu = PowerPCCPU()
        self.gamePad = WiiUGamePad()
    }

    func reset() {
        memory.reset()
        cpu.reset()
        gamePad.reset()
        loadedProgram = nil
        instructionCount = 0
    }

    func loadProgram(_ data: [UInt8], at address: UInt32, entryPoint: UInt32? = nil) {
        memory.load(data, at: address)
        let entry = entryPoint ?? address
        loadedProgram = EmulatorProgram(
            entryPoint: entry,
            imageAddress: address,
            imageSize: data.count
        )
        cpu.programCounter = entry
        instructionCount = 0
    }

    func load(executable: WiiUExecutable) throws {
        reset()
        try WiiUExecutableLoader().load(executable, into: memory)

        let imageAddress = executable.loadSegments.map(\.virtualAddress).min() ?? executable.entryPoint
        let imageEnd = executable.loadSegments.map {
            $0.virtualAddress &+ $0.memorySize
        }.max() ?? executable.entryPoint

        loadedProgram = EmulatorProgram(
            entryPoint: executable.entryPoint,
            imageAddress: imageAddress,
            imageSize: Int(imageEnd &- imageAddress)
        )
        cpu.programCounter = executable.entryPoint
    }

    func step() {
        guard loadedProgram != nil else { return }
        cpu.step(memory: memory)
        instructionCount &+= 1
    }

    func run(maxInstructions: Int) {
        guard maxInstructions > 0, loadedProgram != nil else { return }

        for _ in 0..<maxInstructions {
            step()
        }
    }
}

final class EmulatorSession: ObservableObject {
    @Published private(set) var state: EmulatorState = .stopped
    @Published private(set) var programCounter: UInt32 = 0
    @Published private(set) var instructionCount: UInt64 = 0
    @Published private(set) var lastError: String?

    let core: EmulatorCore
    private let loader = WiiUExecutableLoader()

    init() {
        core = EmulatorCore()
    }

    func boot(url: URL) {
        stop()

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let executable = try loader.inspect(url: url)
            try core.load(executable: executable)
            syncState()
            state = .ready
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            lastError = message
            state = .failed(message)
        }
    }

    func start() {
        guard core.loadedProgram != nil else { return }
        state = .running
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
    }

    func stop() {
        state = .stopped
        core.reset()
        programCounter = 0
        instructionCount = 0
        lastError = nil
    }

    func runFrame() {
        guard state == .running else {
            syncState()
            return
        }

        core.run(maxInstructions: 2_000)
        syncState()
    }

    private func syncState() {
        programCounter = core.cpu.programCounter
        instructionCount = core.instructionCount
    }
}
