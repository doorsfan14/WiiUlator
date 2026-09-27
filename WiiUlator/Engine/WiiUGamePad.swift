import Foundation
import Combine

struct WiiUAnalogStick: Equatable {
    var x: Float = 0
    var y: Float = 0

    mutating func reset() {
        x = 0
        y = 0
    }
}

struct WiiUGamePadState: Equatable {
    var buttons: UInt16 = 0
    var leftStick = WiiUAnalogStick()
    var rightStick = WiiUAnalogStick()
    var touchX: Float = 0
    var touchY: Float = 0
    var touchPressed = false

    mutating func reset() {
        buttons = 0
        leftStick.reset()
        rightStick.reset()
        touchX = 0
        touchY = 0
        touchPressed = false
    }
}

enum WiiUGamePadButton: UInt16 {
    case a = 1
    case b = 2
    case x = 4
    case y = 8
    case zl = 16
    case zr = 32
    case l = 64
    case r = 128
    case dpadUp = 256
    case dpadDown = 512
    case dpadLeft = 1024
    case dpadRight = 2048
    case plus = 4096
    case minus = 8192
    case home = 16384
    case sync = 32768
}

final class WiiUGamePad: ObservableObject {
    @Published private(set) var state = WiiUGamePadState()

    func setButton(_ button: WiiUGamePadButton, pressed: Bool) {
        let mask = button.rawValue
        if pressed {
            state.buttons |= mask
        } else {
            state.buttons &= ~mask
        }
    }

    func setLeftStick(x: Float, y: Float) {
        state.leftStick = WiiUAnalogStick(x: clamp(x), y: clamp(y))
    }

    func setRightStick(x: Float, y: Float) {
        state.rightStick = WiiUAnalogStick(x: clamp(x), y: clamp(y))
    }

    func setTouch(x: Float, y: Float, pressed: Bool) {
        state.touchX = min(max(x, 0), 1)
        state.touchY = min(max(y, 0), 1)
        state.touchPressed = pressed
    }

    func reset() {
        state.reset()
    }

    private func clamp(_ value: Float) -> Float {
        min(max(value, -1), 1)
    }
}

enum WiiURegion: String, CaseIterable, Identifiable {
    case usa = "USA"
    case europe = "EUR"
    case japan = "JPN"
    case korea = "KOR"

    var id: String { rawValue }

    var regionID: Int {
        switch self {
        case .japan: return 1
        case .usa: return 2
        case .europe: return 4
        case .korea: return 8
        }
    }
}

enum WiiUDisplayTarget: String {
    case television = "TV"
    case gamePad = "GamePad"
}

enum WiiUHardware {
    static let cpuArchitecture = "PowerPC 750-class"
    static let gamePadDisplaySize = (width: 854, height: 480)
    static let televisionNativeResolution = (width: 1280, height: 720)
    static let gamePadTouchResolution = (width: 854, height: 480)
}
