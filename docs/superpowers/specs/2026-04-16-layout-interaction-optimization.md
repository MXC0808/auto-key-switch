# Layout & Interaction Optimization

Optimize the newly implemented sidebar layout across three batches: Cleanup, Interaction, and Polish.

## Batch A: Cleanup

### A1. Delete V1 dead code views

Remove 8 unused legacy view files that have been superseded by V2 versions:

- `Sources/UI/Views/MenuBar/AppRuleRow.swift` — replaced by `AppRuleRowV2` in `AppSettingsTab.swift`
- `Sources/UI/Views/MenuBar/MemoryEnabledListView.swift` — replaced by `MemoryEnabledListViewV2` in `MemoryConfigView.swift`
- `Sources/UI/Views/MenuBar/MemoryAppRow.swift` — replaced by `MemoryAppRowV2` in `MemoryConfigView.swift`
- `Sources/UI/Views/MenuBar/MemoryEditToolbar.swift` — replaced by `MemoryToolbarV2` in `MemoryConfigView.swift`
- `Sources/UI/Views/MenuBar/RunningAppsPicker.swift` — replaced by `RunningAppCardV2` in `MemoryConfigView.swift`
- `Sources/UI/Views/MenuBar/RunningAppCard.swift` — replaced by `RunningAppCardV2` in `MemoryConfigView.swift`
- `Sources/UI/Views/MenuBar/AppSearchPicker.swift` — replaced by `AddAppSheet` in `AppSettingsTab.swift`
- `Sources/UI/Views/MenuBar/AppInfoView.swift` — entirely unused

### A2. Add Typography DesignTokens

Add `DesignTokens.Typography` enum to `DesignSystem.swift`:

```swift
enum Typography {
    static let sidebarGroupTitle: Font = .system(size: 10)
    static let sidebarItem: Font = .system(size: 13)
    static let sidebarVersion: Font = .system(size: 12)
    static let contentHeaderIcon: Font = .system(size: 18, weight: .medium)
    static let contentHeaderTitle: Font = .system(size: 12, weight: .semibold)
    static let contentHeaderSubtitle: Font = .system(size: 11)
}
```

Replace all hardcoded `.font(.system(size: N))` in `SidebarView.swift` and `ContentHeaderView.swift` with these tokens.

### A3. Migrate hardcoded spacing to DesignTokens

In `SidebarView.swift` NavButtonStyle, replace:
- `.padding(.leading, 10)` → `.padding(.leading, DesignTokens.Spacing.md)`
- `.padding(.trailing, 5)` → `.padding(.trailing, DesignTokens.Spacing.xs)`
- `.padding(.vertical, 8)` → `.padding(.vertical, DesignTokens.Spacing.sm)`
- `.padding(.horizontal, 10)` → `.padding(.horizontal, DesignTokens.Spacing.md)`

### A4. Add sidebar color tokens and migrate hardcoded colors

Add to `DesignTokens.Colors`:

```swift
static let sidebarActiveBackground = Color.gray.opacity(0.2)
static let sidebarPressedBackground = Color.gray.opacity(0.1)
static let cardHoverBackground = Color.blue.opacity(0.08)
static let warningBackground = Color.yellow.opacity(0.08)
```

Replace 8 instances of `Color(NSColor.controlBackgroundColor)` with `DesignTokens.Colors.background` across:
- `MemoryConfigView.swift` (4 sites)
- `AddAppSheet.swift` (1 site)
- `MemoryEditToolbar.swift` (1 site, if still exists after A1)
- `RunningAppsPicker.swift` (1 site, if still exists after A1)
- `AppSearchPicker.swift` (1 site, if still exists after A1)

Replace `Color.gray.opacity(0.2)` and `Color.gray.opacity(0.1)` in NavButtonStyle with the new tokens.
Replace `Color.blue.opacity(0.08)` in `RunningAppCardV2` with `DesignTokens.Colors.cardHoverBackground`.
Replace `Color.yellow.opacity(0.08)` in `MemoryEnabledListViewV2` with `DesignTokens.Colors.warningBackground`.

### A5. Dynamic version string

In `SidebarView.swift`, replace `Text("v0.4")` with:

```swift
Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.4")")
```

### A6. Migrate hardcoded cornerRadius

In `AddAppSheet.swift`, replace `.cornerRadius(6)` with `.cornerRadius(DesignTokens.CornerRadius.md)`.

### A7. Consolidate DesignSystem helpers or remove

Either make `AppRuleRowV2` and `MemoryAppRowV2` use `.listRowStyle()` and `.hoverHighlight()`, or remove these unused methods from `DesignSystem.swift`. Preferred: make V2 rows use the helpers to reduce duplication.

---

## Batch B: Interaction

### B1. Cmd+1/2/3 keyboard shortcuts for sidebar

Add `.keyboardShortcut()` to sidebar buttons in `SidebarView.swift`:

- `.appRules` → `.keyboardShortcut("1", modifiers: .command)`
- `.memory` → `.keyboardShortcut("2", modifiers: .command)`
- `.preferences` → `.keyboardShortcut("3", modifiers: .command)`

### B2. Tab key navigation

Add `.focusable()` to sidebar buttons so they participate in Tab key navigation. Content area controls (TextFields, Pickers, Buttons) already support Tab navigation by default.

### B3. Arrow key list row navigation

In `AppSettingsTab.swift` and `MemoryConfigView.swift`, add `@FocusState` to track focused row index. Up/Down arrow keys move the focused row, which also updates selection for single-select behavior. This requires:

- A `@FocusState var focusedBundleId: String?` on each list view
- `.focused($focusedBundleId, equals: app.bundleId)` on each row
- `.onKeyPress(.upArrow)` / `.onKeyPress(.downArrow)` handlers to move focus

