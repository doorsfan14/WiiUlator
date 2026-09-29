import Foundation

public final class CafeKernel {
    public static let consoleWrite: UInt32 = 0x0000
    public static let appExit: UInt32 = 0x1900
    public static let getMapVirtAddrRange: UInt32 = 0x3A00
    public static let getDataPhysAddrRange: UInt32 = 0x3B00
    public static let getAvailPhysAddrRange: UInt32 = 0x3C00
    public static let mapMemory: UInt32 = 0x3D00
    public static let unmapMemory: UInt32 = 0x3E00
    public static let logBuffer: UInt32 = 0x3F00
    public static let getCodegenVirtAddrRange: UInt32 = 0x4E00

    public private(set) var exited = false
    public private(set) var exitCode: Int32 = 0
    public private(set) var dispatchCount: UInt64 = 0
    public private(set) var lastSyscall: UInt32? = nil

    public func reset() {
        exited = false
        exitCode = 0
        dispatchCount = 0
        lastSyscall = nil
    }

    public func dispatch(cpu: PowerPCCPU, memory: WiiUMemory) {
        guard let number = cpu.consumeSyscall() else { return }
        lastSyscall = number
        dispatchCount += 1

        switch number {
        case Self.consoleWrite:
            consoleWrite(cpu: cpu, memory: memory)
        case Self.appExit:
            exited = true
            exitCode = Int32(bitPattern: cpu.registers[3])
        case Self.getMapVirtAddrRange:
            cpu.registers[3] = 0x02000000
            cpu.registers[4] = 0x0E000000
        case Self.getDataPhysAddrRange:
            cpu.registers[3] = 0x20000000
            cpu.registers[4] = 0x12000000
        case Self.getAvailPhysAddrRange:
            cpu.registers[3] = 0x20000000
            cpu.registers[4] = 0x12000000
        case Self.getCodegenVirtAddrRange:
            cpu.registers[3] = 0x01800000
            cpu.registers[4] = 0x00020000
        case Self.mapMemory, Self.unmapMemory:
            cpu.registers[3] = 0
        case Self.logBuffer:
            cpu.registers[3] = 0
        default:
            cpu.registers[3] = UInt32(bitPattern: Int32(-1))
        }
    }

    private func consoleWrite(cpu: PowerPCCPU, memory: WiiUMemory) {
        let address = cpu.registers[3]
        let length = min(cpu.registers[4], 4096)
        guard length > 0 else {
            cpu.registers[3] = 0
            return
        }

        var output = ""
        for offset in 0..<length {
            let byte = memory.read8(address &+ offset)
            if byte == 0 { break }
            output.append(Character(UnicodeScalar(byte)))
        }

        if !output.isEmpty {
            print(output, terminator: "")
        }
        cpu.registers[3] = UInt32(output.utf8.count)
    }
}
