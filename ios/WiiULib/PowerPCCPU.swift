import Foundation

public final class PowerPCCPU {
    public var registers = [UInt32](repeating: 0, count: 32)
    public var pc: UInt32 = 0
    public var conditionRegister: UInt32 = 0
    public var linkRegister: UInt32 = 0
    public var countRegister: UInt32 = 0
    public var xer: UInt32 = 0
    public private(set) var lastInstruction: UInt32 = 0
    public private(set) var unsupportedInstruction: UInt32 = 0

    public func reset() {
        registers = [UInt32](repeating: 0, count: 32)
        pc = 0
        conditionRegister = 0
        linkRegister = 0
        countRegister = 0
        xer = 0
        lastInstruction = 0
        unsupportedInstruction = 0
    }

    public func step(memory: WiiUMemory) {
        let currentPC = pc
        let instruction = memory.read32(currentPC)
        lastInstruction = instruction
        unsupportedInstruction = 0
        pc &+= 4

        switch instruction >> 26 {
        case 7:
            let d = Int((instruction >> 21) & 31), a = Int((instruction >> 16) & 31)
            registers[d] = registers[a] &* UInt32(bitPattern: Int32(Int16(bitPattern: UInt16(instruction & 0xFFFF))))

        case 8:
            let d = Int((instruction >> 21) & 31), a = Int((instruction >> 16) & 31)
            registers[d] = UInt32(bitPattern: Int32(Int16(bitPattern: UInt16(instruction & 0xFFFF)))) &- registers[a]

        case 14:
            let d = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            registers[d] = base(a) &+ signExtend16(instruction)

        case 15:
            let d = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            registers[d] = base(a) &+ (signExtend16(instruction) << 16)

        case 16:
            branchConditional(instruction, currentPC: currentPC)

        case 18:
            let li = instruction & 0x03FFFFFC
            let target = (li & 0x02000000) != 0 ? li | 0xFC000000 : li
            if (instruction & 2) != 0 {
                pc = target
            } else {
                pc = currentPC &+ target
            }
            if (instruction & 1) != 0 {
                linkRegister = currentPC &+ 4
            }

        case 24:
            let s = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            registers[a] = registers[s] | (instruction & 0xFFFF)

        case 25:
            let s = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            registers[a] = registers[s] | ((instruction & 0xFFFF) << 16)

        case 26:
            let s = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            registers[a] = registers[s] ^ (instruction & 0xFFFF)

        case 28:
            let s = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            let value = registers[s] & (instruction & 0xFFFF)
            registers[a] = value
            conditionRegister = (conditionRegister & 0x0FFFFFFF) | ((value == 0 ? 2 : (Int32(bitPattern: value) < 0 ? 8 : 4)) << 28)

        case 32:
            let d = Int((instruction >> 21) & 31)
            registers[d] = memory.read32(effectiveAddress(instruction))

        case 33:
            let d = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            let address = effectiveAddress(instruction)
            registers[a] = address
            registers[d] = memory.read32(address)

        case 34:
            let d = Int((instruction >> 21) & 31)
            registers[d] = UInt32(memory.read8(effectiveAddress(instruction)))

        case 36:
            let s = Int((instruction >> 21) & 31)
            memory.write32(effectiveAddress(instruction), registers[s])

        case 37:
            let s = Int((instruction >> 21) & 31)
            let a = Int((instruction >> 16) & 31)
            let address = effectiveAddress(instruction)
            registers[a] = address
            memory.write32(address, registers[s])

        case 38:
            let s = Int((instruction >> 21) & 31)
            memory.write8(effectiveAddress(instruction), UInt8(registers[s] & 0xFF))

        case 40:
            let d = Int((instruction >> 21) & 31)
            registers[d] = memory.read16(effectiveAddress(instruction))

        case 44:
            let s = Int((instruction >> 21) & 31)
            memory.write16(effectiveAddress(instruction), registers[s])

        case 46:
            var address = effectiveAddress(instruction)
            let d = Int((instruction >> 21) & 31)
            if d < 32 {
                for register in d..<32 {
                    registers[register] = memory.read32(address)
                    address &+= 4
                }
            }

        case 47:
            var address = effectiveAddress(instruction)
            let s = Int((instruction >> 21) & 31)
            if s < 32 {
                for register in s..<32 {
                    memory.write32(address, registers[register])
                    address &+= 4
                }
            }

        case 19:
            if ((instruction >> 1) & 1023) == 16 && conditionMet(instruction) {
                pc = linkRegister & ~3
            }

        case 31:
            executeOpcode31(instruction, memory: memory)

        default:
            unsupportedInstruction = instruction
        }
    }

