//
//  HotkeyManager.swift
//  AnyGPT
//
//  Created on 2025
//

import Cocoa
import Carbon

class HotkeyManager {
    private var eventHotKeyRef: EventHotKeyRef?
    private var lastTriggerTime: Date?
    private let debounceInterval: TimeInterval = 0.5 // 500ms debounce

    var onHotkeyPressed: (() -> Void)?

    // Default hotkey: Cmd+Option+`
    private var keyCode: UInt32 = 50 // Backtick key
    private var modifierFlags: UInt32 = cmdKey | optionKey

    private static var sharedManager: HotkeyManager?

    init() {
        HotkeyManager.sharedManager = self
        loadHotkeyPreferences()
    }

    deinit {
        unregister()
    }

    func register() {
        unregister() // Unregister any existing hotkey first

        let hotkeyID = EventHotKeyID(signature: OSType(0x414E5947), id: 1) // 'ANYG' in hex
        var eventHotKey: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )

        if status == noErr {
            eventHotKeyRef = eventHotKey
            installEventHandler()
            Logger.shared.log("Hotkey registered successfully", level: .info)
        } else {
            Logger.shared.log("Failed to register hotkey: \(status)", level: .error)
        }
    }

    func unregister() {
        if let hotKeyRef = eventHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            eventHotKeyRef = nil
            Logger.shared.log("Hotkey unregistered", level: .info)
        }
    }

    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifierFlags = modifiers
        saveHotkeyPreferences()
        register() // Re-register with new hotkey
    }

    func shouldProcessHotkey() async -> Bool {
        let now = Date()

        if let lastTime = lastTriggerTime {
            let timeSinceLastTrigger = now.timeIntervalSince(lastTime)
            if timeSinceLastTrigger < debounceInterval {
                return false
            }
        }

        lastTriggerTime = now
        return true
    }

    private func loadHotkeyPreferences() {
        if let savedKeyCode = UserDefaults.standard.object(forKey: "hotkeyCode") as? UInt32 {
            keyCode = savedKeyCode
        }
        if let savedModifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 {
            modifierFlags = savedModifiers
        }
    }

    private func saveHotkeyPreferences() {
        UserDefaults.standard.set(keyCode, forKey: "hotkeyCode")
        UserDefaults.standard.set(modifierFlags, forKey: "hotkeyModifiers")
    }

    private func installEventHandler() {
        let eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotkeyHandler, 1, [eventSpec], nil, nil)
    }

    // Carbon event handler function
    private let hotkeyHandler: EventHandlerUPP = { _, _, _ in
        DispatchQueue.main.async {
            HotkeyManager.sharedManager?.onHotkeyPressed?()
        }
        return noErr
    }

    // Helper methods for converting between Carbon and Cocoa key codes
    static func carbonKeyCode(from keyCode: Int) -> UInt32 {
        // Common key mappings
        switch keyCode {
        case 0: return 0x00    // A
        case 11: return 0x0B   // B
        case 8: return 0x08    // C
        case 2: return 0x02    // D
        case 14: return 0x0E   // E
        case 3: return 0x03    // F
        case 5: return 0x05    // G
        case 4: return 0x04    // H
        case 34: return 0x22   // I
        case 38: return 0x26   // J
        case 40: return 0x28   // K
        case 37: return 0x25   // L
        case 46: return 0x2E   // M
        case 45: return 0x2D   // N
        case 31: return 0x1F   // O
        case 35: return 0x23   // P
        case 12: return 0x0C   // Q
        case 15: return 0x0F   // R
        case 1: return 0x01    // S
        case 17: return 0x11   // T
        case 32: return 0x20   // U
        case 9: return 0x09    // V
        case 13: return 0x0D   // W
        case 7: return 0x07    // X
        case 16: return 0x10   // Y
        case 6: return 0x06    // Z
        case 50: return 0x32   // Backtick
        case 49: return 0x31   // Space
        case 36: return 0x24   // Return
        case 51: return 0x33   // Delete
        case 53: return 0x35   // Escape
        default: return UInt32(keyCode)
        }
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0

        if flags.contains(.command) {
            carbonFlags |= cmdKey
        }
        if flags.contains(.option) {
            carbonFlags |= optionKey
        }
        if flags.contains(.control) {
            carbonFlags |= controlKey
        }
        if flags.contains(.shift) {
            carbonFlags |= shiftKey
        }

        return carbonFlags >> 8 // Carbon uses different bit positions
    }

    static func hotkeyDisplayString(keyCode: UInt32, modifiers: UInt32) -> String {
        var parts: [String] = []

        if modifiers & cmdKey != 0 {
            parts.append("⌘")
        }
        if modifiers & controlKey != 0 {
            parts.append("⌃")
        }
        if modifiers & optionKey != 0 {
            parts.append("⌥")
        }
        if modifiers & shiftKey != 0 {
            parts.append("⇧")
        }

        // Add key character
        let keyChar = keyCharacter(from: keyCode)
        parts.append(keyChar)

        return parts.joined()
    }

    private static func keyCharacter(from keyCode: UInt32) -> String {
        switch keyCode {
        case 0x32: return "`"
        case 0x31: return "Space"
        case 0x24: return "Return"
        case 0x33: return "Delete"
        case 0x35: return "Esc"
        case 0x00: return "A"
        case 0x0B: return "B"
        case 0x08: return "C"
        case 0x02: return "D"
        case 0x0E: return "E"
        case 0x03: return "F"
        case 0x05: return "G"
        case 0x04: return "H"
        case 0x22: return "I"
        case 0x26: return "J"
        case 0x28: return "K"
        case 0x25: return "L"
        case 0x2E: return "M"
        case 0x2D: return "N"
        case 0x1F: return "O"
        case 0x23: return "P"
        case 0x0C: return "Q"
        case 0x0F: return "R"
        case 0x01: return "S"
        case 0x11: return "T"
        case 0x20: return "U"
        case 0x09: return "V"
        case 0x0D: return "W"
        case 0x07: return "X"
        case 0x10: return "Y"
        case 0x06: return "Z"
        default: return "?"
        }
    }
}