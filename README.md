# AnyGPT

GPT anywhere on your Mac. Select text, press ⌘⌥`, get AI-powered results instantly.

![macOS 12+](https://img.shields.io/badge/macOS-12%2B-blue)
![Swift 5](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🚀 **Invisible Hotkey**: Press ⌘⌥` (customizable) to process selected text
- 🧠 **AI-Powered**: Uses OpenAI's GPT models for intelligent text transformation
- 🔐 **Secure**: API keys stored in macOS Keychain
- ⚡ **Fast**: Direct API calls with smart caching and retry logic
- 🎯 **Zero Friction**: Works in any app, no context switching required
- 📊 **Menu Bar App**: Minimal UI, lives quietly in your menu bar

## Quick Start

### Prerequisites

- macOS 12.0 (Monterey) or later
- OpenAI API key ([Get one here](https://platform.openai.com/api-keys))
- Xcode 14+ (for building from source)

### Installation

#### Option 1: Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/AnyGPT.git
cd AnyGPT

# Open in Xcode
open AnyGPT.xcodeproj

# Build and run (⌘R)
```

#### Option 2: Download Release

Download the latest `.app` from the [Releases](https://github.com/yourusername/AnyGPT/releases) page.

### Setup

1. **Launch AnyGPT** - Look for the ⌘ icon in your menu bar
2. **Grant Accessibility Permission** - Required for keyboard shortcuts
   - System Settings → Privacy & Security → Accessibility → Toggle AnyGPT
3. **Add Your API Key** - Click the menu bar icon → Preferences → API Key tab
4. **Test It** - Select any text and press ⌘⌥`

## Usage

### Basic Workflow

1. Select text in any application
2. Press your hotkey (default: ⌘⌥`)
3. AnyGPT copies the text, processes it through GPT, and replaces your clipboard
4. Optional: Enable auto-paste to insert results directly

### Configuration

Click the AnyGPT icon in your menu bar to access preferences:

#### General Tab
- **Hotkey**: Record a custom keyboard shortcut
- **Auto-paste**: Automatically insert results at cursor
- **Sound**: Play completion sound
- **Launch at login**: Start AnyGPT when macOS starts

#### Model Tab
- **Model Selection**: Choose between GPT-4o-mini, GPT-4o, GPT-3.5-turbo, or custom
- **System Prompt**: Customize AI behavior
- **Temperature**: Adjust creativity (0.0 = focused, 2.0 = creative)
- **Test Button**: Verify your configuration

#### API Key Tab
- **Secure Storage**: Keys stored in macOS Keychain
- **Validation**: Test your API key
- **Quick Link**: Get an API key from OpenAI

#### Advanced Tab
- **Timeout**: Response timeout (5-60 seconds)
- **Max Length**: Input character limit
- **Retry Logic**: Automatic retry on failures
- **Logging**: Debug mode and log access

## Building

### Requirements

- Xcode 14+
- macOS 12+ SDK
- Swift 5+

### Build Commands

```bash
# Debug build
xcodebuild -scheme AnyGPT -configuration Debug

# Release build
xcodebuild -scheme AnyGPT -configuration Release

# Run tests
xcodebuild test -scheme AnyGPT

# Archive for distribution
xcodebuild archive -scheme AnyGPT -archivePath ./build/AnyGPT.xcarchive
```

### Signing & Notarization

For distribution, you'll need to sign and notarize the app:

```bash
# Sign the app
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" AnyGPT.app

# Notarize
xcrun notarytool submit AnyGPT.app --apple-id your@email.com --password your-app-specific-password --team-id TEAMID

# Staple the notarization
xcrun stapler staple AnyGPT.app
```

## Architecture

```
AnyGPT/
├── AppDelegate.swift           # Main app lifecycle
├── Managers/
│   ├── HotkeyManager.swift    # Global hotkey handling
│   ├── AccessibilityHelper.swift # Keyboard events
│   └── NotificationService.swift # User notifications
├── Services/
│   ├── ClipboardService.swift # Clipboard operations
│   ├── OpenAIClient.swift     # API integration
│   ├── KeychainService.swift  # Secure storage
│   └── Logger.swift           # Debug logging
└── UI/
    └── PreferencesViewController.swift # Settings UI
```

## Troubleshooting

### Hotkey Not Working

1. Check Accessibility permissions in System Settings
2. Ensure no other app is using the same hotkey
3. Try recording a different hotkey combination

### API Errors

1. Verify your API key in Preferences
2. Check your OpenAI account has credits
3. Review logs at `~/Library/Logs/AnyGPT/`

### No Text Selected

1. Ensure text is properly selected before pressing hotkey
2. Some apps may require clicking to focus first
3. Try copying manually (⌘C) to verify selection

## Privacy & Security

- **Local Processing**: All operations happen on your device
- **Direct API Calls**: No intermediary servers
- **Secure Storage**: API keys in macOS Keychain
- **No Telemetry**: Zero tracking or analytics
- **Open Source**: Full code transparency

## Logs

Debug logs are stored at:
```
~/Library/Logs/AnyGPT/anygpt.log
```

Access logs via Preferences → Advanced → Reveal Logs

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/AnyGPT/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/AnyGPT/discussions)
- **Website**: [anygpt.dev](https://anygpt.dev)

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

- Built with Swift and AppKit
- Uses OpenAI's Chat Completions API
- Inspired by the need for frictionless AI assistance

---

**AnyGPT** - GPT anywhere, anytime, with a single keystroke.

Visit [anygpt.dev](https://anygpt.dev) for more information.