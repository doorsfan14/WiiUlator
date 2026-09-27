import Foundation

final class PowerPCCPU {
    var generalPurposeRegisters = [UInt32](repeating: 0, count: 32)
    var programCounter: UInt32 = 0
    var conditionRegister: UInt32 = 0

    func reset() {
        generalPurposeRegisters = [UInt32](repeating: 0, count: 32)
        programCounter = 0
        conditionRegister = 0
    }

    func step(memory: EmulatorMemory) {
        let instruction = memory.read32(at: programCounter)
        execute(instruction)
        programCounter &+= 4
    }

    private func execute(_ instruction: UInt32) {
        let opcode = instruction >> 26

        switch opcode {
        case 14:
            // addi: rD = rA + sign-extended immediate
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let immediate = Int32(Int16(truncatingIfNeeded: instruction & 0xffff))
            generalPurposeRegisters[rd] = generalPurposeRegisters[ra] &+ UInt32(bitPattern: immediate)

        case 24:
            // ori: rA = rS | zero-extended immediate
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let immediate = instruction & 0xffff
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] | immediate

        default:
            break
        }
    }
}