    private func base(_ index: Int) -> UInt32 {
        index == 0 ? 0 : registers[index]
    }

    private func signExtend16(_ instruction: UInt32) -> UInt32 {
        UInt32(bitPattern: Int32(Int16(bitPattern: UInt16(instruction & 0xFFFF))))
    }

    private func effectiveAddress(_ instruction: UInt32) -> UInt32 {
        base(Int(instruction & 31)) &+ signExtend16(instruction)
    }

    private func conditionMet(_ instruction: UInt32) -> Bool {
        let bo = (instruction >> 21) & 31
        let bi = (instruction >> 16) & 31
        let bit = (conditionRegister >> (31 - bi)) & 1
        return (bo & 16) != 0 || (bit == 1) == ((bo & 8) != 0)
    }

    private func branchConditional(_ instruction: UInt32, currentPC: UInt32) {
        if conditionMet(instruction) {
            let displacement = UInt32(bitPattern: Int32(Int16(bitPattern: UInt16(instruction & 0xFFFC))))
            pc = (instruction & 2) != 0 ? displacement : currentPC &+ displacement
        }
        if (instruction & 1) != 0 {
            linkRegister = currentPC &+ 4
        }
    }

    private func executeOpcode31(_ instruction: UInt32, memory: WiiUMemory) {
        let xo = (instruction >> 1) & 1023
        let s = Int((instruction >> 21) & 31)
        let a = Int((instruction >> 16) & 31)
        let b = Int((instruction >> 11) & 31)

        switch xo {
        case 19:
            registers[a] = conditionRegister
        case 24:
            registers[a] = registers[s] << (registers[b] & 31)
        case 26:
            registers[a] = UInt32(registers[s] == 0 ? 32 : registers[s].leadingZeroBitCount)
        case 104:
            registers[a] = 0 &- registers[s]
        case 124:
            registers[a] = ~(registers[s] | registers[b])
        case 235:
            registers[a] = registers[s] &* registers[b]
        case 476:
            registers[a] = ~(registers[s] & registers[b])
        case 491:
            if registers[b] != 0 && !(registers[s] == 0x80000000 && registers[b] == 0xFFFFFFFF) {
                registers[a] = UInt32(bitPattern: Int32(bitPattern: registers[s]) / Int32(bitPattern: registers[b]))
            }
        case 266:
            registers[a] = registers[s] &+ registers[b]
        case 40:
            registers[a] = registers[b] &- registers[s]
        case 444:
            registers[a] = registers[s] | registers[b]
        case 316:
            registers[a] = registers[s] ^ registers[b]
        case 28:
            registers[a] = registers[s] & registers[b]
        case 536:
            registers[a] = registers[s] >> (registers[b] & 31)
        case 534:
            let address = base(a) &+ registers[b]
            registers[s] = memory.read32(address).byteSwapped
        case 662:
            let address = base(a) &+ registers[b]
            memory.write32(address, registers[s].byteSwapped)
        case 16:
            if conditionMet(instruction) { pc = linkRegister & ~3 }
            if (instruction & 1) != 0 { linkRegister = pc }
        case 528:
            if conditionMet(instruction) { pc = countRegister & ~3 }
        case 339:
            let spr = ((instruction >> 16) & 31) | (((instruction >> 11) & 31) << 5)
            registers[a] = spr == 1 ? xer : spr == 8 ? linkRegister : spr == 9 ? countRegister : 0
        case 467:
            let spr = ((instruction >> 16) & 31) | (((instruction >> 11) & 31) << 5)
            if spr == 8 { linkRegister = registers[s] }
            else if spr == 9 { countRegister = registers[s] }
            else if spr == 1 { xer = registers[s] }
        default:
            unsupportedInstruction = instruction
        }
    }
}
