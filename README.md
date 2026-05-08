# AutoKeySwitch

<div align="center">

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)

[:cn: 中文文档](README.zh-CN.md) | [:package: Installation](#-installation) | [:book: Usage](#-usage)

A lightweight, intelligent macOS input method auto-switcher that seamlessly switches input methods as you move between applications — so you never have to manually switch again.

> **Note:** This project is a modified version of [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch), with SwiftUIX dependency removed and significant feature enhancements.

## :sparkles: Features

- :repeat: **Auto Switch** — Automatically switch to your preset input method when changing applications
- :iphone: **Menu Bar Control** — Quick access to running apps and input method switching right from the menu bar
- :brain: **App Memory** — Remembers your last input method state per app and restores it when you switch back (up to 20 apps)
- :pencil: **Force English Punctuation** — Output English punctuation even when using a CJKV input method in designated apps
- :gear: **Per-App Rules** — Set independent input method preferences for each application
- :rocket: **Launch at Login** — Optional auto-start when you log in
- :eye: **Visibility Control** — Toggle menu bar icon and Dock icon visibility to match your workflow

## :wrench: System Requirements

- macOS 13.0 or later (compatible up to macOS 26)
- Accessibility permission (for detecting application switches)
- Input monitoring permission (for punctuation interception)

## :package: Installation

### Build from Source

1. Install [Tuist](https://github.com/tuist/tuist#install)

2. Clone the repository
   ```bash
   git clone https://github.com/MXC0808/AutoKeySwitch.git
   cd AutoKeySwitch
   ```

3. Build and run
   ```bash
   make run          # Generate, build and run the app
   # Or step by step:
   make generate     # Generate Xcode project
   make build        # Build project
   make open         # Open the built app
   make clean        # Clean build cache
   make clean-build  # Full clean and rebuild
   make help         # Show all available commands
   ```

### Manual Steps

```bash
tuist generate
open AutoKeySwitch.xcworkspace
```

## :book: Usage

### Menu Bar

1. After launching, the keyboard icon appears in the menu bar
2. Click the icon to see running apps and quickly switch their input methods
3. Use "Open Main Window" to access full settings
4. Toggle "Launch at Login" for auto-start

### Main Window

The main window provides three sections via sidebar navigation:

| Section | Description |
|---------|-------------|
| **App Rules** | Manage input method preferences for each application |
| **App Memory** | Enable memory for specific apps to restore their last input method state |
| **Preferences** | Set global default input method, control menu bar/Dock icon visibility |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘ + 1` | Switch to App Rules tab |
| `⌘ + 2` | Switch to App Memory tab |
| `⌘ + 3` | Switch to Preferences tab |
| `⌘ + O` | Open main window |
| `⌘ + Q` | Quit application |

## :lock: Privacy & Security

AutoKeySwitch takes your privacy seriously:

- :house: All data is stored locally — nothing is uploaded
- :no_entry_sign: No user information or usage data is collected
- :book: Fully open source for review
- :shield: Permissions are used only for their stated purpose:
  - **Accessibility**: Detecting application switches
  - **Input Monitoring**: Intercepting punctuation keys (force English punctuation feature)
  - **Login Items**: Launching at startup

## Dependencies

- [Defaults](https://github.com/sindresorhus/Defaults) (7.3.1) — Persistent settings storage
- [SwifterSwift](https://github.com/SwifterSwift/SwifterSwift) (8.0.0) — Swift native extensions
- [VisualEffects](https://github.com/ArcticLeon/VisualEffects) — SwiftUI blur effects

Build tools:

- [Tuist](https://github.com/tuist/tuist) — Project generation and management

## Development

### Requirements

- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+ (compatible up to macOS 26)
- [Tuist](https://github.com/tuist/tuist)

### Project Structure

```
AutoKeySwitch/
├── Project.swift                     # Tuist project configuration
├── Tuist/                            # Tuist configuration
│   └── Signing/
│       └── AutoKeySwitch.entitlements
├── AutoKeySwitch/
│   └── Sources/
│       ├── App/                      # App entry point
│       │   └── AutoSwitchInputApp.swift
│       ├── Core/
│       │   ├── DesignSystem.swift    # Design tokens and theming
│       │   ├── Models/               # Data models
│       │   │   ├── AppInfo.swift
│       │   │   ├── InputMethod.swift
│       │   │   └── InputSourceProperties.swift
│       │   └── Extensions/           # Swift extensions
│       │       ├── Defaults+Extensions.swift
│       │       └── View+Border.swift
│       ├── Models/
│       │   └── NavigationVM.swift    # Sidebar navigation model
│       ├── Services/
│       │   ├── AppManagement/        # App discovery and listing
│       │   │   ├── AppInfoService.swift
│       │   │   └── AppListService.swift
│       │   ├── InputMethod/          # Input method switching
│       │   │   ├── InputMethodManager.swift
│       │   │   └── InputMethodService.swift
│       │   ├── Punctuation/          # Force English punctuation
│       │   │   ├── PunctuationService.swift
│       │   │   ├── InputSourceProviding.swift
│       │   │   ├── KeyboardLayoutProviding.swift
│       │   │   ├── KeyboardLayoutMapper.swift
│       │   │   └── PermissionProviding.swift
│       │   └── System/               # System services
│       │       ├── AppVisibilityService.swift
│       │       ├── ConfigurationExportService.swift
│       │       ├── LaunchAtLoginService.swift
│       │       └── PermissionService.swift
│       └── UI/
│           └── Views/
│               ├── HUD/                   # Input method switch HUD
│               │   └── InputMethodHUDView.swift
│               └── MenuBar/               # Menu bar and main window views
│                   ├── MainView.swift
│                   ├── SidebarView.swift
│                   ├── MenuBarView.swift
│                   ├── AppSettingsTab.swift
│                   ├── ConfiguredAppsView.swift
│                   ├── RunningAppsView.swift
│                   ├── MemoryConfigView.swift
│                   ├── Memory/
│                   │   ├── MemoryAppRowView.swift
│                   │   ├── MemoryEnabledListView.swift
│                   │   ├── MemoryToolbarView.swift
│                   │   └── RunningAppCardView.swift
│                   ├── PreferencesTab.swift
│                   ├── SettingsView.swift
│                   ├── AddAppSheet.swift
│                   ├── AppRowView.swift
│                   ├── ContentHeaderView.swift
│                   └── ...
├── AutoKeySwitchTests/                    # Test suite
│   ├── UnitTests/
│   ├── IntegrationTests/
│   ├── Mocks/
│   └── TestHelpers/
└── Makefile                               # Build automation
```

## Contributing

Pull requests and issues are welcome. Before submitting a PR, please ensure:

1. Code follows project style guidelines
2. Necessary tests are added
3. Documentation is updated

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.

## Acknowledgments

- [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch) — The original project that AutoKeySwitch is based on
- [SwitchKey](https://github.com/itsuhane/SwitchKey) — Valuable reference for input method switching
- [InputSourcePro](https://github.com/runjuu/InputSourcePro) — Excellent reference for input source management
