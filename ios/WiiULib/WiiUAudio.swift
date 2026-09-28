import Foundation

public final class WiiUAudio {
    public static let sampleRate = 48_000
    public static let channels = 2
    public static let blockSamples = 512

    private var buffer = [Int16](repeating: 0, count: blockSamples * channels)
    private var writePosition = 0
    public private(set) var enabled = true
    public private(set) var volume: Float = 1

    public init() {}

    public func reset() {
        buffer = [Int16](repeating: 0, count: Self.blockSamples * Self.channels)
        writePosition = 0
    }

    public func setEnabled(_ value: Bool) { enabled = value }
    public func setVolume(_ value: Float) { volume = min(1, max(0, value)) }
    public var queuedSamples: Int { writePosition / Self.channels }

    public func submit(_ samples: [Int16], sampleCount: Int) {
        guard enabled, sampleCount > 0 else { return }
        let frames = min(sampleCount, buffer.count / Self.channels)
        for i in 0..<(frames * Self.channels) {
            let scaled = Int((Float(samples[i]) * volume).rounded())
            buffer[i] = Int16(clamping: scaled)
        }
        writePosition = frames * Self.channels
    }

    public func consume() -> [Int16] {
        let output = Array(buffer[0..<writePosition])
        writePosition = 0
        return output
    }
}
