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
