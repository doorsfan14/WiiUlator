import XCTest
@testable import WiiUlator

final class EmulatorCoreTests: XCTestCase {
    func testMemoryBigEndian32BitAccess() {
        let memory = EmulatorMemory(size: 16)
        memory.write32(at: 0, value: 0x12345678)
        XCTAssertEqual(memory.read32(at: 0), 0x12345678)
        XCTAssertEqual(memory.read16(at: 0), 0x1234)
        XCTAssertEqual(memory.read16(at: 2), 0x5678)
    }

    func testPowerPCAddImmediate() {
        let memory = EmulatorMemory(size: 16)
        let cpu = PowerPCCPU()

        memory.write32(at: 0, value: 0x3860002A)
        cpu.step(memory: memory)

        XCTAssertEqual(cpu.generalPurposeRegisters[3], 42)
        XCTAssertEqual(cpu.programCounter, 4)
    }

    func testPowerPCOrImmediate() {
        let memory = EmulatorMemory(size: 16)
        let cpu = PowerPCCPU()

        cpu.generalPurposeRegisters[3] = 0xF0
        memory.write32(at: 0, value: 0x6063000F)
        cpu.step(memory: memory)

        XCTAssertEqual(cpu.generalPurposeRegisters[3], 0xFF)
    }
}
