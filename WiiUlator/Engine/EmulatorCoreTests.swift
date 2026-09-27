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


    func testPowerPCFloatingPointLoadStoreAndAdd() {
        let memory = EmulatorMemory(size: 4096)
        let cpu = PowerPCCPU()

        memory.write32(at: 0x100, value: Float(1.5).bitPattern)
        memory.write32(at: 0x104, value: Float(2.25).bitPattern)

        // lfs f1, 0x100(r0)
        memory.write32(at: 0x000, value: 0xC0200100)
        // lfs f2, 0x104(r0)
        memory.write32(at: 0x004, value: 0xC0400104)
        // fadds f3, f1, f2
        memory.write32(at: 0x008, value: 0xEC61102A)
        // stfs f3, 0x108(r0)
        memory.write32(at: 0x00C, value: 0xD0610108)

        cpu.step(memory: memory)
        cpu.step(memory: memory)
        cpu.step(memory: memory)
        cpu.step(memory: memory)

        XCTAssertEqual(Float(bitPattern: memory.read32(at: 0x108)), 3.75, accuracy: 0.0001)
        XCTAssertEqual(cpu.programCounter, 0x10)
        XCTAssertNil(cpu.unsupportedInstruction)
    }
