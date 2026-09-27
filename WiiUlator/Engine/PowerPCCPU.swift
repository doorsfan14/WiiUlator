import Foundation

final class PowerPCCPU {
    var generalPurposeRegisters = [UInt32](repeating: 0, count: 32)
    var programCounter: UInt32 = 0
    var conditionRegister: UInt32 = 0
    var linkRegister: UInt32 = 0
    var countRegister: UInt32 = 0
    var xer: UInt32 = 0
    var floatingPointRegisters = [Double](repeating: 0, count: 32)
    private(set) var lastInstruction: UInt32 = 0
    private(set) var unsupportedInstruction: UInt32?

    func reset() {
        generalPurposeRegisters = [UInt32](repeating: 0, count: 32)
        programCounter = 0
        conditionRegister = 0
        linkRegister = 0
        countRegister = 0
        xer = 0
        floatingPointRegisters = [Double](repeating: 0, count: 32)
        lastInstruction = 0
        unsupportedInstruction = nil
    }

    func step(memory: EmulatorMemory) {
        let currentPC = programCounter
        let instruction = memory.read32(at: currentPC)
        lastInstruction = instruction
        unsupportedInstruction = nil
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

        case 10: // cmplwi
            let bf = Int((instruction >> 23) & 0x7)
            let ra = Int((instruction >> 16) & 0x1f)
            let lhs = generalPurposeRegisters[ra]
            let rhs = instruction & 0xffff
            updateCRField(bf, lhs < rhs ? 0x8 : (lhs > rhs ? 0x4 : 0x2))

        case 11: // cmpwi
            let bf = Int((instruction >> 23) & 0x7)
            let ra = Int((instruction >> 16) & 0x1f)
            let immediate = signExtend16(instruction)
            updateCRField(bf, compareSigned(generalPurposeRegisters[ra], UInt32(bitPattern: immediate)))

        case 21: // rlwinm
            let rs = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let sh = Int((instruction >> 11) & 0x1f)
            let mb = Int((instruction >> 6) & 0x1f)
            let me = Int((instruction >> 1) & 0x1f)
            let rotated = generalPurposeRegisters[rs].rotateLeft(sh)
            generalPurposeRegisters[ra] = rotated & rotateMask(mb: mb, me: me)

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

        case 48: // lfs
            let frD = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            floatingPointRegisters[frD] = Double(Float(bitPattern: memory.read32(at: effectiveAddress(ra, instruction))))

        case 49: // lfsu
            let frD = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            floatingPointRegisters[frD] = Double(Float(bitPattern: memory.read32(at: address)))

        case 50: // lfd
            let frD = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            floatingPointRegisters[frD] = Double(bitPattern: memory.read64(at: effectiveAddress(ra, instruction)))

        case 51: // lfdu
            let frD = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            floatingPointRegisters[frD] = Double(bitPattern: memory.read64(at: address))

        case 52: // stfs
            let frS = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            memory.write32(at: effectiveAddress(ra, instruction), value: Float(floatingPointRegisters[frS]).bitPattern)

        case 53: // stfsu
            let frS = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            memory.write32(at: address, value: Float(floatingPointRegisters[frS]).bitPattern)

        case 54: // stfd
            let frS = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            memory.write64(at: effectiveAddress(ra, instruction), value: floatingPointRegisters[frS].bitPattern)

        case 55: // stfdu
            let frS = Int((instruction >> 21) & 0x1f)
            let ra = Int((instruction >> 16) & 0x1f)
            let address = effectiveAddress(ra, instruction)
            generalPurposeRegisters[ra] = address
            memory.write64(at: address, value: floatingPointRegisters[frS].bitPattern)

        case 59:
            executeOpcode59(instruction)

        case 63:
            executeOpcode63(instruction)

        case 31:
            executeOpcode31(instruction, memory: memory)

        case 19:
            executeOpcode19(instruction)

        default:
            unsupportedInstruction = instruction
        }
    }

    private func executeOpcode59(_ instruction: UInt32) {
        let frD = Int((instruction >> 21) & 0x1f)
        let frA = Int((instruction >> 16) & 0x1f)
        let frB = Int((instruction >> 11) & 0x1f)
        let xo = (instruction >> 1) & 0x3ff
        let a = Float(floatingPointRegisters[frA])
        let b = Float(floatingPointRegisters[frB])

        switch xo {
        case 18: floatingPointRegisters[frD] = Double(a / b)
        case 20: floatingPointRegisters[frD] = Double(a - b)
        case 21: floatingPointRegisters[frD] = Double(a + b)
        case 25: floatingPointRegisters[frD] = Double(a * b)
        default: unsupportedInstruction = instruction
        }
    }

    private func executeOpcode63(_ instruction: UInt32) {
        let frD = Int((instruction >> 21) & 0x1f)
        let frA = Int((instruction >> 16) & 0x1f)
        let frB = Int((instruction >> 11) & 0x1f)
        let frC = Int((instruction >> 6) & 0x1f)
        let xo = (instruction >> 1) & 0x3ff

        switch xo {
        case 0, 32:
            let field = Int((instruction >> 23) & 0x7)
            let lhs = floatingPointRegisters[frA]
            let rhs = floatingPointRegisters[frB]
            let result: UInt32 = (lhs.isNaN || rhs.isNaN) ? 0x1 : (lhs < rhs ? 0x8 : (lhs > rhs ? 0x4 : 0x2))
            updateCRField(field, result)
        case 12:
            floatingPointRegisters[frD] = Double(Float(floatingPointRegisters[frB]))
        case 18:
            floatingPointRegisters[frD] = floatingPointRegisters[frA] / floatingPointRegisters[frB]
        case 20:
            floatingPointRegisters[frD] = floatingPointRegisters[frA] - floatingPointRegisters[frB]
        case 21:
            floatingPointRegisters[frD] = floatingPointRegisters[frA] + floatingPointRegisters[frB]
        case 25:
            floatingPointRegisters[frD] = floatingPointRegisters[frA] * floatingPointRegisters[frC]
        case 40:
            floatingPointRegisters[frD] = -floatingPointRegisters[frB]
        case 72:
            floatingPointRegisters[frD] = floatingPointRegisters[frB]
        case 264:
            floatingPointRegisters[frD] = abs(floatingPointRegisters[frB])
        default:
            unsupportedInstruction = instruction
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

        case 19: // mfcr
            generalPurposeRegisters[ra] = conditionRegister

        case 24: // slw
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] << (generalPurposeRegisters[rb] & 0x1f)
        case 536: // srw
            generalPurposeRegisters[ra] = generalPurposeRegisters[rs] >> (generalPurposeRegisters[rb] & 0x1f)
        case 792: // sraw
            let value = Int32(bitPattern: generalPurposeRegisters[rs])
            let shift = Int(generalPurposeRegisters[rb] & 0x1f)
            generalPurposeRegisters[ra] = UInt32(bitPattern: value >> shift)
        case 235: // mullw
            let lhs = Int64(Int32(bitPattern: generalPurposeRegisters[rs]))
            let rhs = Int64(Int32(bitPattern: generalPurposeRegisters[rb]))
            generalPurposeRegisters[ra] = UInt32(bitPattern: Int32(truncatingIfNeeded: lhs * rhs))
        case 491: // divw
            let lhs = Int32(bitPattern: generalPurposeRegisters[rs])
            let rhs = Int32(bitPattern: generalPurposeRegisters[rb])
            if rhs != 0, !(lhs == Int32.min && rhs == -1) {
                generalPurposeRegisters[ra] = UInt32(bitPattern: lhs / rhs)
            }
        case 534: // lwbrx
            let address = baseAddress(ra) &+ generalPurposeRegisters[rb]
            generalPurposeRegisters[rs] = UInt32(memory.read8(at: address))
                | UInt32(memory.read8(at: address &+ 1)) << 8
                | UInt32(memory.read8(at: address &+ 2)) << 16
                | UInt32(memory.read8(at: address &+ 3)) << 24
        case 662: // stwbrx
            let address = baseAddress(ra) &+ generalPurposeRegisters[rb]
            let value = generalPurposeRegisters[rs]
            memory.write8(at: address, value: UInt8(value & 0xff))
            memory.write8(at: address &+ 1, value: UInt8((value >> 8) & 0xff))
            memory.write8(at: address &+ 2, value: UInt8((value >> 16) & 0xff))
            memory.write8(at: address &+ 3, value: UInt8((value >> 24) & 0xff))
        case 339: // mfspr
            let spr = ((instruction >> 16) & 0x1f) | (((instruction >> 11) & 0x1f) << 5)
            generalPurposeRegisters[ra] = specialRegister(spr)
        case 467: // mtspr
            let spr = ((instruction >> 16) & 0x1f) | (((instruction >> 11) & 0x1f) << 5)
            writeSpecialRegister(spr, value: generalPurposeRegisters[rs])
        case 144: // mtcrf
            let crm = (instruction >> 12) & 0xff
            var newCR = conditionRegister
            for field in 0..<8 where (crm & (1 << (7 - field))) != 0 {
                let shift = UInt32((7 - field) * 4)
                newCR = (newCR & ~(0xF << shift)) | (generalPurposeRegisters[rs] & (0xF << shift))
            }
            conditionRegister = newCR
        default:
            unsupportedInstruction = instruction
        }
    }

    private func executeOpcode19(_ instruction: UInt32) {
        let xo = (instruction >> 1) & 0x3ff
        let bo = UInt8((instruction >> 21) & 0x1f)
        let bi = UInt8((instruction >> 16) & 0x1f)
        let lk = (instruction & 1) != 0

        switch xo {
        case 16: // bclr
            let returnAddress = programCounter
            if branchCondition(bo: bo, bi: bi) {
                programCounter = linkRegister & 0xFFFFFFFC
            }
            if lk {
                linkRegister = returnAddress
            }
        case 528: // bcctr
            let target = countRegister & 0xFFFFFFFC
            if branchCondition(bo: bo, bi: bi) {
                programCounter = target
            }
            if lk {
                linkRegister = programCounter
            }
        case 0: // mcrf
            let bf = Int((instruction >> 23) & 0x7)
            let bfa = Int((instruction >> 18) & 0x7)
            let destinationShift = UInt32((7 - bf) * 4)
            let sourceShift = UInt32((7 - bfa) * 4)
            let value = (conditionRegister >> sourceShift) & 0xF
            conditionRegister = (conditionRegister & ~(0xF << destinationShift)) | (value << destinationShift)
        default:
            unsupportedInstruction = instruction
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
        let raw = value & 0x03FFFFFC
        if (raw & 0x02000000) != 0 {
            return Int32(bitPattern: raw | 0xFC000000)
        }
        return Int32(raw)
    }

    private func branchCondition(bo: UInt8, bi: UInt8) -> Bool {
        var ctrPass = true
        if (bo & 0x04) == 0 {
            countRegister &-= 1
            ctrPass = ((countRegister != 0) != ((bo & 0x02) != 0))
        }

        let crPass: Bool
        if (bo & 0x10) != 0 {
            crPass = true
        } else {
            let conditionBit = ((conditionRegister >> (31 - Int(bi))) & 1) != 0
            crPass = conditionBit == ((bo & 0x08) != 0)
        }

        return ctrPass && crPass
    }

    private func compareSigned(_ lhs: UInt32, _ rhs: UInt32) -> UInt32 {
        let a = Int32(bitPattern: lhs)
        let b = Int32(bitPattern: rhs)
        if a < b { return 0x8 }
        if a > b { return 0x4 }
        return 0x2
    }

    private func updateCRField(_ field: Int, _ value: UInt32) {
        let shift = UInt32((7 - field) * 4)
        conditionRegister = (conditionRegister & ~(0xF << shift)) | ((value & 0xF) << shift)
    }

    private func specialRegister(_ spr: UInt32) -> UInt32 {
        switch spr {
        case 1: return xer
        case 8: return linkRegister
        case 9: return countRegister
        default: return 0
        }
    }

    private func writeSpecialRegister(_ spr: UInt32, value: UInt32) {
        switch spr {
        case 1: xer = value
        case 8: linkRegister = value
        case 9: countRegister = value
        default: break
        }
    }

    private func rotateMask(mb: Int, me: Int) -> UInt32 {
        if mb <= me {
            let width = me - mb + 1
            if width == 32 { return UInt32.max }
            return ((UInt32(1) << UInt32(width)) - 1) << UInt32(31 - me)
        }

        let left = UInt32.max << UInt32(31 - me)
        let right = (UInt32(1) << UInt32(32 - mb)) - 1
        return left | right
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


private extension UInt32 {
    func rotateLeft(_ amount: Int) -> UInt32 {
        let shift = amount & 31
        if shift == 0 { return self }
        return (self << UInt32(shift)) | (self >> UInt32(32 - shift))
    }
}
