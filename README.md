# AutoKeySwitch

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="Platform"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-green.svg" alt="License"></a>
</p>

<p align="center">
  <a href="README.zh-CN.md">中文文档</a> &nbsp;·&nbsp;
  <a href="#installation">Installation</a> &nbsp;·&nbsp;
  <a href="#usage">Usage</a>
</p>

<p align="center">
A lightweight, intelligent macOS input method auto-switcher that seamlessly switches input methods as you move between applications — so you never have to manually switch again.
</p>

> **Note:** This project is a modified version of [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch), with SwiftUIX dependency removed and significant feature enhancements.

---

## Features

- **Auto Switch** — Automatically switch to your preset input method when changing applications
- **Menu Bar Control** — Quick access to running apps and input method switching right from the menu bar
- **App Memory** — Remembers your last input method state per app and restores it when you switch back (up to 20 apps)
- **Force English Punctuation** — Output English punctuation even when using a CJKV input method in designated apps
- **Per-App Rules** — Set independent input method preferences for each application
- **Launch at Login** — Optional auto-start when you log in
- **Visibility Control** — Toggle menu bar icon and Dock icon visibility to match your workflow

## System Requirements

- macOS 13.0 or later (compatible up to macOS 26)
- Accessibility permission (for detecting application switches)
- Input monitoring permission (for punctuation interception)

## Installation

### Build from Source

1. Install [Tuist](https://github.com/tuist/tuist#install)

2. Clone the repository and build:

   ```bash
   git clone https://github.com/MXC0808/AutoKeySwitch.git
   cd AutoKeySwitch
   make run
   ```

   Or step by step:

   ```bash
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

## Usage

### Menu Bar

1. After launching, the keyboard icon appears in the menu bar
2. Click the icon to see running apps and quickly switch their input methods
3. Use "Open Main Window" to access full settings
4. Toggle "Launch at Login" for auto-start

### Main Window

The main window provides three sections via sidebar navigation:

| Section         | Description                                                    |
|-----------------|----------------------------------------------------------------|
| **App Rules**   | Manage input method preferences for each application           |
| **App Memory**  | Enable memory for specific apps to restore their last input method state |
| **Preferences** | Set global default input method, control menu bar/Dock icon visibility |

## Privacy & Security

- All data is stored locally — nothing is uploaded
- No user information or usage data is collected
- Fully open source for review
- Permissions are used only for their stated purpose:
  - **Accessibility**: Detecting application switches
  - **Input Monitoring**: Intercepting punctuation keys (force English punctuation feature)
  - **Login Items**: Launching at startup

## Dependencies

| Package                                                                    | Version | Purpose                      |
|----------------------------------------------------------------------------|---------|------------------------------|
| [Defaults](https://github.com/sindresorhus/Defaults)                       | 7.3.1   | Persistent settings storage  |
| [SwifterSwift](https://github.com/SwifterSwift/SwifterSwift)               | 8.0.0   | Swift native extensions      |
| [VisualEffects](https://github.com/ArcticLeon/VisualEffects)               | 1.0.0+  | SwiftUI blur effects         |
| [Tuist](https://github.com/tuist/tuist)                                    | -       | Project generation and management |

## Project Structure

```
AutoKeySwitch/
├── Project.swift                          # Tuist project configuration
├── Tuist/
│   └── Signing/
│       ├── AutoKeySwitch.entitlements
│       └── AutoSwitchInput.entitlements
├── Tuist.swift                            # Tuist configuration helpers
├── Makefile                               # Build automation
├── CLAUDE.md                              # Project instructions for AI
│
├── AutoKeySwitch/
│   └── Sources/
│       ├── App/
│       │   └── AutoSwitchInputApp.swift   # App entry point
│       │
│       ├── Core/
│       │   ├── DesignSystem.swift         # Design tokens and theming
│       │   ├── Models/
│       │   │   ├── AppInfo.swift
│       │   │   ├── InputMethod.swift
│       │   │   └── InputSourceProperties.swift
│       │   └── Extensions/
│       │       ├── Defaults+Extensions.swift
│       │       └── View+Border.swift
│       │
│       ├── Models/
│       │   └── NavigationVM.swift          # Sidebar navigation model
│       │
│       ├── Services/
│       │   ├── AppManagement/
│       │   │   ├── AppInfoService.swift    # App metadata discovery
│       │   │   └── AppListService.swift    # Running app listing
│       │   ├── InputMethod/
│       │   │   ├── InputMethodManager.swift
│       │   │   └── InputMethodService.swift
│       │   ├── Punctuation/
│       │   │   ├── PunctuationService.swift
│       │   │   ├── InputSourceProviding.swift
│       │   │   ├── KeyboardLayoutProviding.swift
│       │   │   ├── KeyboardLayoutMapper.swift
│       │   │   └── PermissionProviding.swift
│       │   └── System/
│       │       ├── AppVisibilityService.swift
│       │       ├── ConfigurationExportService.swift
│       │       ├── LaunchAtLoginService.swift
│       │       └── PermissionService.swift
│       │
│       └── UI/Views/
│           ├── HUD/
│           │   └── InputMethodHUDView.swift  # Switch overlay
│           │
│           └── MenuBar/
│               ├── MainView.swift
│               ├── SidebarView.swift
│               ├── MenuBarView.swift
│               ├── AppSettingsTab.swift
│               ├── ConfiguredAppsView.swift
│               ├── RunningAppsView.swift
│               ├── MemoryConfigView.swift
│               ├── Memory/
│               │   ├── MemoryAppRowView.swift
│               │   ├── MemoryEnabledListView.swift
│               │   ├── MemoryToolbarView.swift
│               │   └── RunningAppCardView.swift
│               ├── PreferencesTab.swift
│               ├── SettingsView.swift
│               ├── AddAppSheet.swift
│               ├── AppRowView.swift
│               └── ContentHeaderView.swift
│
├── AutoKeySwitchTests/
│   ├── UnitTests/
│   │   ├── AppListServiceTests.swift
│   │   ├── InputMethodManagerTests.swift
│   │   ├── KeyboardLayoutMapperTests.swift
│   │   └── PunctuationServiceLogicTests.swift
│   ├── IntegrationTests/
│   │   └── PunctuationServiceIntegrationTests.swift
│   ├── Mocks/
│   │   ├── MockInputSourceProvider.swift
│   │   ├── MockKeyboardLayoutProvider.swift
│   │   └── MockPermissionProvider.swift
│   ├── TestHelpers/
│   │   └── InputMethodTestHelpers.swift
│   └── E2E/
│       ├── ManualTestChecklist.md
│       ├── punctuation_basic_test.scpt
│       ├── shift_number_test.scpt
│       └── run_e2e_tests.sh
│
├── docs/superpowers/
│   ├── plans/        # Implementation plans
│   └── specs/        # Design specifications
│
├── plans/            # General planning documents
└── Screenshots/
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