import Foundation

final class EmulatorMemory {
    let size: Int
    private var storage: [UInt8]

    init(size: Int) {
        precondition(size > 0)
        self.size = size
        self.storage = Array(repeating: 0, count: size)
    }

    func reset() {
        storage = Array(repeating: 0, count: size)
    }

    func read8(at address: UInt32) -> UInt8 {
        storage[index(for: address)]
    }

    func read16(at address: UInt32) -> UInt16 {
        let a = index(for: address)
        return UInt16(storage[a]) << 8 | UInt16(storage[index(for: address &+ 1)])
    }

    func read32(at address: UInt32) -> UInt32 {
        let a = index(for: address)
        return UInt32(storage[a]) << 24
            | UInt32(storage[index(for: address &+ 1)]) << 16
            | UInt32(storage[index(for: address &+ 2)]) << 8
            | UInt32(storage[index(for: address &+ 3)])
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
