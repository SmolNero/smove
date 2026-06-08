import Carbon
import Foundation

struct KeyCombo {
    let keyCode: UInt32
    let modifiers: UInt32

    static func parse(_ binding: String) -> KeyCombo? {
        let parts = binding
            .lowercased()
            .split(separator: "+")
            .map { String($0) }

        guard let key = parts.last, let keyCode = keyCodes[key] else {
            return nil
        }

        var modifiers: UInt32 = 0

        for part in parts.dropLast() {
            switch part {
            case "cmd", "command":
                modifiers |= UInt32(cmdKey)
            case "alt", "option", "opt":
                modifiers |= UInt32(optionKey)
            case "ctrl", "control":
                modifiers |= UInt32(controlKey)
            case "shift":
                modifiers |= UInt32(shiftKey)
            default:
                return nil
            }
        }

        return KeyCombo(keyCode: keyCode, modifiers: modifiers)
    }
}

private let keyCodes: [String: UInt32] = [
    "a": 0,
    "s": 1,
    "d": 2,
    "f": 3,
    "h": 4,
    "g": 5,
    "z": 6,
    "x": 7,
    "c": 8,
    "v": 9,
    "b": 11,
    "q": 12,
    "w": 13,
    "e": 14,
    "r": 15,
    "y": 16,
    "t": 17,
    "1": 18,
    "2": 19,
    "3": 20,
    "4": 21,
    "6": 22,
    "5": 23,
    "=": 24,
    "9": 25,
    "7": 26,
    "-": 27,
    "8": 28,
    "0": 29,
    "]": 30,
    "o": 31,
    "u": 32,
    "[": 33,
    "i": 34,
    "p": 35,
    "l": 37,
    "j": 38,
    "'": 39,
    "k": 40,
    ";": 41,
    "\\": 42,
    ",": 43,
    "/": 44,
    "n": 45,
    "m": 46,
    ".": 47,
    "tab": 48,
    "space": 49,
    "`": 50,
    "escape": 53,
    "esc": 53,
    "left": 123,
    "right": 124,
    "down": 125,
    "up": 126
]
