import Foundation

public final class WiiUMemory {
    private static let pageSize = 0x1000
    private var pages: [UInt32: [UInt8]] = [:]

    public func reset() {
        pages.removeAll(keepingCapacity: true)
    }

    public func read8(_ address: UInt32) -> UInt8 {
        let page = address >> 12
        guard let bytes = pages[page] else { return 0 }
        return bytes[Int(address & 0xFFF)]
    }

    public func read16(_ address: UInt32) -> UInt32 {
        let page = address >> 12
        let offset = Int(address & 0xFFF)
        if let bytes = pages[page], offset < Self.pageSize - 1 {
            return (UInt32(bytes[offset]) << 8) | UInt32(bytes[offset + 1])
        }
        return (UInt32(read8(address)) << 8) | UInt32(read8(address &+ 1))
    }

    public func read32(_ address: UInt32) -> UInt32 {
        let page = address >> 12
        let offset = Int(address & 0xFFF)
        if let bytes = pages[page], offset <= Self.pageSize - 4 {
            return (UInt32(bytes[offset]) << 24)
                | (UInt32(bytes[offset + 1]) << 16)
                | (UInt32(bytes[offset + 2]) << 8)
                | UInt32(bytes[offset + 3])
        }
        return (UInt32(read8(address)) << 24)
            | (UInt32(read8(address &+ 1)) << 16)
            | (UInt32(read8(address &+ 2)) << 8)
            | UInt32(read8(address &+ 3))
    }

    public func write8(_ address: UInt32, _ value: UInt8) {
        let page = address >> 12
        if pages[page] == nil {
            pages[page] = Array(repeating: 0, count: Self.pageSize)
        }
        pages[page]![Int(address & 0xFFF)] = value
    }

    public func write16(_ address: UInt32, _ value: UInt32) {
        write8(address, UInt8((value >> 8) & 0xFF))
        write8(address &+ 1, UInt8(value & 0xFF))
    }

    public func write32(_ address: UInt32, _ value: UInt32) {
        write8(address, UInt8((value >> 24) & 0xFF))
        write8(address &+ 1, UInt8((value >> 16) & 0xFF))
        write8(address &+ 2, UInt8((value >> 8) & 0xFF))
        write8(address &+ 3, UInt8(value & 0xFF))
    }

    public func load(_ data: Data, at address: UInt32) {
        for (offset, byte) in data.enumerated() {
            write8(address &+ UInt32(offset), byte)
        }
    }

    public func zero(count: UInt32, at address: UInt32) {
        guard count > 0 else { return }
        for offset in 0..<count {
            write8(address &+ offset, 0)
        }
    }
}
