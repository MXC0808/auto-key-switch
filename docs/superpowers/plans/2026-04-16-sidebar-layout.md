# Sidebar Layout Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace TabView segmented control with InputSourcePro-style sidebar + content layout

**Architecture:** Custom `HStack(sidebar + content)` layout with `NavigationVM` managing selection state, `SidebarView` rendering grouped navigation buttons with icons, and a `ContentHeaderView` providing context. Uses `VisualEffects` library for sidebar frosted glass.

**Tech Stack:** SwiftUI, VisualEffects 1.0.3 (twostraws), Tuist

---

## File Structure

| Operation | Path | Responsibility |
|-----------|------|----------------|
| Create | `Sources/Models/NavigationVM.swift` | Navigation state, NavItem enum, NavGroup struct |
| Create | `Sources/Core/Extensions/View+Border.swift` | Edge-specific border drawing |
| Create | `Sources/UI/Views/MenuBar/SidebarView.swift` | Sidebar view + NavButtonStyle |
| Create | `Sources/UI/Views/MenuBar/ContentHeaderView.swift` | Content area header bar |
| Modify | `Sources/Core/DesignSystem.swift` | Add Sidebar DesignTokens |
| Modify | `Project.swift` | Add VisualEffects dependency |
| Modify | `Sources/UI/Views/MenuBar/MainView.swift` | TabView → HStack layout |
| Modify | `Sources/App/AutoSwitchInputApp.swift` | Window size, titlebar, button config |

---

### Task 1: Add VisualEffects dependency and Sidebar DesignTokens

**Files:**
- Modify: `Project.swift:13-16` (packages array)
- Modify: `Project.swift:55-57` (dependencies array)
- Modify: `Sources/Core/DesignSystem.swift` (add Sidebar enum)

- [ ] **Step 1: Add VisualEffects package to Project.swift**

In the `packages` array, add after the Defaults entry:

```swift
.remote(url: "https://github.com/twostraws/VisualEffects", requirement: .upToNextMajor(from: "1.0.0")),
```

In the AutoKeySwitch target's `dependencies` array, add:

```swift
.package(product: "VisualEffects"),
```

- [ ] **Step 2: Add Sidebar DesignTokens to DesignSystem.swift**

Add this enum inside `DesignTokens` (after `Sizes`):

```swift
// MARK: - Sidebar

/// 侧边栏
enum Sidebar {
    static let width: CGFloat = 200
    static let headerHeight: CGFloat = 52
    static let iconSize: CGFloat = 15
    static let cornerRadius: CGFloat = 6
    static let topPadding: CGFloat = 40
}
```

- [ ] **Step 3: Resolve Tuist and verify build**

Run: `tuist generate && xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -5`

Expected: BUILD SUCCEEDED (VisualEffects imported successfully)

- [ ] **Step 4: Commit**

```bash
git add Project.swift Sources/Core/DesignSystem.swift
git commit -m "feat: add VisualEffects dependency and Sidebar DesignTokens"
```

---

### Task 2: Create View+Border extension

**Files:**
- Create: `Sources/Core/Extensions/View+Border.swift`

This is copied from InputSourcePro's `Border.swift` utility, used for sidebar/content divider and content header bottom border.

- [ ] **Step 1: Create View+Border.swift**

```swift
import SwiftUI

private struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: rect.minX
                case .trailing: rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: rect.minY
                case .bottom: rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: rect.width
                case .leading, .trailing: width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: width
                case .leading, .trailing: rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/Core/Extensions/View+Border.swift
git commit -m "feat: add View+Border extension for edge-specific borders"
```

---

### Task 3: Create NavigationVM

**Files:**
- Create: `Sources/Models/NavigationVM.swift`

- [ ] **Step 1: Create NavigationVM.swift**

