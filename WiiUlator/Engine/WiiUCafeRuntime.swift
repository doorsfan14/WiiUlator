import Foundation

struct WiiUCafeRuntime {
    enum Symbol: String {
        case OSReport
        case OSFatal
        case OSGetSystemInfo
        case MEMAllocFromDefaultHeap
        case MEMFreeToDefaultHeap
        case GX2Init
        case GX2Shutdown
        case VPADInit
        case VPADRead
    }

    private(set) var initialized = false

    mutating func reset() {
        initialized = false
    }

    mutating func initialize() {
        initialized = true
    }

    mutating func handleSystemCall(cpu: PowerPCCPU, memory: EmulatorMemory) {
        guard initialized else { return }

        switch cpu.generalPurposeRegisters[0] {
        case 0x100:
            // KeAppPanic: leave the exception visible to the emulator
            // without terminating the host process.
            cpu.generalPurposeRegisters[3] = UInt32(bitPattern: -1)
        default:
            // Unknown Cafe syscall: return an error rather than executing
            // through an unmapped host address.
            cpu.generalPurposeRegisters[3] = UInt32(bitPattern: -1)
        }
    }

    func address(for symbol: Symbol) -> UInt32? {
        switch symbol {
        case .OSReport: return 0xFFF00000
        case .OSFatal: return 0xFFF00004
        case .OSGetSystemInfo: return 0xFFF00008
        case .MEMAllocFromDefaultHeap: return 0xFFF0000C
        case .MEMFreeToDefaultHeap: return 0xFFF00010
        case .GX2Init: return 0xFFF00014
        case .GX2Shutdown: return 0xFFF00018
        case .VPADInit: return 0xFFF0001C
        case .VPADRead: return 0xFFF00020
        }
    }
}
