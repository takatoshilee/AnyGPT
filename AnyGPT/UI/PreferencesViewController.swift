//
//  PreferencesViewController.swift
//  AnyGPT
//
//  Created on 2025
//

import Cocoa

class PreferencesViewController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create tab items
        let generalTab = GeneralTabViewController()
        generalTab.title = "General"
        let generalItem = NSTabViewItem(viewController: generalTab)
        generalItem.label = "General"
        generalItem.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "General")

        let modelTab = ModelTabViewController()
        modelTab.title = "Model"
        let modelItem = NSTabViewItem(viewController: modelTab)
        modelItem.label = "Model"
        modelItem.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "Model")

        let apiKeyTab = APIKeyTabViewController()
        apiKeyTab.title = "API Key"
        let apiKeyItem = NSTabViewItem(viewController: apiKeyTab)
        apiKeyItem.label = "API Key"
        apiKeyItem.image = NSImage(systemSymbolName: "key", accessibilityDescription: "API Key")

        let advancedTab = AdvancedTabViewController()
        advancedTab.title = "Advanced"
        let advancedItem = NSTabViewItem(viewController: advancedTab)
        advancedItem.label = "Advanced"
        advancedItem.image = NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: "Advanced")

        // Add tabs
        addTabViewItem(generalItem)
        addTabViewItem(modelItem)
        addTabViewItem(apiKeyItem)
        addTabViewItem(advancedItem)
    }

    func selectAPIKeyTab() {
        selectedTabViewItemIndex = 2 // API Key tab is at index 2
    }
}

// MARK: - General Tab
class GeneralTabViewController: NSViewController {
    private var hotkeyField: NSTextField!
    private var recordButton: NSButton!
    private var autoPasteCheckbox: NSButton!
    private var playSoundCheckbox: NSButton!
    private var launchAtLoginCheckbox: NSButton!
    private var isRecordingHotkey = false

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.alignment = .leading

        // Hotkey section
        let hotkeyLabel = NSTextField(labelWithString: "Global Hotkey:")
        hotkeyField = NSTextField()
        hotkeyField.isEditable = false
        hotkeyField.stringValue = HotkeyManager.hotkeyDisplayString(
            keyCode: UInt32(UserDefaults.standard.integer(forKey: "hotkeyCode")),
            modifiers: UInt32(UserDefaults.standard.integer(forKey: "hotkeyModifiers"))
        )
        if hotkeyField.stringValue.isEmpty {
            hotkeyField.stringValue = "⌘⌥`"
        }

        recordButton = NSButton(title: "Record", target: self, action: #selector(recordHotkey))
        recordButton.bezelStyle = .rounded

        let hotkeyStack = NSStackView(views: [hotkeyLabel, hotkeyField, recordButton])
        hotkeyStack.orientation = .horizontal
        hotkeyStack.spacing = 10

        // Checkboxes
        autoPasteCheckbox = NSButton(checkboxWithTitle: "Auto-paste results", target: self, action: #selector(toggleAutoPaste))
        autoPasteCheckbox.state = UserDefaults.standard.bool(forKey: "autoPaste") ? .on : .off

        playSoundCheckbox = NSButton(checkboxWithTitle: "Play sound on completion", target: self, action: #selector(togglePlaySound))
        playSoundCheckbox.state = UserDefaults.standard.bool(forKey: "playSound") ? .on : .off

        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(toggleLaunchAtLogin))
        launchAtLoginCheckbox.state = UserDefaults.standard.bool(forKey: "launchAtLogin") ? .on : .off

        // Add all to stack
        stackView.addArrangedSubview(hotkeyStack)
        stackView.addArrangedSubview(autoPasteCheckbox)
        stackView.addArrangedSubview(playSoundCheckbox)
        stackView.addArrangedSubview(launchAtLoginCheckbox)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        ])
    }

    @objc private func recordHotkey() {
        if isRecordingHotkey {
            // Stop recording
            isRecordingHotkey = false
            recordButton.title = "Record"
            hotkeyField.stringValue = "Recording cancelled"
        } else {
            // Start recording
            isRecordingHotkey = true
            recordButton.title = "Stop"
            hotkeyField.stringValue = "Press your hotkey..."

            // Monitor for key events
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard self?.isRecordingHotkey == true else { return event }

                let keyCode = UInt32(event.keyCode)
                let modifiers = HotkeyManager.carbonModifiers(from: event.modifierFlags)

                if modifiers != 0 && keyCode != 0 {
                    self?.hotkeyField.stringValue = HotkeyManager.hotkeyDisplayString(keyCode: keyCode, modifiers: modifiers)
                    UserDefaults.standard.set(keyCode, forKey: "hotkeyCode")
                    UserDefaults.standard.set(modifiers, forKey: "hotkeyModifiers")

                    self?.isRecordingHotkey = false
                    self?.recordButton.title = "Record"

                    // Update hotkey manager
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        // Re-register hotkey through app delegate
                    }

                    return nil // Consume event
                }

                return event
            }
        }
    }

    @objc private func toggleAutoPaste(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "autoPaste")
    }

    @objc private func togglePlaySound(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "playSound")
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "launchAtLogin")
        // TODO: Implement actual launch at login using SMAppService
    }
}

