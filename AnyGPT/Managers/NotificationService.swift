//
//  NotificationService.swift
//  AnyGPT
//
//  Created on 2025
//

import Cocoa
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private var hasPermission = false

    private init() {
        checkPermissions()
    }

    func checkPermissions() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            self?.hasPermission = settings.authorizationStatus == .authorized
        }
    }

    func requestPermissions(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            self?.hasPermission = granted
            if let error = error {
                Logger.shared.log("Notification permission error: \(error)", level: .error)
            }
            completion(granted)
        }
    }

    func show(title: String, message: String, isError: Bool = false) {
        if hasPermission {
            showNotification(title: title, message: message, isError: isError)
        } else {
            showAlert(title: title, message: message, isError: isError)
        }
    }

    private func showNotification(title: String, message: String, isError: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message

        if UserDefaults.standard.bool(forKey: "playSound") && !isError {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("Glass"))
        } else if isError {
            content.sound = UNNotificationSound.default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        notificationCenter.add(request) { error in
            if let error = error {
                Logger.shared.log("Failed to show notification: \(error)", level: .error)
                // Fallback to alert
                DispatchQueue.main.async {
                    self.showAlert(title: title, message: message, isError: isError)
                }
            }
        }
    }

    private func showAlert(title: String, message: String, isError: Bool) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = isError ? .warning : .informational
            alert.addButton(withTitle: "OK")

            // Don't block the main thread
            alert.beginSheetModal(for: NSApp.keyWindow ?? NSWindow()) { _ in
                // Alert dismissed
            }
        }
    }

    func showToast(_ message: String, duration: TimeInterval = 2.0) {
        // Create a simple toast-style window
        DispatchQueue.main.async {
            let toast = ToastWindow(message: message)
            toast.show(duration: duration)
        }
    }
}

// Custom toast window for lightweight notifications
class ToastWindow: NSWindow {
    init(message: String) {
        let label = NSTextField(labelWithString: message)
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .labelColor
        label.alignment = .center

        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        containerView.layer?.cornerRadius = 8
        containerView.layer?.masksToBounds = true

        containerView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 50)
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.contentView = containerView
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = true

        // Position at top-right of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - contentRect.width - 20
            let y = screenFrame.maxY - contentRect.height - 40
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    func show(duration: TimeInterval) {
        self.alphaValue = 0
        self.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.animator().alphaValue = 1.0
        }) {
            // After fade in, wait then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    self.animator().alphaValue = 0.0
                }) {
                    self.orderOut(nil)
                }
            }
        }
    }
}