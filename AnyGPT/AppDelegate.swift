//
//  AppDelegate.swift
//  AnyGPT
//
//  Created on 2025
//

import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var preferencesViewController: PreferencesViewController!
    private var hotkeyManager: HotkeyManager!
    private var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Configure app as menu bar only (agent)
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar item
        setupStatusItem()

        // Initialize preferences UI
        setupPreferences()

        // Initialize hotkey manager
        setupHotkey()

        // Setup event monitor for clicking outside popover
        setupEventMonitor()

        // Request notification permissions
        requestNotificationPermissions()

        // Check accessibility permissions
        AccessibilityHelper.shared.checkPermissions()

        // Initialize logger
        Logger.shared.log("AnyGPT launched", level: .info)

        // Check for API key on launch
        checkAPIKeyStatus()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "command", accessibilityDescription: "AnyGPT")
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPreferences() {
        preferencesViewController = PreferencesViewController()

        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = preferencesViewController
    }

    private func setupHotkey() {
        hotkeyManager = HotkeyManager()

        hotkeyManager.onHotkeyPressed = { [weak self] in
            Task {
                await self?.handleHotkeyTrigger()
            }
        }

        hotkeyManager.register()
    }

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover.isShown == true {
                self?.closePopover()
            }
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                Logger.shared.log("Notification permissions granted", level: .info)
            } else {
                Logger.shared.log("Notification permissions denied", level: .warning)
            }
        }
    }

    private func checkAPIKeyStatus() {
        do {
            _ = try KeychainService.shared.retrieveAPIKey()
        } catch {
            // API key not found, will prompt user when they first use the hotkey
            Logger.shared.log("No API key found in keychain", level: .info)
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            if popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }

    private func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()

            // Highlight the button
            button.highlight(true)
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()

        // Remove highlight
        statusItem.button?.highlight(false)
    }

    private func showContextMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Test with Sample Text", action: #selector(testWithSample), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reveal Logs", action: #selector(revealLogs), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About AnyGPT", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // Remove menu after showing
    }

    @objc private func showPreferences() {
        showPopover()
    }

    @objc private func testWithSample() {
        Task {
            let sampleText = "This is a sample text for testing AnyGPT functionality."
            await processThroughLLM(text: sampleText, isTest: true)
        }
    }

    @objc private func revealLogs() {
        Logger.shared.revealLogsInFinder()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "AnyGPT"
        alert.informativeText = "Version 1.0.0\n\nGPT anywhere on your Mac.\nSelect text, press your hotkey, get AI-powered results instantly.\n\nVisit anygpt.dev for more information."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func handleHotkeyTrigger() async {
        // Check debounce
        guard await hotkeyManager.shouldProcessHotkey() else {
            Logger.shared.log("Hotkey debounced", level: .debug)
            return
        }

        // Animate status bar icon
        animateStatusIcon(processing: true)

        // Check accessibility permissions
        guard AccessibilityHelper.shared.hasPermissions() else {
            AccessibilityHelper.shared.requestPermissions()
            animateStatusIcon(processing: false)
            return
        }

        // Send Cmd+C to copy selection
        AccessibilityHelper.shared.sendCommandC()

        // Wait for clipboard to update
        try? await Task.sleep(nanoseconds: 250_000_000) // 250ms

        // Read clipboard
        guard let text = ClipboardService.shared.readText() else {
            NotificationService.shared.show(title: "AnyGPT", message: "Nothing to process", isError: true)
            ClipboardService.shared.writeText("Please select text first")
            animateStatusIcon(processing: false)
            return
        }

        // Process through LLM
        await processThroughLLM(text: text)

        animateStatusIcon(processing: false)
    }

    private func processThroughLLM(text: String, isTest: Bool = false) async {
        // Check API key
        let apiKey: String
        do {
            apiKey = try KeychainService.shared.retrieveAPIKey()
        } catch {
            Logger.shared.log("No API key found", level: .error)
            // Show preferences on API key tab
            showPopover()
            preferencesViewController.selectAPIKeyTab()
            return
        }

        // Get user preferences
        let model = UserDefaults.standard.string(forKey: "model") ?? "gpt-4o-mini"
        let systemPrompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? "You are a helpful assistant."
        let autoPaste = UserDefaults.standard.bool(forKey: "autoPaste")
        let playSound = UserDefaults.standard.bool(forKey: "playSound")

        // Call OpenAI API
        do {
            let response = try await OpenAIClient.shared.generate(
                text: text,
                apiKey: apiKey,
                model: model,
                systemPrompt: systemPrompt
            )

            // Write to clipboard
            ClipboardService.shared.writeText(response)

            // Show notification
            let inputCount = text.count
            let outputCount = response.count
            NotificationService.shared.show(
                title: "AnyGPT",
                message: "In: \(inputCount) chars • Out: \(outputCount) chars",
                isError: false
            )

            // Play sound if enabled
            if playSound {
                NSSound(named: "Glass")?.play()
            }

            // Auto-paste if enabled and not a test
            if autoPaste && !isTest {
                AccessibilityHelper.shared.sendCommandV()
            }

            Logger.shared.log("Successfully processed text: in=\(inputCount), out=\(outputCount)", level: .info)

        } catch {
            Logger.shared.log("Error processing text: \(error)", level: .error)

            let errorMessage = "Error: \(error.localizedDescription)"
            ClipboardService.shared.writeText(errorMessage)
            NotificationService.shared.show(
                title: "AnyGPT",
                message: "Error copied to clipboard",
                isError: true
            )
        }
    }

    private func animateStatusIcon(processing: Bool) {
        guard let button = statusItem.button else { return }

        if processing {
            // Pulse animation
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                button.animator().alphaValue = 0.5
            } completionHandler: {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    button.animator().alphaValue = 1.0
                }
            }
        } else {
            button.alphaValue = 1.0
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        hotkeyManager.unregister()
        Logger.shared.log("AnyGPT terminated", level: .info)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Event Monitor
class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stop()
    }
}