import Foundation

struct WiiURPXLinker {
    enum LinkError: LocalizedError {
        case unreadable
        case invalidSectionTable
        case invalidSymbolTable
        case invalidStringTable
        case unsupportedRelocation(UInt32)
        case unresolvedSymbol(String)

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "The RPX could not be read for linking."
            case .invalidSectionTable:
                return "The RPX contains an invalid ELF section table."
            case .invalidSymbolTable:
                return "The RPX contains an invalid symbol table."
            case .invalidStringTable:
                return "The RPX contains an invalid symbol string table."
            case .unsupportedRelocation(let type):
                return "The RPX uses unsupported PowerPC relocation type \(type)."
            case .unresolvedSymbol(let name):
                return "The RPX imports unresolved symbol \(name)."
            }
        }
    }

    private struct Section {
        let type: UInt32
        let address: UInt32
        let offset: UInt32
        let size: UInt32
        let link: UInt32
        let info: UInt32
        let entrySize: UInt32
    }

    private struct Symbol {
        let name: String
        let value: UInt32
        let sectionIndex: UInt16
    }

    func link(executable: WiiUExecutable, memory: EmulatorMemory, runtime: WiiUCafeRuntime) throws {
        guard let module = executable.module, module.isRPXLike else { return }
        guard let data = try? Data(contentsOf: executable.url) else {
            throw LinkError.unreadable
        }
        guard data.count >= 52 else { throw LinkError.invalidSectionTable }

        let sectionOffset = Int(read32(data, 32))
        let sectionSize = Int(read16(data, 46))
        let sectionCount = Int(read16(data, 48))
        guard sectionSize >= 40,
              sectionCount > 0,
              sectionOffset >= 0,
              sectionOffset <= data.count,
              sectionCount <= (data.count - sectionOffset) / sectionSize else {
            throw LinkError.invalidSectionTable
        }

        var sections: [Section] = []
        sections.reserveCapacity(sectionCount)

        for i in 0..<sectionCount {
            let o = sectionOffset + i * sectionSize
            let fileOffset = UInt64(read32(data, o + 16))
            let size = UInt64(read32(data, o + 20))
            guard fileOffset <= UInt64(data.count),
                  size <= UInt64(data.count) - fileOffset else {
                throw LinkError.invalidSectionTable
            }
            sections.append(
                Section(
                    type: read32(data, o + 4),
                    address: read32(data, o + 12),
                    offset: UInt32(fileOffset),
                    size: UInt32(size),
                    link: read32(data, o + 24),
                    info: read32(data, o + 28),
                    entrySize: read32(data, o + 36)
                )
            )
        }

        var symbols: [Symbol] = []
        for (index, section) in sections.enumerated() where section.type == 2 || section.type == 11 {
            let stringIndex = Int(section.link)
            guard stringIndex >= 0, stringIndex < sections.count else {
                throw LinkError.invalidSymbolTable
            }

            let strings = try stringBytes(data, section: sections[stringIndex])
            let entrySize = Int(section.entrySize == 0 ? 16 : section.entrySize)
            guard entrySize >= 16, Int(section.size) % entrySize == 0 else {
                throw LinkError.invalidSymbolTable
            }

            let count = Int(section.size) / entrySize
            symbols = []
            symbols.reserveCapacity(count)

            for i in 0..<count {
                let o = Int(section.offset) + i * entrySize
                let nameOffset = read32(data, o)
                let value = read32(data, o + 4)
                let shndx = read16(data, o + 14)
                let name = string(at: nameOffset, in: strings)
                symbols.append(Symbol(name: name, value: value, sectionIndex: shndx))
            }

            if index == sections.count - 1 { break }
        }

        for section in sections where section.type == 4 || section.type == 9 {
            let symbolIndex = Int(section.link)
            guard symbolIndex >= 0, symbolIndex < sections.count else {
                throw LinkError.invalidSymbolTable
            }

            let symbolSection = sections[symbolIndex]
            guard symbolSection.type == 2 || symbolSection.type == 11 else {
                throw LinkError.invalidSymbolTable
            }

            let stringsIndex = Int(symbolSection.link)
            guard stringsIndex >= 0, stringsIndex < sections.count else {
                throw LinkError.invalidStringTable
            }
            let strings = try stringBytes(data, section: sections[stringsIndex])

            let entrySize = Int(section.entrySize == 0 ? (section.type == 4 ? 12 : 8) : section.entrySize)
            guard entrySize >= (section.type == 4 ? 12 : 8),
                  Int(section.size) % entrySize == 0 else {
                throw LinkError.invalidSectionTable
            }

            let count = Int(section.size) / entrySize
            for i in 0..<count {
                let o = Int(section.offset) + i * entrySize
                let relocationAddress = read32(data, o)
                let info = read32(data, o + 4)
                let symbolNumber = Int(info >> 8)
                let type = info & 0xff
                let addend = section.type == 4 ? Int32(bitPattern: read32(data, o + 8)) : Int32(bitPattern: memory.read32(at: relocationAddress))

                guard symbolNumber >= 0, symbolNumber < symbols.count else {
                    throw LinkError.invalidSymbolTable
                }

                let symbol = symbols[symbolNumber]
                let target: UInt32
                if symbol.sectionIndex == 0 {
                    guard let imported = runtime.address(named: symbol.name) else {
                        throw LinkError.unresolvedSymbol(symbol.name)
                    }
                    target = imported
                } else {
                    target = symbol.value
                }

                try apply(
                    type: type,
                    target: target,
                    addend: addend,
                    place: relocationAddress,
                    memory: memory
                )
            }
        }
    }

    private func apply(
        type: UInt32,
        target: UInt32,
        addend: Int32,
        place: UInt32,
        memory: EmulatorMemory
    ) throws {
        let value = UInt32(bitPattern: Int32(bitPattern: target) &+ addend)
        var instruction = memory.read32(at: place)

        switch type {
        case 0:
            return
        case 1, 24:
            memory.write32(at: place, value: value)
        case 2:
            instruction = (instruction & 0xFC000003) | (value & 0x03FFFFFC)
            memory.write32(at: place, value: instruction)
        case 4:
            memory.write16(at: place, value: UInt16(value & 0xffff))
        case 5:
            memory.write16(at: place, value: UInt16((value >> 16) & 0xffff))
        case 6:
            memory.write16(at: place, value: UInt16((value &+ 0x8000) >> 16))
        case 10:
            let displacement = UInt32(bitPattern: Int32(bitPattern: target) &+ addend &- Int32(bitPattern: place))
            instruction = (instruction & 0xFC000003) | (displacement & 0x03FFFFFC)
            memory.write32(at: place, value: instruction)
        case 11, 12, 13:
            let displacement = UInt32(bitPattern: Int32(bitPattern: target) &+ addend &- Int32(bitPattern: place))
            instruction = (instruction & 0xFFFF0003) | (displacement & 0x0000FFFC)
            memory.write32(at: place, value: instruction)
        case 22:
            memory.write32(at: place, value: value)
        case 26:
            let displacement = UInt32(bitPattern: Int32(bitPattern: target) &+ addend &- Int32(bitPattern: place))
            memory.write32(at: place, value: displacement)
        default:
            throw LinkError.unsupportedRelocation(type)
        }
    }

    private func stringBytes(_ data: Data, section: Section) throws -> [UInt8] {
        let start = Int(section.offset)
        let end = start + Int(section.size)
        guard start >= 0, end <= data.count else {
            throw LinkError.invalidStringTable
        }
        return Array(data[start..<end])
    }

    private func string(at offset: UInt32, in bytes: [UInt8]) -> String {
        let start = Int(offset)
        guard start >= 0, start < bytes.count else { return "" }
        var end = start
        while end < bytes.count && bytes[end] != 0 { end += 1 }
        return String(bytes: bytes[start..<end], encoding: .utf8) ?? ""
    }

    private func read16(_ data: Data, _ offset: Int) -> UInt16 {
        UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
    }

    private func read32(_ data: Data, _ offset: Int) -> UInt32 {
        UInt32(data[offset]) << 24
            | UInt32(data[offset + 1]) << 16
            | UInt32(data[offset + 2]) << 8
            | UInt32(data[offset + 3])
    }
}
