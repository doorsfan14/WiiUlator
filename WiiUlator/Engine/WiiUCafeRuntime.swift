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
        case .OSReport: return 0x01800000
        case .OSFatal: return 0x01800004
        case .OSGetSystemInfo: return 0x01800008
        case .MEMAllocFromDefaultHeap: return 0x0180000C
        case .MEMFreeToDefaultHeap: return 0x01800010
        case .GX2Init: return 0x01800014
        case .GX2Shutdown: return 0x01800018
        case .VPADInit: return 0x0180001C
        case .VPADRead: return 0x01800020
        }
    }

    func address(named name: String) -> UInt32? {
        guard let symbol = Symbol(rawValue: name) else { return nil }
        return address(for: symbol)
    }

    func containsStub(_ address: UInt32) -> Bool {
        address >= 0x01800000 && address <= 0x01800020 && (address & 3) == 0
    }

    mutating func invokeStub(at address: UInt32, cpu: PowerPCCPU, memory: EmulatorMemory) -> Bool {
        guard initialized, containsStub(address) else { return false }

        switch address {
        case 0x01800000:
            // Cafe's OSReport is variadic. The emulator intentionally treats it
            // as a successful no-op until a guest logging bridge is added.
            cpu.generalPurposeRegisters[3] = 0
        case 0x01800004:
            fatalMessage = "Guest called OSFatal"
            cpu.generalPurposeRegisters[3] = UInt32(bitPattern: -1)
        case 0x01800008:
            let result = cpu.generalPurposeRegisters[3]
            if result != 0 {
                memory.zero(0x40, at: result)
            }
            cpu.generalPurposeRegisters[3] = 0
        case 0x0180000C:
            let size = cpu.generalPurposeRegisters[3]
            let aligned = (size &+ 0x1F) & ~0x1F
            let result = heapCursor
            heapCursor = heapCursor &+ max(aligned, 0x20)
            cpu.generalPurposeRegisters[3] = result
        case 0x01800010:
            cpu.generalPurposeRegisters[3] = 0
        case 0x01800014, 0x01800018:
            cpu.generalPurposeRegisters[3] = 0
        case 0x0180001C:
            cpu.generalPurposeRegisters[3] = 0
        case 0x01800020:
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
