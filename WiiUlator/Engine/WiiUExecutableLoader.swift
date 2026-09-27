import Foundation

struct WiiUExecutable {
    let url: URL
    let entryPoint: UInt32
    let loadSegments: [WiiULoadSegment]
}

struct WiiULoadSegment {
    let virtualAddress: UInt32
    let fileOffset: UInt32
    let fileSize: UInt32
    let memorySize: UInt32
}

enum WiiUExecutableLoaderError: LocalizedError {
    case unreadable
    case tooSmall
    case invalidMagic
    case unsupportedFormat
    case wrongArchitecture
    case invalidProgramHeaders
    case noLoadableSegments

    var errorDescription: String? {
        switch self {
        case .unreadable: return "The selected file could not be read."
        case .tooSmall: return "The executable is too small to contain a valid ELF header."
        case .invalidMagic: return "The file is not an ELF executable."
        case .unsupportedFormat: return "This ELF format is not supported yet. Wii Ulator currently expects 32-bit big-endian executables."
        case .wrongArchitecture: return "The executable is not a PowerPC executable."
        case .invalidProgramHeaders: return "The executable contains invalid program headers."
        case .noLoadableSegments: return "The executable does not contain a loadable program segment."
        }
    }
}

struct WiiUExecutableLoader {
    func inspect(url: URL) throws -> WiiUExecutable {
        guard let data = try? Data(contentsOf: url) else {
            throw WiiUExecutableLoaderError.unreadable
        }

        guard data.count >= 52 else {
            throw WiiUExecutableLoaderError.tooSmall
        }

        guard data[0] == 0x7f, data[1] == 0x45, data[2] == 0x4c, data[3] == 0x46 else {
            throw WiiUExecutableLoaderError.invalidMagic
        }

        guard data[4] == 1, data[5] == 2 else {
            throw WiiUExecutableLoaderError.unsupportedFormat
        }

        let machine = read16(data, at: 18)
        guard machine == 20 else {
            throw WiiUExecutableLoaderError.wrongArchitecture
        }

        let entryPoint = read32(data, at: 24)
        let programHeaderOffset = Int(read32(data, at: 28))
        let programHeaderSize = Int(read16(data, at: 42))
        let programHeaderCount = Int(read16(data, at: 44))

        guard programHeaderSize >= 32,
              programHeaderOffset >= 0,
              programHeaderCount > 0,
              programHeaderOffset + programHeaderSize * programHeaderCount <= data.count else {
            throw WiiUExecutableLoaderError.invalidProgramHeaders
        }

        var segments: [WiiULoadSegment] = []

        for index in 0..<programHeaderCount {
            let offset = programHeaderOffset + index * programHeaderSize
            let type = read32(data, at: offset)

            guard type == 1 else { continue }

            let fileOffset = read32(data, at: offset + 4)
            let virtualAddress = read32(data, at: offset + 8)
            let fileSize = read32(data, at: offset + 16)
            let memorySize = read32(data, at: offset + 20)

            guard UInt64(fileOffset) + UInt64(fileSize) <= UInt64(data.count),
                  memorySize >= fileSize else {
                throw WiiUExecutableLoaderError.invalidProgramHeaders
            }

            segments.append(
                WiiULoadSegment(
                    virtualAddress: virtualAddress,
                    fileOffset: fileOffset,
                    fileSize: fileSize,
                    memorySize: memorySize
                )
            )
        }

        guard !segments.isEmpty else {
            throw WiiUExecutableLoaderError.noLoadableSegments
        }

        return WiiUExecutable(
            url: url,
            entryPoint: entryPoint,
            loadSegments: segments
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