// MARK: - Model Tab
class ModelTabViewController: NSViewController {
    private var modelPopup: NSPopUpButton!
    private var customModelField: NSTextField!
    private var systemPromptView: NSTextView!
    private var temperatureSlider: NSSlider!
    private var temperatureLabel: NSTextField!
    private var testButton: NSButton!
    private var testResultField: NSTextField!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 15
        stackView.alignment = .leading

        // Model selection
        let modelLabel = NSTextField(labelWithString: "Model:")
        modelPopup = NSPopUpButton()
        modelPopup.addItems(withTitles: ["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo", "o1-mini", "Custom..."])

        let savedModel = UserDefaults.standard.string(forKey: "model") ?? "gpt-4o-mini"
        modelPopup.selectItem(withTitle: savedModel)
        modelPopup.target = self
        modelPopup.action = #selector(modelChanged)

        customModelField = NSTextField()
        customModelField.placeholderString = "Enter custom model name"
        customModelField.isHidden = !savedModel.contains("Custom")

        let modelStack = NSStackView(views: [modelLabel, modelPopup, customModelField])
        modelStack.orientation = .horizontal
        modelStack.spacing = 10

        // System prompt
        let promptLabel = NSTextField(labelWithString: "System Prompt:")
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        systemPromptView = NSTextView()
        systemPromptView.isRichText = false
        systemPromptView.font = NSFont.systemFont(ofSize: 13)
        systemPromptView.string = UserDefaults.standard.string(forKey: "systemPrompt") ?? "You are a helpful assistant."
        scrollView.documentView = systemPromptView

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(equalToConstant: 100)
        ])

        // Temperature
        let tempLabel = NSTextField(labelWithString: "Temperature:")
        temperatureSlider = NSSlider()
        temperatureSlider.minValue = 0.0
        temperatureSlider.maxValue = 2.0
        temperatureSlider.doubleValue = UserDefaults.standard.double(forKey: "temperature")
        if temperatureSlider.doubleValue == 0 {
            temperatureSlider.doubleValue = 0.7
        }
        temperatureSlider.target = self
        temperatureSlider.action = #selector(temperatureChanged)

        temperatureLabel = NSTextField(labelWithString: String(format: "%.1f", temperatureSlider.doubleValue))
        temperatureLabel.isEditable = false

        let tempStack = NSStackView(views: [tempLabel, temperatureSlider, temperatureLabel])
        tempStack.orientation = .horizontal
        tempStack.spacing = 10

        // Test button
        testButton = NSButton(title: "Test with Sample", target: self, action: #selector(testModel))
        testButton.bezelStyle = .rounded

        testResultField = NSTextField(labelWithString: "")
        testResultField.isEditable = false

        // Add all to stack
        stackView.addArrangedSubview(modelStack)
        stackView.addArrangedSubview(promptLabel)
        stackView.addArrangedSubview(scrollView)
        stackView.addArrangedSubview(tempStack)
        stackView.addArrangedSubview(testButton)
        stackView.addArrangedSubview(testResultField)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            scrollView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    @objc private func modelChanged(_ sender: NSPopUpButton) {
        let selectedTitle = sender.selectedItem?.title ?? ""
        customModelField.isHidden = !selectedTitle.contains("Custom")

        if !selectedTitle.contains("Custom") {
            UserDefaults.standard.set(selectedTitle, forKey: "model")
        }
    }

    @objc private func temperatureChanged(_ sender: NSSlider) {
        temperatureLabel.stringValue = String(format: "%.1f", sender.doubleValue)
        UserDefaults.standard.set(sender.doubleValue, forKey: "temperature")
    }

    @objc private func testModel() {
        testResultField.stringValue = "Testing..."

        // Save current settings
        UserDefaults.standard.set(systemPromptView.string, forKey: "systemPrompt")
        if !customModelField.isHidden {
            UserDefaults.standard.set(customModelField.stringValue, forKey: "model")
        }

        Task {
            do {
                let apiKey = try KeychainService.shared.retrieveAPIKey()
                let model = UserDefaults.standard.string(forKey: "model") ?? "gpt-4o-mini"
                let systemPrompt = systemPromptView.string

                let response = try await OpenAIClient.shared.generate(
                    text: "Hello, this is a test.",
                    apiKey: apiKey,
                    model: model,
                    systemPrompt: systemPrompt
                )

                await MainActor.run {
                    testResultField.stringValue = "✓ Success: \(response.prefix(50))..."
                }
            } catch {
                await MainActor.run {
                    testResultField.stringValue = "✗ Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - API Key Tab
class APIKeyTabViewController: NSViewController {
    private var apiKeyField: NSSecureTextField!
    private var showButton: NSButton!
    private var validateButton: NSButton!
    private var statusLabel: NSTextField!
    private var isShowingKey = false

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 15

        // API key field
        let keyLabel = NSTextField(labelWithString: "OpenAI API Key:")
        apiKeyField = NSSecureTextField()
        apiKeyField.placeholderString = "sk-..."

        // Try to load existing key
        if let existingKey = try? KeychainService.shared.retrieveAPIKey() {
            apiKeyField.stringValue = existingKey
        }

        showButton = NSButton(title: "Show", target: self, action: #selector(toggleShowKey))
        showButton.bezelStyle = .rounded

        let keyStack = NSStackView(views: [keyLabel, apiKeyField, showButton])
        keyStack.orientation = .horizontal
        keyStack.spacing = 10

        // Validate button
        validateButton = NSButton(title: "Validate", target: self, action: #selector(validateKey))
        validateButton.bezelStyle = .rounded

        // Status label
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.isEditable = false

        // Get API key link
        let linkButton = NSButton(title: "Get API Key", target: self, action: #selector(openAPIKeyPage))
        linkButton.bezelStyle = .inline

        // Save button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveKey))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        // Add all to stack
        stackView.addArrangedSubview(keyStack)
        stackView.addArrangedSubview(validateButton)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(linkButton)
        stackView.addArrangedSubview(saveButton)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 350),
            apiKeyField.widthAnchor.constraint(equalToConstant: 250)
        ])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // Focus the API key field
        view.window?.makeFirstResponder(apiKeyField)
    }

    @objc private func toggleShowKey() {
        isShowingKey.toggle()
        showButton.title = isShowingKey ? "Hide" : "Show"
        // TODO: Switch between secure and regular text field
    }

    @objc private func validateKey() {
        let apiKey = apiKeyField.stringValue
        guard !apiKey.isEmpty else {
            statusLabel.stringValue = "Please enter an API key"
            return
        }

        statusLabel.stringValue = "Validating..."
        validateButton.isEnabled = false

        Task {
            do {
                let isValid = try await OpenAIClient.shared.validateAPIKey(apiKey)
                await MainActor.run {
                    statusLabel.stringValue = isValid ? "✓ Valid API key" : "✗ Invalid API key"
                    validateButton.isEnabled = true
                }
            } catch {
                await MainActor.run {
                    statusLabel.stringValue = "✗ \(error.localizedDescription)"
                    validateButton.isEnabled = true
                }
            }
        }
    }

    @objc private func saveKey() {
        let apiKey = apiKeyField.stringValue
        guard !apiKey.isEmpty else {
            statusLabel.stringValue = "Please enter an API key"
            return
        }

        do {
            try KeychainService.shared.storeAPIKey(apiKey)
            statusLabel.stringValue = "✓ API key saved"
        } catch {
            statusLabel.stringValue = "✗ Failed to save: \(error.localizedDescription)"
        }
    }

    @objc private func openAPIKeyPage() {
        if let url = URL(string: "https://platform.openai.com/api-keys") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Advanced Tab
class AdvancedTabViewController: NSViewController {
    private var timeoutField: NSTextField!
    private var maxLengthField: NSTextField!
    private var retryField: NSTextField!
    private var verboseLoggingCheckbox: NSButton!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 400))

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 15

        // Timeout
        let timeoutLabel = NSTextField(labelWithString: "Response timeout (seconds):")
        timeoutField = NSTextField()
        timeoutField.integerValue = UserDefaults.standard.integer(forKey: "timeout")
        if timeoutField.integerValue == 0 {
            timeoutField.integerValue = 20
        }

        let timeoutStack = NSStackView(views: [timeoutLabel, timeoutField])
        timeoutStack.orientation = .horizontal
        timeoutStack.spacing = 10

        // Max length
        let lengthLabel = NSTextField(labelWithString: "Max input length (characters):")
        maxLengthField = NSTextField()
        maxLengthField.integerValue = UserDefaults.standard.integer(forKey: "maxInputLength")
        if maxLengthField.integerValue == 0 {
            maxLengthField.integerValue = 4000
        }

        let lengthStack = NSStackView(views: [lengthLabel, maxLengthField])
        lengthStack.orientation = .horizontal
        lengthStack.spacing = 10

        // Retry attempts
        let retryLabel = NSTextField(labelWithString: "Retry attempts:")
        retryField = NSTextField()
        retryField.integerValue = UserDefaults.standard.integer(forKey: "retryAttempts")
        if retryField.integerValue == 0 {
            retryField.integerValue = 2
        }

        let retryStack = NSStackView(views: [retryLabel, retryField])
        retryStack.orientation = .horizontal
        retryStack.spacing = 10

        // Verbose logging
        verboseLoggingCheckbox = NSButton(checkboxWithTitle: "Enable verbose logging", target: self, action: #selector(toggleVerboseLogging))
        verboseLoggingCheckbox.state = UserDefaults.standard.bool(forKey: "EnableVerboseLogging") ? .on : .off

        // Buttons
        let revealLogsButton = NSButton(title: "Reveal Logs", target: self, action: #selector(revealLogs))
        revealLogsButton.bezelStyle = .rounded

        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetDefaults))
        resetButton.bezelStyle = .rounded

        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        // Add all to stack
        stackView.addArrangedSubview(timeoutStack)
        stackView.addArrangedSubview(lengthStack)
        stackView.addArrangedSubview(retryStack)
        stackView.addArrangedSubview(verboseLoggingCheckbox)
        stackView.addArrangedSubview(revealLogsButton)
        stackView.addArrangedSubview(resetButton)
        stackView.addArrangedSubview(saveButton)

        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        ])
    }

    @objc private func toggleVerboseLogging(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "EnableVerboseLogging")
    }

    @objc private func revealLogs() {
        Logger.shared.revealLogsInFinder()
    }

    @objc private func resetDefaults() {
        timeoutField.integerValue = 20
        maxLengthField.integerValue = 4000
        retryField.integerValue = 2
        verboseLoggingCheckbox.state = .off
        saveSettings()
    }

    @objc private func saveSettings() {
        UserDefaults.standard.set(timeoutField.integerValue, forKey: "timeout")
        UserDefaults.standard.set(maxLengthField.integerValue, forKey: "maxInputLength")
        UserDefaults.standard.set(retryField.integerValue, forKey: "retryAttempts")

        let alert = NSAlert()
        alert.messageText = "Settings Saved"
        alert.informativeText = "Advanced settings have been saved."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}