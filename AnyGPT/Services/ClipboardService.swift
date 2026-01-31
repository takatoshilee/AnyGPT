//
//  ClipboardService.swift
//  AnyGPT
//
//  Created on 2025
//

import Cocoa

class ClipboardService {
    static let shared = ClipboardService()

    private let pasteboard = NSPasteboard.general

    private init() {}

    func readText() -> String? {
        let types = [NSPasteboard.PasteboardType.string]
        guard pasteboard.canReadItem(withDataConformingToTypes: types) else {
            Logger.shared.log("No text available in clipboard", level: .debug)
            return nil
        }

        let text = pasteboard.string(forType: .string)

        if let text = text, !text.isEmpty {
            Logger.shared.log("Read \(text.count) characters from clipboard", level: .debug)
            return text
        }

        return nil
    }

    func writeText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        Logger.shared.log("Wrote \(text.count) characters to clipboard", level: .debug)
    }

    func clear() {
        pasteboard.clearContents()
        Logger.shared.log("Clipboard cleared", level: .debug)
    }

    // Get character count without reading full content (for performance)
    func getTextLength() -> Int? {
        if let text = readText() {
            return text.count
        }
        return nil
    }

    // Check if clipboard has text without reading it
    func hasText() -> Bool {
        let types = [NSPasteboard.PasteboardType.string]
        return pasteboard.canReadItem(withDataConformingToTypes: types)
    }

    // Save current clipboard state (for restoration if needed)
    func saveState() -> String? {
        return readText()
    }

    // Restore clipboard state
    func restoreState(_ state: String?) {
        if let state = state {
            writeText(state)
        }
    }

    // Handle large text with truncation warning
    func processLargeText(_ text: String, maxLength: Int = 8000) -> (text: String, wasTruncated: Bool) {
        if text.count > maxLength {
            let truncatedText = String(text.prefix(maxLength))
            Logger.shared.log("Text truncated from \(text.count) to \(maxLength) characters", level: .warning)
            return (truncatedText, true)
        }
        return (text, false)
    }

    // Monitor clipboard changes (useful for clipboard managers)
    func startMonitoring(onChange: @escaping (String?) -> Void) -> Timer {
        var lastChangeCount = pasteboard.changeCount

        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let currentChangeCount = self.pasteboard.changeCount

            if currentChangeCount != lastChangeCount {
                lastChangeCount = currentChangeCount
                let newText = self.readText()
                onChange(newText)
            }
        }

        return timer
    }

    // Format clipboard content for logging (sanitized)
    func sanitizedContent() -> String {
        guard let text = readText() else {
            return "<empty>"
        }

        if text.count <= 50 {
            return text
        }

        let preview = String(text.prefix(25)) + "..." + String(text.suffix(25))
        return "\(preview) (\(text.count) chars total)"
    }
}