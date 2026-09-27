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
    case a = 1 << 0
    case b = 1 << 1
    case x = 1 << 2
    case y = 1 << 3
    case zl = 1 << 4
    case zr = 1 << 5
    case l = 1 << 6
    case r = 1 << 7
    case dpadUp = 1 << 8
    case dpadDown = 1 << 9
    case dpadLeft = 1 << 10
    case dpadRight = 1 << 11
    case plus = 1 << 12
    case minus = 1 << 13
    case home = 1 << 14
    case sync = 1 << 15
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
