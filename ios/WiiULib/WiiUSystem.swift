import Foundation

public final class WiiUSystem {
    public static let mainRAMBase: UInt32 = 0x10000000
    public static let mainRAMSize: UInt32 = 0x10000000
    public static let mmioBase: UInt32 = 0x0C000000
    public static let mmioSize: UInt32 = 0x01000000

    public let memory = WiiUMemory()
    public let cpu = PowerPCCPU()
    public let audio = WiiUAudio()
    public let kernel = CafeKernel()
    public private(set) var cycles: UInt64 = 0

    public init() {}

    public func reset() {
        memory.reset()
        cpu.reset()
        audio.reset()
        kernel.reset()
        cycles = 0
    }

    public func loadProgram(_ data: Data, at address: UInt32, entryPoint: UInt32) {
        reset()
        memory.load(data, at: address)
        cpu.pc = entryPoint
    }

    func tick() {
        cycles += 1
    }

    public func run(instructions: Int) {
        guard instructions > 0 else { return }
        for _ in 0..<instructions {
            cpu.step(memory: memory)
            if cpu.syscall != nil { kernel.dispatch(cpu: cpu, memory: memory) }
            tick()
            if cpu.unsupportedInstruction != 0 || kernel.exited { break }
        }
    }

    public var isStopped: Bool {
        cpu.unsupportedInstruction != 0 || kernel.exited
    }
}
