import Foundation

struct WiiUExecutable {
    let url: URL
    let entryPoint: UInt32
    let loadSegments: [WiiULoadSegment]
    let fileSize: Int
    let module: WiiURPXModule?
}

struct WiiULoadSegment {
    let virtualAddress: UInt32
    let fileOffset: UInt32
    let fileSize: UInt32
    let memorySize: UInt32
    let flags: UInt32
}

enum WiiUExecutableLoaderError: LocalizedError {
    case unreadable
    case tooSmall
    case invalidMagic
    case unsupportedFormat
    case wrongArchitecture
    case invalidProgramHeaders
    case noLoadableSegments
    case segmentOutOfBounds

    var errorDescription: String? {
        switch self {
        case .unreadable:
            return "The selected executable could not be read."
        case .tooSmall:
            return "The executable is too small to contain a valid ELF header."
        case .invalidMagic:
            return "The file is not an ELF executable."
        case .unsupportedFormat:
            return "This executable is not a 32-bit big-endian Wii U ELF/RPX image."
        case .wrongArchitecture:
            return "The executable is not a PowerPC executable."
        case .invalidProgramHeaders:
            return "The executable contains invalid program headers."
        case .noLoadableSegments:
            return "The executable does not contain a loadable program segment."
        case .segmentOutOfBounds:
            return "A loadable segment extends beyond the executable file."
        }
    }
}

struct WiiUExecutableLoader {
    func inspect(url: URL) throws -> WiiUExecutable {
        guard let data = try? Data(contentsOf: url) else {
            throw WiiUExecutableLoaderError.unreadable
        }

        return try inspect(data: data, url: url)
    }

    func inspect(data: Data, url: URL) throws -> WiiUExecutable {
        guard data.count >= 52 else {
            throw WiiUExecutableLoaderError.tooSmall
        }

        guard data[0] == 0x7f,
              data[1] == 0x45,
              data[2] == 0x4c,
              data[3] == 0x46 else {
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

        var segments: [WiiULoadSegment] = []
        var module: WiiURPXModule?

        // RPX/RPL images use ELF section headers rather than a normal
        // executable program-header table. Keep standard ELF loading when
        // program headers are present, but fall back to allocatable sections
        // for Cafe modules.
        let hasValidProgramHeaders =
            programHeaderSize >= 32 &&
            programHeaderCount > 0 &&
            programHeaderOffset >= 0 &&
            programHeaderOffset <= data.count &&
            programHeaderCount <= (data.count - programHeaderOffset) / programHeaderSize

        if hasValidProgramHeaders {
            for index in 0..<programHeaderCount {
                let offset = programHeaderOffset + index * programHeaderSize
                let type = read32(data, at: offset)

                guard type == 1 else { continue }

                let flags = read32(data, at: offset + 24)
                let fileOffset = read32(data, at: offset + 4)
                let virtualAddress = read32(data, at: offset + 8)
                let fileSize = read32(data, at: offset + 16)
                let memorySize = read32(data, at: offset + 20)

                guard memorySize >= fileSize else {
                    throw WiiUExecutableLoaderError.invalidProgramHeaders
                }

                guard UInt64(fileOffset) + UInt64(fileSize) <= UInt64(data.count) else {
                    throw WiiUExecutableLoaderError.segmentOutOfBounds
                }

                segments.append(
                    WiiULoadSegment(
                        virtualAddress: virtualAddress,
                        fileOffset: fileOffset,
                        fileSize: fileSize,
                        memorySize: memorySize,
                        flags: flags
                    )
                )
            }
        } else {
            module = try? WiiURPXModuleParser().parse(
                data: data,
                url: url,
                entryPoint: entryPoint
            )

            guard let rpx = module, rpx.isRPXLike else {
                throw WiiUExecutableLoaderError.invalidProgramHeaders
            }

            let allocFlag: UInt32 = 0x2
            let noBitsType: UInt32 = 8

            for section in rpx.sections where (section.flags & allocFlag) != 0 {
                let isNoBits = section.type == noBitsType
                guard isNoBits || section.size > 0 else { continue }

                if !isNoBits {
                    guard UInt64(section.offset) + UInt64(section.size) <= UInt64(data.count) else {
                        throw WiiUExecutableLoaderError.segmentOutOfBounds
                    }
                }

                segments.append(
                    WiiULoadSegment(
                        virtualAddress: section.address,
                        fileOffset: section.offset,
                        fileSize: isNoBits ? 0 : section.size,
                        memorySize: section.size,
                        flags: section.flags
                    )
                )
            }
        }

        guard !segments.isEmpty else {
            throw WiiUExecutableLoaderError.noLoadableSegments
        }

        if module == nil {
            module = try? WiiURPXModuleParser().parse(
                data: data,
                url: url,
                entryPoint: entryPoint
            )
        }

        return WiiUExecutable(
            url: url,
            entryPoint: entryPoint,
            loadSegments: segments,
            fileSize: data.count,
            module: module
        )
    }

    func load(_ executable: WiiUExecutable, into memory: EmulatorMemory) throws {
        let data: Data
        do {
            data = try Data(contentsOf: executable.url)
        } catch {
            throw WiiUExecutableLoaderError.unreadable
        }

        for segment in executable.loadSegments {
            let start = Int(segment.fileOffset)
            let end = start + Int(segment.fileSize)
            guard start >= 0, end <= data.count else {
                throw WiiUExecutableLoaderError.segmentOutOfBounds
            }

            if segment.fileSize > 0 {
                memory.load(
                    Array(data[start..<end]),
                    at: segment.virtualAddress
                )
            }

            if segment.memorySize > segment.fileSize {
                memory.zero(
                    segment.memorySize - segment.fileSize,
                    at: segment.virtualAddress &+ segment.fileSize
                )
            }
        }
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