```swift
import SwiftUI

@MainActor
class NavigationVM: ObservableObject {
    /// Sidebar navigation item
    enum NavItem: String, CaseIterable, Identifiable {
        case appRules
        case memory
        case preferences

        var id: String { rawValue }

        /// SF Symbol name for sidebar icon
        var icon: String {
            switch self {
            case .appRules:
                return "app.badge.checkmark"
            case .memory:
                if #available(macOS 14.0, *) {
                    return "brain.head.profile"
                } else {
                    return "brain"
                }
            case .preferences:
                return "gearshape"
            }
        }

        /// Chinese display name shown in sidebar and content header
        var displayName: String {
            switch self {
            case .appRules: return "应用规则"
            case .memory: return "短期记忆"
            case .preferences: return "偏好设置"
            }
        }
    }

    /// Sidebar group with header title
    struct NavGroup {
        let id: String
        let title: String
        let items: [NavItem]
    }

    /// All groups in sidebar display order
    static var grouped: [NavGroup] {
        [
            NavGroup(id: "rules", title: "规则", items: [.appRules, .memory]),
            NavGroup(id: "settings", title: "设置", items: [.preferences]),
        ]
    }

    @Published var selection: NavItem = .appRules
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/Models/NavigationVM.swift
git commit -m "feat: add NavigationVM with NavItem and NavGroup"
```

---

### Task 4: Create SidebarView with NavButtonStyle

**Files:**
- Create: `Sources/UI/Views/MenuBar/SidebarView.swift`

- [ ] **Step 1: Create SidebarView.swift**

```swift
import SwiftUI
import VisualEffects

/// Sidebar navigation with grouped items
struct SidebarView: View {
    @EnvironmentObject private var navigationVM: NavigationVM

    var body: some View {
        ZStack {
            VisualEffectBlur(
                material: .sidebar,
                blendingMode: .behindWindow,
                state: .followsWindowActiveState
            )

            VStack(spacing: DesignTokens.Spacing.lg) {
                ForEach(NavigationVM.grouped, id: \.id) { group in
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        if !group.title.isEmpty {
                            HStack {
                                Text(group.title)
                                    .font(.system(size: 10))
                                    .opacity(0.6)
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .padding(.bottom, 2)
                        }

                        ForEach(group.items) { item in
                            Button(action: { navigationVM.selection = item }) {
                                Text(item.displayName)
                            }
                            .buttonStyle(
                                NavButtonStyle(
                                    icon: item.icon,
                                    isActive: navigationVM.selection == item
                                )
                            )
                        }
                    }
                }

                Spacer()

                Text("v0.4")
                    .opacity(0.5)
                    .font(.system(size: 12))
            }
            .padding(.top, DesignTokens.Sidebar.topPadding)
            .padding(.vertical)
        }
        .frame(width: DesignTokens.Sidebar.width)
    }
}

/// Sidebar navigation button style with icon + text + selection highlight
struct NavButtonStyle: ButtonStyle {
    let icon: String
    let isActive: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Sidebar.iconSize, weight: .medium))
                .frame(width: DesignTokens.Sidebar.iconSize, height: DesignTokens.Sidebar.iconSize)
                .opacity(0.9)

            configuration.label
                .lineLimit(1)

            Spacer()
        }
        .padding(.leading, 10)
        .padding(.trailing, 5)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(isActive ? Color.gray.opacity(0.2) : Color.clear)
        .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
        .foregroundColor(Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Sidebar.cornerRadius))
        .contentShape(Rectangle())
        .padding(.horizontal, 10)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -5`

