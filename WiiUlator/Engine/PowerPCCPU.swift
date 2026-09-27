import Foundation

final class PowerPCCPU {
    var generalPurposeRegisters = [UInt32](repeating: 0, count: 32)
    var programCounter: UInt32 = 0
    var conditionRegister: UInt32 = 0
    var linkRegister: UInt32 = 0
    var countRegister: UInt32 = 0
    var xer: UInt32 = 0

    func reset() {
        generalPurposeRegisters = [UInt32](repeating: 0, count: 32)
        programCounter = 0
        conditionRegister = 0
        linkRegister = 0
        countRegister = 0
        xer = 0
    }

    func step(memory: EmulatorMemory) {
        let currentPC = programCounter
        let instruction = memory.read32(at: currentPC)
        programCounter = currentPC &+ 4
        execute(instruction, currentPC: currentPC, memory: memory)
    }

    private func execute(_ instruction: UInt32, currentPC: UInt32, memory: EmulatorMemory) {
        let opcode = instruction >> 26

        switch opcode {
        case 14:
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let immediate = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            generalPurposeRegisters[rd] = generalPurposeRegisters[ra] &+ UInt32(bitPattern: immediate)

        case 24:
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let immediate = instruction & 0xffff
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] | immediate

        case 32:
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let displacement = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            let address = UInt32(bitPattern: Int32(bitPattern: generalPurposeRegisters[ra]) &+ displacement)
            generalPurposeRegisters[rd] = UInt32(memory.read8(at: address))

        case 34:
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let displacement = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            let address = UInt32(bitPattern: Int32(bitPattern: generalPurposeRegisters[ra]) &+ displacement)
            generalPurposeRegisters[rd] = UInt32(memory.read16(at: address))

        case 40:
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let displacement = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            let address = UInt32(bitPattern: Int32(bitPattern: generalPurposeRegisters[ra]) &+ displacement)
            generalPurposeRegisters[rd] = memory.read32(at: address)

        case 36:
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let displacement = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            let address = UInt32(bitPattern: Int32(bitPattern: generalPurposeRegisters[ra]) &+ displacement)
            memory.write8(at: address, value: UInt8(generalPurposeRegisters[rs] & 0xff))

        case 38:
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let displacement = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            let address = UInt32(bitPattern: Int32(bitPattern: generalPurposeRegisters[ra]) &+ displacement)
            memory.write16(at: address, value: UInt16(generalPurposeRegisters[rs] & 0xffff))

        case 44:
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let displacement = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            let address = UInt32(bitPattern: Int32(bitPattern: generalPurposeRegisters[ra]) &+ displacement)
            memory.write32(at: address, value: generalPurposeRegisters[rs])

        case 18:
            let li = instruction & 0x03fffffc
            let displacement = Int32(bitPattern: li)
            let target = UInt32(bitPattern: Int32(bitPattern: currentPC) &+ (displacement << 0))
            if (instruction & 1) != 0 {
                linkRegister = currentPC &+ 4
            }
            programCounter = target

        default:
            break
        }
    }
}