### B4. Delete confirmation dialog in AppSettingsTab

Add `.confirmationDialog` to the delete button in `AppSettingsTab.swift`, matching the pattern already used in `MemoryConfigView.swift`:

```swift
.confirmationDialog(
    "确定要删除选中的 \(selectedApps.count) 个应用规则吗？",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("确认删除", role: .destructive) {
        deleteSelectedApps()
    }
} message: {
    Text("此操作不可撤销")
}
```

Requires adding `@State private var showDeleteConfirmation = false`.

### B5. Accessibility labels

Add `.accessibilityLabel()` to all icon-only buttons across the app:
- AppSettingsTab: plus button → "添加应用", trash button → "删除选中应用"
- MemoryConfigView: clear-all button → "清空所有记忆", trash button → "删除选中", add button on cards → "添加到记忆"
- PreferencesTab: question mark buttons already have `.help()` but should also have `.accessibilityLabel()`
- ContentHeaderView: icon → "当前页面: \(item.displayName)"

Add `.accessibilityElement(children: .combine)` and `.accessibilityAddTraits(.isButton)` to `AppRuleRowV2` and `MemoryAppRowV2` since they use `.onTapGesture` instead of Button.

---

## Batch C: Polish

### C1. MemoryAppRowV2 delete button hover animation

In `MemoryConfigView.swift` `MemoryAppRowV2`, replace:

```swift
// Current: conditional rendering, pops in/out
if isHovered {
    Button(action: onRemove) { ... }
        .transition(.opacity)
}
```

With opacity-based approach:

```swift
// New: smooth fade in/out
Button(action: onRemove) {
    Image(systemName: "trash")
        .foregroundStyle(.red)
}
.buttonStyle(.plain)
.opacity(isHovered ? 1 : 0)
.disabled(!isHovered)
.animation(DesignTokens.Animation.fast, value: isHovered)
```

### C2. Sidebar selection animation

In `SidebarView.swift` NavButtonStyle, add animation to background state change:

```swift
.background(...)
.animation(DesignTokens.Animation.fast, value: isActive)
```

### C3. Content area tab transition

In `MainView.swift`, add `.id(asyncSelection)` to the content view to force SwiftUI to create a new view on tab switch, and wrap the onChange in `withAnimation`:

```swift
.onChange(of: navigationVM.selection) { _ in
    withAnimation(DesignTokens.Animation.fast) {
        asyncSelection = navigationVM.selection
    }
}
```

Apply `.transition(.opacity)` to the content view.

### C4. Window max size limit

In `AutoSwitchInputApp.swift` `showMainWindow()`, add after setting window properties:

```swift
window.maxSize = NSSize(width: 900, height: 680)
```

### C5. Fix invisible menu bar icon

In `AutoSwitchInputApp.swift`, when `isMenuBarHidden` is true, the `MenuBarExtra` label should not render at all. This requires restructuring the scene to conditionally include the `MenuBarExtra` or use `.menuBarExtraStyle(.window)` with a conditional view.

Simplest approach: remove the `if/else` opacity hack and always show the icon. If hiding is truly needed, the `MenuBarExtra` scene itself must be conditionally included, which requires a different app structure (separate `Scene` registration). For now, remove the opacity(0) hack and always show the icon, since the menu bar icon is the primary way to access the app.

### C6. Clean up MainView double Spacer

Remove the redundant outer `HStack` + `Spacer` wrapping in `MainView.swift` content area.

### C7. Fix AppRuleRowV2 indentation

Fix the inconsistent indentation of `.onChange` and `.onAppear` modifiers in `AppSettingsTab.swift` `AppRuleRowV2`.

### C8. Clean up empty AppDelegate delegate methods

Remove the empty `windowWillClose` and `windowDidClose` methods from `AppDelegate`.

---

## File Change Summary

### New Tokens (DesignSystem.swift modifications)
- `DesignTokens.Typography` enum
- `DesignTokens.Colors.sidebarActiveBackground`, `sidebarPressedBackground`, `cardHoverBackground`, `warningBackground`

### Files Deleted (8)
- AppRuleRow.swift, MemoryEnabledListView.swift, MemoryAppRow.swift, MemoryEditToolbar.swift, RunningAppsPicker.swift, RunningAppCard.swift, AppSearchPicker.swift, AppInfoView.swift

### Files Modified
- DesignSystem.swift — Typography + Color tokens
- SidebarView.swift — Typography tokens, spacing tokens, color tokens, keyboard shortcuts, focusable, selection animation
- ContentHeaderView.swift — Typography tokens
- MainView.swift — Tab transition animation, double Spacer cleanup
- AppSettingsTab.swift — Delete confirmation, accessibility labels, arrow key nav, cornerRadius
- MemoryConfigView.swift — Hover animation fix, accessibility labels, arrow key nav, color tokens
- PreferencesTab.swift — Accessibility labels
- AddAppSheet.swift — cornerRadius token
- AutoSwitchInputApp.swift — Max window size, menu bar icon fix, delegate cleanup

## Verification

1. Build succeeds
2. All deleted files no longer referenced
3. No hardcoded spacing/color/font values remain in modified files
4. Cmd+1/2/3 switches sidebar tabs
5. Tab key navigates between controls
6. Arrow keys move selection in list views
7. Delete confirmation dialog appears in AppSettingsTab
8. VoiceOver reads meaningful labels for all interactive elements
9. Memory delete button fades in/out smoothly
10. Sidebar selection transitions animate
11. Content area has subtle transition on tab switch
12. Window cannot be stretched beyond 900x680
13. Version string reads from Bundle
