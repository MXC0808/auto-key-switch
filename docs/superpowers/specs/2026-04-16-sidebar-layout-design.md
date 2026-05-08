# Sidebar Layout Redesign

Replace the current TabView (segmented control) with an InputSourcePro-style sidebar + content layout.

## Problem

macOS TabView in `.automatic` style renders as a segmented control that does not display SF Symbol icons. The current three-tab layout (应用规则, 短期记忆, 偏好设置) lacks visual hierarchy, icon support, and the professional feel of a sidebar navigation.

## Solution

Adopt InputSourcePro's custom `HStack(sidebar + content)` layout pattern with grouped sidebar navigation, icon support, frosted glass sidebar background, and a content area header.

## Architecture

### Layout Structure

```
NSWindow (780x520, no zoom/minimize, hidden titlebar)
├── HStack(spacing: 0)
│   ├── SidebarView (200pt, frosted glass)
│   │   ├── Top padding (40pt, for hidden titlebar space)
│   │   ├── Group "规则"
│   │   │   ├── NavButton: 应用规则 (app.badge.checkmark)
│   │   │   └── NavButton: 短期记忆 (brain.head.profile / brain)
│   │   ├── Group "设置"
│   │   │   └── NavButton: 偏好设置 (gearshape)
│   │   ├── Spacer
│   │   └── Version label
│   │
│   └── Content Area
│       ├── ContentHeaderView (52pt)
│       │   ├── SF Symbol (18pt)
│       │   ├── VStack
│       │   │   ├── "AutoKeySwitch" (12pt semibold)
│       │   │   └── Current page name (11pt)
│       │   └── Bottom border (1px separator)
│       │
│       ├── ScrollView
│       │   └── Current page view
│       └── Spacer(minLength: 0)
```

### Navigation Model

Follows InputSourcePro's `NavigationVM.Nav.grouped` pattern:

```swift
@MainActor
class NavigationVM: ObservableObject {
    enum NavItem: String, CaseIterable, Identifiable {
        case appRules
        case memory
        case preferences

        var id: String { rawValue }
        var icon: String { ... }         // SF Symbol name
        var displayName: String { ... }  // Chinese UI text: "应用规则"/"短期记忆"/"偏好设置"
    }

    /// Sidebar group definition
    struct NavGroup {
        let id: String
        let title: String   // Group header text: "规则"/"设置"
        let items: [NavItem]
    }

    /// All groups in sidebar order
    static var grouped: [NavGroup] {
        [
            NavGroup(id: "rules", title: "规则", items: [.appRules, .memory]),
            NavGroup(id: "settings", title: "设置", items: [.preferences]),
        ]
    }

    @Published var selection: NavItem = .appRules
}
```

### View Switching

`MainView` uses `@ViewBuilder getView()` on the current `asyncSelection` to render the appropriate content view. The `asyncSelection` pattern (from InputSourcePro) prevents animation glitches during tab transitions.

```swift
// In MainView
@State private var asyncSelection: NavItem = .appRules

.onChange(of: navigationVM.selection) { _ in
    asyncSelection = navigationVM.selection
}
```

## Component Details

### NavButtonStyle

Custom `ButtonStyle` for sidebar buttons:

- Layout: `HStack` with icon (15pt medium) + text, left-aligned
- Selected state: `Color.gray.opacity(0.2)` background, `RoundedRectangle(cornerRadius: 6)`
- Pressed state: `Color.gray.opacity(0.1)` background
- Padding: leading 10, trailing 5, vertical 8
- Horizontal margin: 10
- Foreground: `Color.primary`

### SidebarView

- Width: 200pt
- Background: `VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow, state: .followsWindowActiveState)`
- Group titles: 10pt system font, 0.6 opacity, left-aligned with 20pt leading padding
- Top padding: 40pt (space for hidden titlebar)
- Version label: 12pt, 0.5 opacity, bottom-aligned

### ContentHeaderView

- Height: 52pt
- Left: SF Symbol (18pt medium, 0.8 opacity, 20pt frame)
- Right of icon: VStack with app name (12pt semibold, 0.8 opacity) + page name (11pt, 0.6 opacity)
- Bottom: 1px border in `NSColor.separatorColor`

### Border Extension

Copied from InputSourcePro's `Border.swift`:

```swift
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View
}
```

Used for sidebar/content divider and content header bottom border.

## Window Configuration

| Property | Value |
|----------|-------|
| Size | 780 x 520 |
| Title | "AutoKeySwitch" |
| Title visibility | Hidden |
| Titlebar | Transparent |
| Style mask | `.titled`, `.closable`, `.fullSizeContentView` |
| Zoom button | Disabled |
| Minimize button | Disabled |

## Dependencies

- **VisualEffects** (new): `https://github.com/sindresorhus/VisualEffects` — sidebar frosted glass effect

## DesignTokens Additions

```swift
enum Sidebar {
    static let width: CGFloat = 200
    static let headerHeight: CGFloat = 52
    static let iconSize: CGFloat = 15
    static let cornerRadius: CGFloat = 6
    static let topPadding: CGFloat = 40
}
```

## File Changes

### New Files

| File | Description |
|------|-------------|
| `Sources/Models/NavigationVM.swift` | Navigation state, NavItem/NavGroup enums |
| `Sources/UI/Views/MenuBar/SidebarView.swift` | Sidebar view + NavButtonStyle |
| `Sources/UI/Views/MenuBar/ContentHeaderView.swift` | Content area header |
| `Sources/Core/Extensions/View+Border.swift` | Edge-specific border drawing |

### Modified Files

| File | Change |
|------|--------|
| `Sources/UI/Views/MenuBar/MainView.swift` | TabView → HStack(sidebar + content) |
| `Sources/App/AutoSwitchInputApp.swift` | Window config: size, titlebar, buttons |
| `Sources/Core/DesignSystem.swift` | Add Sidebar DesignTokens |
| Package config (Package.swift or Tuist) | Add VisualEffects dependency |

### Unchanged Files

All existing tab content views (`AppSettingsTab`, `MemoryConfigView`, `PreferencesTab`) remain structurally unchanged. Only their external padding may need minor adjustments.

## Interaction Details

- Sidebar buttons switch pages instantly (no animation)
- Sidebar is always visible, not collapsible
- No `.help()` tooltips on sidebar buttons (icon + text is sufficient)
- Existing tooltips within each page view remain unchanged
- MenuBarView is unaffected

## Verification

1. Build succeeds with new dependency
2. Sidebar displays grouped navigation with icons
3. Clicking sidebar items switches content
4. Frosted glass effect renders on sidebar
5. Content header shows icon + app name + page name
6. Window size is 780x520 with hidden titlebar
7. All existing page functionality preserved
