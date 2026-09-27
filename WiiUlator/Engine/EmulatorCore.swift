import Foundation

struct EmulatorProgram {
    let entryPoint: UInt32
    let imageAddress: UInt32
    let imageSize: Int
}

final class EmulatorCore {
    let memory: EmulatorMemory
    let cpu: PowerPCCPU
    private(set) var loadedProgram: EmulatorProgram?

    init(memorySize: Int = 64 * 1024 * 1024) {
        self.memory = EmulatorMemory(size: memorySize)
        self.cpu = PowerPCCPU()
    }

    func reset() {
        memory.reset()
        cpu.reset()
        loadedProgram = nil
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
    }

    func step() {
        cpu.step(memory: memory)
    }

    func run(maxInstructions: Int) {
        guard maxInstructions > 0 else { return }

        for _ in 0..<maxInstructions {
            step()
        }
    }
}
