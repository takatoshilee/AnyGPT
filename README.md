# AnyGPT

a small macOS menu-bar app: select text in any app, hit a global hotkey, and the
selection gets run through GPT and put back on your clipboard.

i built this for myself so i could run quick prompts without switching to a browser
tab. menu-bar preferences for the hotkey, model, system prompt, and API key (stored
in the macOS Keychain).

## build

it's a Swift Package (no .xcodeproj):

```bash
git clone https://github.com/takatoshilee/AnyGPT.git
cd AnyGPT
open Package.swift   # opens in Xcode; run the AnyGPT target
```

or `swift build` from the command line.

needs macOS 12+, an Accessibility permission grant (for the hotkey), and your own
OpenAI API key set in preferences.

## layout

```
AnyGPT/
├── AppDelegate.swift            # app lifecycle + menu bar
├── Managers/                    # hotkey, accessibility, notifications
├── Services/                    # clipboard, OpenAI client, keychain, logging
└── UI/PreferencesViewController.swift
```

## status

personal tool. works on my machine; not actively maintained. MIT.
