import Foundation

public enum WiiULibError: Error {
    case invalidELF
    case unsupportedELF
    case invalidLoadSegment
    case invalidSections
    case noLoadableSegments
}

public final class WiiULib {
    public let memory = WiiUMemory()
    public let cpu = PowerPCCPU()
    public private(set) var instructionCount: UInt64 = 0
    public private(set) var entryPoint: UInt32 = 0

    public func reset() {
        memory.reset()
        cpu.reset()
        instructionCount = 0
        entryPoint = 0
    }

    public func load(data: Data, at address: UInt32, entryPoint: UInt32) {
        reset()
        memory.load(data, at: address)
        self.entryPoint = entryPoint
        cpu.pc = entryPoint
    }

    public func run(instructions count: Int) {
        guard count > 0 else { return }
        for _ in 0..<count {
            cpu.step(memory: memory)
            instructionCount += 1
            if cpu.unsupportedInstruction != 0 {
                break
            }
        }
    }

    public func loadELF(_ data: Data) throws {
        guard data.count >= 52,
              data[data.startIndex] == 0x7F,
              data[data.startIndex + 1] == 0x45,
              data[data.startIndex + 2] == 0x4C,
              data[data.startIndex + 3] == 0x46 else {
            throw WiiULibError.invalidELF
        }

        guard data[data.startIndex + 4] == 1, data[data.startIndex + 5] == 2 else {
            throw WiiULibError.unsupportedELF
        }

        guard read16(data, 18) == 20 else {
            throw WiiULibError.unsupportedELF
        }

        let entry = read32(data, 24)
        let programHeaderOffset = Int(read32(data, 28))
        let programHeaderSize = Int(read16(data, 42))
        let programHeaderCount = Int(read16(data, 44))
        var loaded = false

        if programHeaderSize >= 32,
           programHeaderOffset >= 0,
           programHeaderCount > 0,
           programHeaderOffset <= data.count,
           programHeaderCount <= (data.count - programHeaderOffset) / programHeaderSize {

            for index in 0..<programHeaderCount {
                let offset = programHeaderOffset + index * programHeaderSize
                if read32(data, offset) != 1 { continue }

                let fileOffset = Int(read32(data, offset + 4))
                let virtualAddress = read32(data, offset + 8)
                let fileSize = Int(read32(data, offset + 16))
                let memorySize = Int(read32(data, offset + 20))

                guard fileOffset >= 0,
                      fileSize >= 0,
                      memorySize >= fileSize,
                      fileOffset <= data.count,
                      fileSize <= data.count - fileOffset else {
                    throw WiiULibError.invalidLoadSegment
                }

                memory.load(data.subdata(in: fileOffset..<(fileOffset + fileSize)), at: virtualAddress)
                if memorySize > fileSize {
                    memory.zero(count: UInt32(memorySize - fileSize), at: virtualAddress &+ UInt32(fileSize))
                }
                loaded = true
            }
        }

        if !loaded {
            let sectionHeaderOffset = Int(read32(data, 32))
            let sectionHeaderSize = Int(read16(data, 46))
            let sectionHeaderCount = Int(read16(data, 48))

            guard sectionHeaderSize >= 40,
                  sectionHeaderCount > 0,
                  sectionHeaderOffset >= 0,
                  sectionHeaderOffset <= data.count,
                  sectionHeaderCount <= (data.count - sectionHeaderOffset) / sectionHeaderSize else {
                throw WiiULibError.invalidSections
            }

            for index in 0..<sectionHeaderCount {
                let offset = sectionHeaderOffset + index * sectionHeaderSize
                let type = read32(data, offset + 4)
                let flags = read32(data, offset + 8)
                let virtualAddress = read32(data, offset + 12)
                let fileOffset = Int(read32(data, offset + 16))
                let size = Int(read32(data, offset + 20))

                guard (flags & 2) != 0 else { continue }

                if type == 8 {
                    memory.zero(count: UInt32(size), at: virtualAddress)
                } else {
                    guard fileOffset >= 0,
                          size >= 0,
                          fileOffset <= data.count,
                          size <= data.count - fileOffset else {
                        throw WiiULibError.invalidLoadSegment
                    }
                    memory.load(data.subdata(in: fileOffset..<(fileOffset + size)), at: virtualAddress)
                }
                loaded = true
            }
        }

        guard loaded else { throw WiiULibError.noLoadableSegments }

        entryPoint = entry
        cpu.pc = entry
        instructionCount = 0
    }

    private func read16(_ data: Data, _ offset: Int) -> UInt16 {
        (UInt16(data[data.startIndex + offset]) << 8)
        | UInt16(data[data.startIndex + offset + 1])
    }

    private func read32(_ data: Data, _ offset: Int) -> UInt32 {
        (UInt32(data[data.startIndex + offset]) << 24)
        | (UInt32(data[data.startIndex + offset + 1]) << 16)
        | (UInt32(data[data.startIndex + offset + 2]) << 8)
        | UInt32(data[data.startIndex + offset + 3])
    }
}