Expected: BUILD SUCCEEDED (may have unused warning, that's fine)

- [ ] **Step 3: Commit**

```bash
git add Sources/UI/Views/MenuBar/SidebarView.swift
git commit -m "feat: add SidebarView with NavButtonStyle"
```

---

### Task 5: Create ContentHeaderView

**Files:**
- Create: `Sources/UI/Views/MenuBar/ContentHeaderView.swift`

- [ ] **Step 1: Create ContentHeaderView.swift**

```swift
import SwiftUI

/// Content area header showing current page icon, app name, and page name
struct ContentHeaderView: View {
    let item: NavigationVM.NavItem

    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .medium))
                .opacity(0.8)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 0) {
                Text("AutoKeySwitch")
                    .font(.system(size: 12, weight: .semibold))
                    .opacity(0.8)

                Text(item.displayName)
                    .font(.system(size: 11))
                    .opacity(0.6)
            }

            Spacer()
        }
        .frame(height: DesignTokens.Sidebar.headerHeight)
        .padding(.horizontal)
        .border(width: 1, edges: [.bottom], color: Color(NSColor.separatorColor))
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/UI/Views/MenuBar/ContentHeaderView.swift
git commit -m "feat: add ContentHeaderView for content area header"
```

---

### Task 6: Rewrite MainView to sidebar + content layout

**Files:**
- Modify: `Sources/UI/Views/MenuBar/MainView.swift`

This is the core integration task. Replace the entire TabView with the HStack(sidebar + content) layout.

- [ ] **Step 1: Rewrite MainView.swift**

Replace entire file content with:

```swift
import SwiftUI

/// Main window view with sidebar navigation
struct MainView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @StateObject private var navigationVM = NavigationVM()
    @State private var asyncSelection: NavigationVM.NavItem = .appRules

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()

            HStack {
                VStack(spacing: 0) {
                    ContentHeaderView(item: asyncSelection)

                    asyncSelection.getView()

                    Spacer(minLength: 0)
                }

                Spacer(minLength: 0)
            }
            .border(width: 1, edges: [.leading], color: Color(NSColor.separatorColor))
        }
        .frame(minWidth: 780, minHeight: 520)
        .environmentObject(navigationVM)
        .onChange(of: navigationVM.selection) { _ in
            asyncSelection = navigationVM.selection
        }
        .onAppear {
            asyncSelection = navigationVM.selection
        }
    }
}

extension NavigationVM.NavItem {
    @ViewBuilder
    func getView() -> some View {
        switch self {
        case .appRules:
            AppSettingsTab()
        case .memory:
            MemoryConfigView()
        case .preferences:
            PreferencesTab()
        }
    }
}

#Preview {
    MainView()
        .environmentObject(InputMethodManager.shared)
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -10`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/UI/Views/MenuBar/MainView.swift
git commit -m "feat: replace TabView with sidebar + content layout"
```

---

### Task 7: Update window configuration in AutoSwitchInputApp

**Files:**
- Modify: `Sources/App/AutoSwitchInputApp.swift:71-94`

- [ ] **Step 1: Update showMainWindow() method**

Replace the `showMainWindow()` method body with:

```swift
func showMainWindow() {
    if mainWindow == nil {
        let contentView = MainView()
            .environmentObject(InputMethodManager.shared)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "AutoKeySwitch"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        // Disable zoom and minimize buttons
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.standardWindowButton(.miniaturizeButton)?.isEnabled = false

        self.mainWindow = window
    }

    mainWindow?.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Sources/App/AutoSwitchInputApp.swift
git commit -m "feat: update window config for sidebar layout"
```

---

### Task 8: Final integration verification

**Files:**
- No new changes — verify and clean up

- [ ] **Step 1: Full build**

Run: `xcodebuild build -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 2: Visual verification checklist**

Launch the app and verify:
1. Sidebar displays with frosted glass effect
2. Two groups visible: "规则" (应用规则 + 短期记忆) and "设置" (偏好设置)
3. Icons render next to each navigation item
4. Clicking sidebar items switches the content view
5. Content header shows icon + "AutoKeySwitch" + page name
6. Window size is 780x520 with hidden titlebar
7. Zoom and minimize buttons are disabled
8. All existing page functionality works (search, toggles, pickers, alerts)

- [ ] **Step 3: Update spec if any deviations found**

If any behavior differs from spec, document the deviation in the commit message and update the spec file accordingly.
