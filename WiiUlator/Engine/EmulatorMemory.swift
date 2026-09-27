import Foundation

struct EmulatorMemoryRegion {
    let name: String
    let start: UInt32
    let size: UInt32
    let readable: Bool
    let writable: Bool
    let executable: Bool

    var end: UInt32 {
        start &+ size
    }

    func contains(_ address: UInt32) -> Bool {
        address >= start && address < end
    }
}

final class EmulatorMemory {
    static let pageSize = 0x1000

    let regions: [EmulatorMemoryRegion]
    private var pages: [UInt32: [UInt8]] = [:]

    init(size: Int = 64 * 1024 * 1024) {
        _ = size

        regions = [
            EmulatorMemoryRegion(
                name: "Codegen / JIT",
                start: 0x01800000,
                size: 0x00020000,
                readable: true,
                writable: true,
                executable: true
            ),
            EmulatorMemoryRegion(
                name: "Application Code",
                start: 0x02000000,
                size: 0x0E000000,
                readable: true,
                writable: true,
                executable: true
            ),
            EmulatorMemoryRegion(
                name: "Application Data",
                start: 0x10000000,
                size: 0x52000000,
                readable: true,
                writable: true,
                executable: false
            ),
            EmulatorMemoryRegion(
                name: "Hardware",
                start: 0xE0000000,
                size: 0x04000000,
                readable: true,
                writable: true,
                executable: false
            )
        ]
    }

    func reset() {
        pages.removeAll(keepingCapacity: true)
    }

    func load(_ data: [UInt8], at address: UInt32) {
        guard !data.isEmpty else { return }

        for (offset, byte) in data.enumerated() {
            write8(at: address &+ UInt32(offset), value: byte)
        }
    }

    func zero(_ count: UInt32, at address: UInt32) {
        guard count > 0 else { return }

        for offset in 0..<count {
            write8(at: address &+ offset, value: 0)
        }
    }

    func read8(at address: UInt32) -> UInt8 {
        let page = pageNumber(for: address)
        guard let storage = pages[page] else { return 0 }
        return storage[pageOffset(for: address)]
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
        let page = pageNumber(for: address)
        if pages[page] == nil {
            pages[page] = Array(repeating: 0, count: Self.pageSize)
        }
        pages[page]![pageOffset(for: address)] = value
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

    func contains(_ address: UInt32) -> Bool {
        regions.contains { $0.contains(address) }
    }

    private func pageNumber(for address: UInt32) -> UInt32 {
        address >> 12
    }

    private func pageOffset(for address: UInt32) -> Int {
        Int(address & 0xFFF)
    }
}
