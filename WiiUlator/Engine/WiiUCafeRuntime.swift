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
    private var heapCursor: UInt32 = 0x12000000
    private(set) var fatalMessage: String?

    mutating func reset() {
        initialized = false
        heapCursor = 0x12000000
        fatalMessage = nil
    }

    mutating func initialize() {
        initialized = true
    }

    func address(for symbol: Symbol) -> UInt32 {
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

    func address(named name: String) -> UInt32? {
        guard let symbol = Symbol(rawValue: name) else { return nil }
        return address(for: symbol)
    }

    func containsStub(_ address: UInt32) -> Bool {
        address >= 0xFFF00000 && address <= 0xFFF00020 && (address & 3) == 0
    }

    mutating func invokeStub(at address: UInt32, cpu: PowerPCCPU, memory: EmulatorMemory) -> Bool {
        guard initialized, containsStub(address) else { return false }

        switch address {
        case self.address(for: .OSReport):
            // Cafe's OSReport is variadic. The emulator intentionally treats it
            // as a successful no-op until a guest logging bridge is added.
            cpu.generalPurposeRegisters[3] = 0
        case self.address(for: .OSFatal):
            fatalMessage = "Guest called OSFatal"
            cpu.generalPurposeRegisters[3] = UInt32(bitPattern: -1)
        case self.address(for: .OSGetSystemInfo):
            let result = cpu.generalPurposeRegisters[3]
            if result != 0 {
                memory.zero(0x40, at: result)
            }
            cpu.generalPurposeRegisters[3] = 0
        case self.address(for: .MEMAllocFromDefaultHeap):
            let size = cpu.generalPurposeRegisters[3]
            let aligned = (size &+ 0x1F) & ~0x1F
            let result = heapCursor
            heapCursor = heapCursor &+ max(aligned, 0x20)
            cpu.generalPurposeRegisters[3] = result
        case self.address(for: .MEMFreeToDefaultHeap):
            cpu.generalPurposeRegisters[3] = 0
        case self.address(for: .GX2Init), self.address(for: .GX2Shutdown):
            cpu.generalPurposeRegisters[3] = 0
        case self.address(for: .VPADInit):
            cpu.generalPurposeRegisters[3] = 0
        case self.address(for: .VPADRead):
            let buffer = cpu.generalPurposeRegisters[4]
            let count = cpu.generalPurposeRegisters[5]
            if buffer != 0 && count > 0 {
                memory.zero(min(count, 0x100), at: buffer)
            }
            cpu.generalPurposeRegisters[3] = 0
        default:
            return false
        }

        return true
    }

    mutating func handleSystemCall(cpu: PowerPCCPU, memory: EmulatorMemory) {
        guard initialized else { return }

        switch cpu.generalPurposeRegisters[0] {
        case 0x100:
            cpu.generalPurposeRegisters[3] = UInt32(bitPattern: -1)
        default:
            cpu.generalPurposeRegisters[3] = UInt32(bitPattern: -1)
        }
    }
}
