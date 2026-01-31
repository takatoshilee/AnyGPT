//
//  AccessibilityHelper.swift
//  AnyGPT
//
//  Created on 2025
//

import Cocoa
import ApplicationServices

class AccessibilityHelper {
    static let shared = AccessibilityHelper()

    private var permissionGranted: Bool = false

    private init() {
        checkPermissions()
    }

    @discardableResult
    func checkPermissions() -> Bool {
        permissionGranted = AXIsProcessTrusted()
        return permissionGranted
    }

    func hasPermissions() -> Bool {
        return checkPermissions()
    }

    func requestPermissions() {
        if !hasPermissions() {
            showPermissionDialog()
        }
    }

    private func showPermissionDialog() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            AnyGPT needs accessibility permissions to:
            • Copy selected text (⌘C)
            • Paste results back (⌘V)

            Click "Open Settings" to grant permission in System Settings.
            You'll need to toggle AnyGPT in the list.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    private func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func sendCommandC() {
        guard hasPermissions() else {
            Logger.shared.log("Cannot send Cmd+C: No accessibility permissions", level: .error)
            return
        }

        sendKeyboardShortcut(keyCode: 0x08, flags: .maskCommand) // C key with Command
        Logger.shared.log("Sent Cmd+C", level: .debug)
    }

    func sendCommandV() {
        guard hasPermissions() else {
            Logger.shared.log("Cannot send Cmd+V: No accessibility permissions", level: .error)
            return
        }

        sendKeyboardShortcut(keyCode: 0x09, flags: .maskCommand) // V key with Command
        Logger.shared.log("Sent Cmd+V", level: .debug)
    }

    private func sendKeyboardShortcut(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down event
        if let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDownEvent.flags = flags
            keyDownEvent.post(tap: .cghidEventTap)
        }

        // Small delay between down and up
        usleep(10000) // 10ms

        // Key up event
        if let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUpEvent.flags = flags
            keyUpEvent.post(tap: .cghidEventTap)
        }
    }

    // Alternative method using AXUIElement (fallback if CGEvent fails)
    func sendKeyboardShortcutViaAX(keyCode: String, modifiers: [String]) {
        guard hasPermissions() else { return }

        if let systemWideElement = AXUIElementCreateSystemWide() as AXUIElement? {
            AXUIElementPostKeyboardEvent(systemWideElement, 0, keyCode as CFString, true)
            AXUIElementPostKeyboardEvent(systemWideElement, 0, keyCode as CFString, false)
        }
    }

    // Check if we're in a text field that can accept paste
    func canPasteInCurrentContext() -> Bool {
        guard hasPermissions() else { return false }

        // Get the focused element
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(
            systemWideElement as CFTypeRef,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        if result == .success, let element = focusedElement {
            // Check if it's a text field or text area
            var role: CFTypeRef?
            AXUIElementCopyAttributeValue(
                element as! AXUIElement,
                kAXRoleAttribute as CFString,
                &role
            )

            if let roleString = role as? String {
                let textRoles = [
                    kAXTextFieldRole,
                    kAXTextAreaRole,
                    kAXComboBoxRole,
                    kAXStaticTextRole
                ]

                return textRoles.contains(roleString as CFString)
            }
        }

        return true // Default to true if we can't determine
    }

    // Test function to verify accessibility is working
    func testAccessibility() -> Bool {
        guard hasPermissions() else {
            Logger.shared.log("Accessibility test failed: No permissions", level: .error)
            return false
        }

        // Try to get the focused element
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(
            systemWideElement as CFTypeRef,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        if result == .success {
            Logger.shared.log("Accessibility test passed", level: .info)
            return true
        } else {
            Logger.shared.log("Accessibility test failed: \(result.rawValue)", level: .error)
            return false
        }
    }
}