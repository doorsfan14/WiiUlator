import Foundation

struct EmulatorMemoryRegion {
    let name: String
    let start: UInt32
    let size: UInt32
    let readable: Bool
    let writable: Bool

    var end: UInt32 {
        start &+ size
    }

    func contains(_ address: UInt32) -> Bool {
        address >= start && address < end
    }
}

final class EmulatorMemory {
    let size: Int
    private var storage: [UInt8]
    let regions: [EmulatorMemoryRegion]

    init(size: Int = 64 * 1024 * 1024) {
        precondition(size > 0)
        self.size = size
        self.storage = Array(repeating: 0, count: size)

        regions = [
            EmulatorMemoryRegion(
                name: "Homebrew App",
                start: 0x02000000,
                size: UInt32(min(size, 0x01000000)),
                readable: true,
                writable: true
            ),
            EmulatorMemoryRegion(
                name: "Application Data",
                start: 0x10000000,
                size: 0x01000000,
                readable: true,
                writable: true
            )
        ]
    }

    func reset() {
        storage = Array(repeating: 0, count: size)
    }

    func load(_ data: [UInt8], at address: UInt32) {
        precondition(Int(address) + data.count <= size)
        for (offset, byte) in data.enumerated() {
            storage[Int(address) + offset] = byte
        }
    }

    func read8(at address: UInt32) -> UInt8 {
        storage[index(for: address)]
    }

    func read16(at address: UInt32) -> UInt16 {
        UInt16(read8(at: address)) << 8
            | UInt16(read8(at: address &+ 1))
    }

    func read32(at address: UInt32) -> UInt32 {
        UInt32(read8(at: address)) << 24
            | UInt32(read8(at: address &+ 1)) << 16
            | UInt32(read8(at: address &+ 2)) << 8
            | UInt32(read8(at: address &+ 3))
    }

    func write8(at address: UInt32, value: UInt8) {
        storage[index(for: address)] = value
    }

    func write16(at address: UInt32, value: UInt16) {
        write8(at: address, value: UInt8(value >> 8))
        write8(at: address &+ 1, value: UInt8(value & 0xff))
    }

    func write32(at address: UInt32, value: UInt32) {
        write8(at: address, value: UInt8((value >> 24) & 0xff))
        write8(at: address &+ 1, value: UInt8((value >> 16) & 0xff))
        write8(at: address &+ 2, value: UInt8((value >> 8) & 0xff))
        write8(at: address &+ 3, value: UInt8(value & 0xff))
    }

    private func index(for address: UInt32) -> Int {
        Int(address) % size
    }
}
