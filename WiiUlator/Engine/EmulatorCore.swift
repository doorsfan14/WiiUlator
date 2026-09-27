import Foundation

final class EmulatorCore {
    let memory: EmulatorMemory
    let cpu: PowerPCCPU

    init(memorySize: Int = 64 * 1024 * 1024) {
        self.memory = EmulatorMemory(size: memorySize)
        self.cpu = PowerPCCPU()
    }

    func reset() {
        memory.reset()
        cpu.reset()
    }

    func step() {
        cpu.step(memory: memory)
    }
}
