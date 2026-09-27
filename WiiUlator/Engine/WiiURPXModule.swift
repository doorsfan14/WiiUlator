import Foundation

struct WiiURPXSection {
    let name: String
    let type: UInt32
    let flags: UInt32
    let address: UInt32
    let offset: UInt32
    let size: UInt32
    let alignment: UInt32
    let entrySize: UInt32
}

struct WiiURPXModule {
    let url: URL
    let entryPoint: UInt32
    let sections: [WiiURPXSection]
    let isRPXLike: Bool
}

enum WiiURPXModuleError: LocalizedError {
    case invalidSectionHeaders
    case invalidSectionStringTable
    case invalidSectionName

    var errorDescription: String? {
        switch self {
        case .invalidSectionHeaders:
            return "The RPX contains invalid section headers."
        case .invalidSectionStringTable:
            return "The RPX section-name table is invalid."
        case .invalidSectionName:
            return "The RPX contains an invalid section name."
        }
    }
}

struct WiiURPXModuleParser {
    func parse(data: Data, url: URL, entryPoint: UInt32) throws -> WiiURPXModule {
        guard data.count >= 52 else {
            throw WiiURPXModuleError.invalidSectionHeaders
        }

        let sectionHeaderOffset = Int(read32(data, at: 32))
        let sectionHeaderSize = Int(read16(data, at: 46))
        let sectionCount = Int(read16(data, at: 48))
        let sectionStringIndex = Int(read16(data, at: 50))

        guard sectionHeaderSize >= 40,
              sectionCount > 0,
              sectionHeaderOffset >= 0,
              sectionHeaderOffset <= data.count,
              sectionCount <= (data.count - sectionHeaderOffset) / sectionHeaderSize,
              sectionStringIndex < sectionCount else {
            throw WiiURPXModuleError.invalidSectionHeaders
        }

        var rawSections: [(nameIndex: UInt32, type: UInt32, flags: UInt32, address: UInt32, offset: UInt32, size: UInt32, alignment: UInt32, entrySize: UInt32)] = []
        rawSections.reserveCapacity(sectionCount)

        for index in 0..<sectionCount {
            let offset = sectionHeaderOffset + index * sectionHeaderSize
            let fileOffset = UInt64(read32(data, at: offset + 16))
            let size = UInt64(read32(data, at: offset + 20))

            guard fileOffset <= UInt64(data.count),
                  size <= UInt64(data.count) - fileOffset else {
                throw WiiURPXModuleError.invalidSectionHeaders
            }

            rawSections.append((
                nameIndex: read32(data, at: offset),
                type: read32(data, at: offset + 4),
                flags: read32(data, at: offset + 8),
                address: read32(data, at: offset + 12),
                offset: UInt32(fileOffset),
                size: UInt32(size),
                alignment: read32(data, at: offset + 32),
                entrySize: read32(data, at: offset + 36)
            ))
        }

        let stringSection = rawSections[sectionStringIndex]
        let stringStart = Int(stringSection.offset)
        let stringEnd = stringStart + Int(stringSection.size)

        guard stringStart >= 0, stringEnd <= data.count else {
            throw WiiURPXModuleError.invalidSectionStringTable
        }

        let stringTable = Array(data[stringStart..<stringEnd])

        func sectionName(_ index: UInt32) throws -> String {
            let start = Int(index)
            guard start >= 0, start < stringTable.count else {
                throw WiiURPXModuleError.invalidSectionName
            }

            var end = start
            while end < stringTable.count, stringTable[end] != 0 {
                end += 1
            }

            guard end <= stringTable.count else {
                throw WiiURPXModuleError.invalidSectionName
            }

            return String(bytes: stringTable[start..<end], encoding: .utf8) ?? ""
        }

        let sections = try rawSections.map {
            WiiURPXSection(
                name: try sectionName($0.nameIndex),
                type: $0.type,
                flags: $0.flags,
                address: $0.address,
                offset: $0.offset,
                size: $0.size,
                alignment: $0.alignment,
                entrySize: $0.entrySize
            )
        }

        let rpxNames = Set([
            ".code",
            ".data",
            ".sdata",
            ".rodata",
            ".bss",
            ".sbss",
            ".fini",
            ".text",
            ".rodata",
            ".rela.text"
        ])

        let isRPXLike = sections.contains { rpxNames.contains($0.name) }
            || url.pathExtension.lowercased() == "rpx"

        return WiiURPXModule(
            url: url,
            entryPoint: entryPoint,
            sections: sections,
            isRPXLike: isRPXLike
        )
    }

    private func read16(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
    }

    private func read32(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset]) << 24
            | UInt32(data[offset + 1]) << 16
            | UInt32(data[offset + 2]) << 8
            | UInt32(data[offset + 3])
    }
}
