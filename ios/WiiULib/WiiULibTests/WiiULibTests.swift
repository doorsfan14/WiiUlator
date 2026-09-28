import XCTest
@testable import WiiULib

final class WiiULibTests: XCTestCase {
    func testBigEndianMemory() {
        let memory = WiiUMemory()
        memory.write32(0x1000, 0x12345678)

        XCTAssertEqual(memory.read8(0x1000), 0x12)
        XCTAssertEqual(memory.read16(0x1000), 0x1234)
        XCTAssertEqual(memory.read32(0x1000), 0x12345678)
    }

    func testCrossPageMemory() {
        let memory = WiiUMemory()
        memory.write32(0x1FFE, 0x12345678)
        XCTAssertEqual(memory.read32(0x1FFE), 0x12345678)

        memory.zero(count: 4, at: 0x1FFE)
        XCTAssertEqual(memory.read32(0x1FFE), 0)
    }

    func testPowerPCAddImmediate() {
        let core = WiiULib()
        let address: UInt32 = 0x1000

        // addi r3,r0,42
        core.load(data: Data([0x38, 0x60, 0x00, 0x2A]), at: address, entryPoint: address)
        core.run(instructions: 1)

        XCTAssertEqual(core.cpu.registers[3], 42)
        XCTAssertEqual(core.cpu.pc, address + 4)
        XCTAssertEqual(core.instructionCount, 1)
        XCTAssertEqual(core.system.cycles, 1)
        XCTAssertTrue(core.memory === core.system.memory)
        XCTAssertTrue(core.cpu === core.system.cpu)
    }

    func testPowerPCBranchAndLink() {
        let core = WiiULib()
        let address: UInt32 = 0x2000

        // bl +8; target is 0x2008 and LR becomes 0x2004.
        core.load(data: Data([0x48, 0x00, 0x00, 0x09, 0x38, 0x60, 0x00, 0x01, 0x38, 0x60, 0x00, 0x02]), at: address, entryPoint: address)
        core.run(instructions: 1)

        XCTAssertEqual(core.cpu.pc, address + 8)
        XCTAssertEqual(core.cpu.linkRegister, address + 4)
    }

    func testELFLoader() throws {
        let core = WiiULib()

        var elf = Data(repeating: 0, count: 84)
        elf[0] = 0x7F; elf[1] = 0x45; elf[2] = 0x4C; elf[3] = 0x46
        elf[4] = 1; elf[5] = 2
        write16(&elf, 18, 20)
        write32(&elf, 24, 0x1000)
        write32(&elf, 28, 52)
        write16(&elf, 42, 32)
        write16(&elf, 44, 1)

        elf = Data(repeating: 0, count: 88)
        elf[0] = 0x7F; elf[1] = 0x45; elf[2] = 0x4C; elf[3] = 0x46
        elf[4] = 1; elf[5] = 2
        write16(&elf, 18, 20)
        write32(&elf, 24, 0x1000)
        write32(&elf, 28, 52)
        write16(&elf, 42, 32)
        write16(&elf, 44, 1)
        write32(&elf, 52, 1)
        write32(&elf, 56, 84)
        write32(&elf, 60, 0x1000)
        write32(&elf, 68, 4)
        write32(&elf, 72, 4)
        elf[84] = 0x38; elf[85] = 0x60; elf[86] = 0x00; elf[87] = 0x2A

        try core.loadELF(elf)

        XCTAssertEqual(core.entryPoint, 0x1000)
        XCTAssertEqual(core.cpu.pc, 0x1000)
        XCTAssertEqual(core.memory.read32(0x1000), 0x3860002A)
    }

    private func write16(_ data: inout Data, _ offset: Int, _ value: UInt16) {
        data[offset] = UInt8(value >> 8)
        data[offset + 1] = UInt8(value & 0xFF)
    }

    private func write32(_ data: inout Data, _ offset: Int, _ value: UInt32) {
        data[offset] = UInt8((value >> 24) & 0xFF)
        data[offset + 1] = UInt8((value >> 16) & 0xFF)
        data[offset + 2] = UInt8((value >> 8) & 0xFF)
        data[offset + 3] = UInt8(value & 0xFF)
    }
}
