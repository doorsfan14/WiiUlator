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

        // r0 is hard-wired to zero only for instructions that explicitly
        // treat it as zero; PowerPC general-purpose register 0 itself is writable.
    }

    private func execute(_ instruction: UInt32, currentPC: UInt32, memory: EmulatorMemory) {
        let opcode = instruction >> 26

        switch opcode {
        case 14: // addi
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let immediate = signExtend16(instruction)
            generalPurposeRegisters[rd] = baseAddress(ra) &+ UInt32(bitPattern: immediate)

        case 15: // addis
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let immediate = signExtend16(instruction) << 16
            generalPurposeRegisters[rd] = baseAddress(ra) &+ UInt32(bitPattern: immediate)

        case 16: // bc
            let bo = UInt8((instruction >> 21) & 0x1f)
            let bi = UInt8((instruction >> 16) & 0x1f)
            let bd = signExtend16(instruction & 0xfffc)
            let aa = (instruction & 2) != 0
            let lk = (instruction & 1) != 0

            if branchCondition(bo: bo, bi: bi) {
                let target = aa
                    ? UInt32(bitPattern: bd)
                    : UInt32(bitPattern: Int32(bitPattern: currentPC) &+ bd)
                programCounter = target
            }

            if lk {
                linkRegister = currentPC &+ 4
            }

        case 18: // b
            let li = instruction & 0x03fffffc
            let displacement = signExtend26(li)
            let aa = (instruction & 2) != 0
            let lk = (instruction & 1) != 0

            let target = aa
                ? UInt32(bitPattern: displacement)
                : UInt32(bitPattern: Int32(bitPattern: currentPC) &+ displacement)

            if lk {
                linkRegister = currentPC &+ 4
            }

            programCounter = target

        case 24: // ori
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] | (instruction & 0xffff)

        case 25: // oris
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] | ((instruction & 0xffff) << 16)

        case 26: // xori
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] ^ (instruction & 0xffff)

        case 28: // andi.
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let value = generalPurposeRegisters[rs] & (instruction & 0xffff)
            generalPurposeRegisters[ra] = value
            updateCR0(value)

        case 29: // andis.
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let value = generalPurposeRegisters[rs] & ((instruction & 0xffff) << 16)
            generalPurposeRegisters[ra] = value
            updateCR0(value)

        case 32: // lwz
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[rd] = memory.read32(at: address)

        case 33: // lwzu
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            generalPurposeRegisters[rd] = memory.read32(at: address)

        case 34: // lbz
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            generalPurposeRegisters[rd] = UInt32(memory.read8(at: effectiveAddress(ra, instruction)))

        case 35: // lbzu
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            generalPurposeRegisters[rd] = UInt32(memory.read8(at: address))

        case 36: // stw
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            memory.write32(at: effectiveAddress(ra, instruction), value: generalPurposeRegisters[rs])

        case 37: // stwu
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            memory.write32(at: address, value: generalPurposeRegisters[rs])

        case 38: // stb
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            memory.write8(at: effectiveAddress(ra, instruction), value: UInt8(generalPurposeRegisters[rs] & 0xff))

        case 39: // stbu
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            memory.write8(at: address, value: UInt8(generalPurposeRegisters[rs] & 0xff))

        case 40: // lhz
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            generalPurposeRegisters[rd] = UInt32(memory.read16(at: effectiveAddress(ra, instruction)))

        case 42: // lha
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let value = Int16(bitPattern: memory.read16(at: effectiveAddress(ra, instruction)))
            generalPurposeRegisters[rd] = UInt32(bitPattern: Int32(value))

        case 44: // sth
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            memory.write16(at: effectiveAddress(ra, instruction), value: UInt16(generalPurposeRegisters[rs] & 0xffff))

        case 46: // lmw
            let rd = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            var address = effectiveAddress(ra, instruction)
            for register in rd..<32 {
                generalPurposeRegisters[register] = memory.read32(at: address)
                address &+= 4
            }

        case 47: // stmw
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            var address = effectiveAddress(ra, instruction)
            for register in rs..<32 {
                memory.write32(at: address, value: generalPurposeRegisters[register])
                address &+= 4
            }

        case 31:
            executeOpcode31(instruction, memory: memory)

        case 19:
            executeOpcode19(instruction)

        default:
            break
        }
    }

    private func executeOpcode31(_ instruction: UInt32, memory: EmulatorMemory) {
        let xo = (instruction >> 1) & 0x3ff
        let rs = Int((instruction >> 21) & 0x1f)
        let ra = Int((instruction >> 16) & 0x1f)
        let rb = Int((instruction >> 11) & 0x1f)

        switch xo {
        case 266: // add
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] &+ generalPurposeRegisters[rb]

        case 40: // sub
            generalPurposeRegisters[ra] = generalPurposeRegisters[rb] &- generalPurposeRegisters[rs]

        case 444: // or
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] | generalPurposeRegisters[rb]

        case 316: // xor
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] ^ generalPurposeRegisters[rb]

        case 28: // and
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] & generalPurposeRegisters[rb]

        case 339: // mflr
            generalPurposeRegisters[ra] = linkRegister

        case 467: // mtspr
            let spr = ((instruction >> 16) & 0x1f) | (((instruction >> 11) & 0x1f) << 5)
            switch spr {
            case 8:
                countRegister = generalPurposeRegisters[rs]
            case 9:
                linkRegister = generalPurposeRegisters[rs]
            case 1:
                xer = generalPurposeRegisters[rs]
            default:
                break
            }

        case 19: // mfcr
            generalPurposeRegisters[ra] = conditionRegister

        default:
            break
        }
    }

    private func executeOpcode19(_ instruction: UInt32) {
        let xo = (instruction >> 1) & 0x3ff

        guard xo == 16 else { return } // bclr

        let bo = UInt8((instruction >> 21) & 0x1f)
        let bi = UInt8((instruction >> 16) & 0x1f)
        let lk = (instruction & 1) != 0

        if branchCondition(bo: bo, bi: bi) {
            programCounter = linkRegister & 0xFFFFFFFC
        }

        if lk {
            linkRegister = programCounter
        }
    }

    private func effectiveAddress(_ ra: Int, _ instruction: UInt32) -> UInt32 {
        let displacement = signExtend16(instruction)
        return baseAddress(ra) &+ UInt32(bitPattern: displacement)
    }

    private func baseAddress(_ register: Int) -> UInt32 {
        register == 0 ? 0 : generalPurposeRegisters[register]
    }

    private func signExtend16(_ value: UInt32) -> Int32 {
        Int32(Int16(truncatingIfNeeded: value & 0xffff))
    }

    private func signExtend26(_ value: UInt32) -> Int32 {
        let shifted = value | 0xFC000000
        return Int32(bitPattern: shifted)
    }

    private func branchCondition(bo: UInt8, bi: UInt8) -> Bool {
        let ignoreCondition = (bo & 0x10) != 0
        let branchIfTrue = (bo & 0x08) != 0
        let conditionBit = ((conditionRegister >> (31 - Int(bi))) & 1) != 0

        if ignoreCondition {
            return true
        }

        return branchIfTrue ? conditionBit : !conditionBit
    }

    private func updateCR0(_ value: UInt32) {
        let signed = Int32(bitPattern: value)
        let nibble: UInt32
        if signed < 0 {
            nibble = 0x8
        } else if signed > 0 {
            nibble = 0x4
        } else {
            nibble = 0x2
        }

        conditionRegister = (conditionRegister & 0x0FFFFFFF) | (nibble << 28)
    }
}
