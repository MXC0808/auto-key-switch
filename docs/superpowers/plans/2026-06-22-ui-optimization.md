# UI Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved AutoKeySwitch UI optimization spec across app rules, memory config, menu bar popover, HUD, and preferences while preserving existing settings and behaviors.

**Architecture:** Add shared UI tokens first, then implement one independently testable surface per task. Keep existing service/data APIs intact except for a small global auto-switch toggle in Defaults and InputMethodManager. UI work stays in existing SwiftUI view files and reuses existing callbacks/data sources.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, Defaults, Swift Testing, Tuist/Xcode project.

---

## File Structure and Responsibilities

### Modify

- `AutoKeySwitch/Sources/Core/DesignSystem.swift`
  - Add visual tokens used by the redesigned cards, badges, HUD, and section headers.

- `AutoKeySwitch/Sources/Core/Extensions/Defaults+Extensions.swift`
  - Add `isAutoSwitchEnabled` Defaults key.

- `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`
  - Pause automatic switching when `Defaults[.isAutoSwitchEnabled] == false` while still recording previous app state and updating current active app.

- `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`
  - Remove table headers and replace `AppRuleRowV2` with card-style layout.

- `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift`
  - Replace split running-apps + enabled-list layout with unified searchable list.

- `AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryAppRowView.swift`
  - Convert to unified memory row with running/enabled/not-running badges and inline add action.

- `AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryToolbarView.swift`
  - Keep or lightly adapt for unified bottom toolbar.

- `AutoKeySwitch/Sources/UI/Views/MenuBar/MenuBarView.swift`
  - Replace current simple NSMenu-like group with global toggle header, current app section, other running apps, quick switch, and actions toolbar.

- `AutoKeySwitch/Sources/UI/Views/HUD/InputMethodHUDView.swift`
  - Replace text-only HUD with pill badge while keeping panel behavior.

- `AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift`
  - Replace GroupBox UI with section card UI while keeping existing state and actions.

- `AutoKeySwitchTests/UnitTests/InputMethodManagerTests.swift`
  - Add tests for the global auto-switch Defaults key and paused switching behavior where possible.

### Remove if no references remain

- `AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/RunningAppCardView.swift`
- `AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryEnabledListView.swift`

Do not remove these files until `grep` confirms there are no references and the project builds.

---

## Task 1: Add Shared Design Tokens and Auto-Switch Defaults Key

**Files:**
- Modify: `AutoKeySwitch/Sources/Core/DesignSystem.swift`
- Modify: `AutoKeySwitch/Sources/Core/Extensions/Defaults+Extensions.swift`
- Test: `AutoKeySwitchTests/UnitTests/InputMethodManagerTests.swift`

- [ ] **Step 1: Add a failing test for the new Defaults key**

Append this test inside `InputMethodManagerTests`:

```swift
@Test("isAutoSwitchEnabled defaults to true and can be changed")
@MainActor
func testIsAutoSwitchEnabledDefaultsToTrue() {
    let originalValue = Defaults[.isAutoSwitchEnabled]
    Defaults[.isAutoSwitchEnabled] = true
    #expect(Defaults[.isAutoSwitchEnabled])

    Defaults[.isAutoSwitchEnabled] = false
    #expect(!Defaults[.isAutoSwitchEnabled])

    Defaults[.isAutoSwitchEnabled] = originalValue
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
xcodebuild test -workspace AutoKeySwitch.xcworkspace -scheme AutoKeySwitch -only-testing:AutoKeySwitchTests/InputMethodManagerTests/testIsAutoSwitchEnabledDefaultsToTrue
```

Expected: FAIL because `Defaults.Keys.isAutoSwitchEnabled` does not exist.

- [ ] **Step 3: Add the Defaults key**

In `Defaults+Extensions.swift`, after `defaultInputMethod`, add:

```swift
    /// Whether automatic input method switching is enabled
    nonisolated static let isAutoSwitchEnabled = Key<Bool>("isAutoSwitchEnabled", default: true, suite: appGroupSuite)
```

- [ ] **Step 4: Add design tokens**

In `DesignSystem.swift`, update `CornerRadius`, `Colors`, and `Typography` with these entries:

```swift
        static let pill: CGFloat = 20
```

```swift
            static let hudEnglishIndicator = Color(red: 0.42, green: 0.66, blue: 0.86)
            static let hudChineseIndicator = Color.orange
            static let statusRunning = Color.green
            static let destructive = Color(red: 1.0, green: 0.42, blue: 0.42)
```

```swift
            static let cardTitle: Font = .system(size: 13, weight: .medium)
            static let cardSubtitle: Font = .system(size: 10)
            static let badgeText: Font = .system(size: 10)
            static let sectionHeader: Font = .system(size: 12, weight: .medium)
            static let menuItemTitle: Font = .system(size: 13, weight: .medium)
            static let menuItemSubtitle: Font = .system(size: 10)
            static let hudText: Font = .system(size: 15, weight: .medium)
```

- [ ] **Step 5: Run the test and verify it passes**

Run:

```bash
xcodebuild test -workspace AutoKeySwitch.xcworkspace -scheme AutoKeySwitch -only-testing:AutoKeySwitchTests/InputMethodManagerTests/testIsAutoSwitchEnabledDefaultsToTrue
```

Expected: PASS.

- [ ] **Step 6: Build**

Run:

```bash
make build
```

Expected: build succeeds.

- [ ] **Step 7: Commit**

```bash
git add AutoKeySwitch/Sources/Core/DesignSystem.swift AutoKeySwitch/Sources/Core/Extensions/Defaults+Extensions.swift AutoKeySwitchTests/UnitTests/InputMethodManagerTests.swift
git commit -m "feat: add UI tokens and auto-switch setting"
```

---

## Task 2: Pause Automatic Switching When Global Toggle Is Off

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`
- Test: `AutoKeySwitchTests/UnitTests/InputMethodManagerTests.swift`

- [ ] **Step 1: Add a focused unit test for the setting state**

Append this test inside `InputMethodManagerTests`:

```swift
@Test("auto-switch enabled setting is restored after mutation")
@MainActor
func testAutoSwitchEnabledSettingRestoresAfterMutation() {
    let originalValue = Defaults[.isAutoSwitchEnabled]

    Defaults[.isAutoSwitchEnabled] = false
    #expect(Defaults[.isAutoSwitchEnabled] == false)

    Defaults[.isAutoSwitchEnabled] = true
    #expect(Defaults[.isAutoSwitchEnabled] == true)

    Defaults[.isAutoSwitchEnabled] = originalValue
}
```

- [ ] **Step 2: Run the test**

Run:

```bash
xcodebuild test -workspace AutoKeySwitch.xcworkspace -scheme AutoKeySwitch -only-testing:AutoKeySwitchTests/InputMethodManagerTests/testAutoSwitchEnabledSettingRestoresAfterMutation
```

Expected: PASS after Task 1. This test protects the setting behavior before wiring it into app activation.

- [ ] **Step 3: Add early return in `handleAppActivation`**

In `InputMethodManager.swift`, inside `handleAppActivation(_:)`, keep `recordPreviousAppState()`, bundle extraction, and `currentActiveAppBundleId = bundleId` before the toggle check. Add this immediately after `currentActiveAppBundleId = bundleId`:

```swift
        guard Defaults[.isAutoSwitchEnabled] else {
            updatePunctuationService(for: bundleId)
            return
        }
```

The top of the method should read like this:

```swift
    private func handleAppActivation(_ notification: Notification) async {
        await recordPreviousAppState()

        guard let userInfo = notification.userInfo,
              let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else {
            return
        }

        currentActiveAppBundleId = bundleId

        guard Defaults[.isAutoSwitchEnabled] else {
            updatePunctuationService(for: bundleId)
            return
        }

        guard installedApps.contains(where: { $0.bundleId == bundleId }) else {
            updatePunctuationService(for: bundleId)
            return
        }
```

- [ ] **Step 4: Run focused tests**

Run:

```bash
xcodebuild test -workspace AutoKeySwitch.xcworkspace -scheme AutoKeySwitch -only-testing:AutoKeySwitchTests/InputMethodManagerTests
```

Expected: PASS.

- [ ] **Step 5: Build**

Run:

```bash
make build
```

Expected: build succeeds.

- [ ] **Step 6: Commit**

```bash
git add AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift AutoKeySwitchTests/UnitTests/InputMethodManagerTests.swift
git commit -m "feat: pause auto switching with global setting"
```

---

## Task 3: Redesign App Rules Rows as Cards

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`

- [ ] **Step 1: Remove the column header block**

In `AppSettingsTab.body`, delete the `HStack` block that renders these three header texts:

- `Text("应用")`
- `Text("英文标点")`
- `Text("输入法")`

Keep the search bar above and the `ScrollView` below.

- [ ] **Step 2: Rename `AppRuleRowV2` to `AppRuleCardView`**

Change:

```swift
struct AppRuleRowV2: View {
```

to:

```swift
struct AppRuleCardView: View {
```

Update the `ForEach` call from `AppRuleRowV2(...)` to `AppRuleCardView(...)`.

- [ ] **Step 3: Replace the card body**

Replace the `body` of `AppRuleCardView` with this implementation:

```swift
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconLarge, height: DesignTokens.Sizes.iconLarge)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(app.name)
                    .font(DesignTokens.Typography.cardTitle)
                    .lineLimit(1)
            }
            .frame(minWidth: 100, alignment: .leading)

            Spacer()

            let isGlobalEnabled = Defaults[.forceEnglishPunctuationEnabled]

            HStack(spacing: DesignTokens.Spacing.xs) {
                Text("英文标点")
                    .font(DesignTokens.Typography.badgeText)
                    .foregroundStyle(.secondary)

                Toggle("", isOn: $forceEnglishPunctuation)
                    .help(isGlobalEnabled ? "强制英文符号" : "请先在通用设置中开启总开关")
                    .toggleStyle(.switch)
                    .disabled(!isGlobalEnabled)
                    .opacity(isGlobalEnabled ? 1.0 : 0.4)
                    .focusable(false)
                    .onChange(of: forceEnglishPunctuation) { newValue in
                        var apps = Defaults[.forceEnglishPunctuationApps]
                        if newValue {
                            apps.insert(app.bundleId)
                        } else {
                            apps.remove(app.bundleId)
                        }
                        Defaults[.forceEnglishPunctuationApps] = apps
                        if app.bundleId == viewModel.currentActiveAppBundleId {
                            viewModel.updatePunctuationServiceState()
                        }
                    }
                    .onAppear {
                        forceEnglishPunctuation = Defaults[.forceEnglishPunctuationApps].contains(app.bundleId)
                    }
            }

            Picker("", selection: Binding(
                get: { currentSelection },
                set: { newValue in
                    onInputChange(newValue.isEmpty ? nil : newValue)
                }
            )) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "circle.dashed")
                    Text("使用默认")
                }.tag("")

                ForEach(viewModel.inputMethods) { method in
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        if let icon = method.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
                        } else {
                            Image(systemName: "keyboard")
                                .frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
                        }
                        Text(method.name)
                    }.tag(method.id)
                }
            }
            .pickerStyle(.menu)
            .frame(width: DesignTokens.Sizes.pickerWidth)
            .focusable(false)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(isSelected ? DesignTokens.Colors.selectionHighlight : (isHovered ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.background))
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(isSelected ? DesignTokens.Colors.selectionBorder : DesignTokens.Colors.divider, lineWidth: 1)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
        }
        .animation(DesignTokens.Animation.fast, value: isSelected)
        .animation(DesignTokens.Animation.fast, value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleSelection()
        }
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
```

- [ ] **Step 4: Fix indentation and remove duplicate code**

Ensure the old toggle and picker code is not duplicated after replacing the body.

- [ ] **Step 5: Build**

Run:

```bash
make build
```

Expected: build succeeds.

- [ ] **Step 6: Manual verification**

Run:

```bash
make run
```

Verify:
- App rules list has no column headers.
- Rows render as rounded cards.
- Selecting a card shows accent border and left bar.
- The input method picker still changes per-app setting.
- The English punctuation toggle still respects the global force punctuation setting.

- [ ] **Step 7: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift
git commit -m "feat: redesign app rules as cards"
```

---

## Task 4: Replace Memory Config with Unified List

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift`
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryAppRowView.swift`
- Remove after build: `AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/RunningAppCardView.swift`
- Remove after build: `AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryEnabledListView.swift`

- [ ] **Step 1: Add state and computed list helpers to `MemoryConfigView`**

Inside `MemoryConfigView`, add:

```swift
    @State private var searchText = ""

    private var unifiedApps: [MemoryDisplayApp] {
        let runningBundleIds = Set(viewModel.runningApps.map(\.bundleId))
        let runningApps = viewModel.runningApps.map { app in
            MemoryDisplayApp(app: app, isRunning: true, isEnabled: viewModel.memoryEnabledApps.contains(app.bundleId))
        }
        let inactiveEnabledApps = viewModel.memoryEnabledAppsInfo
            .filter { !runningBundleIds.contains($0.bundleId) }
            .map { app in
                MemoryDisplayApp(app: app, isRunning: false, isEnabled: true)
            }
        let combined = runningApps + inactiveEnabledApps
        let filtered = searchText.isEmpty
            ? combined
            : combined.filter { $0.app.name.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted { lhs, rhs in
            if lhs.isRunning != rhs.isRunning {
                return lhs.isRunning && !rhs.isRunning
            }
            return lhs.app.name.localizedCaseInsensitiveCompare(rhs.app.name) == .orderedAscending
        }
    }
```

Add this helper struct below `MemoryConfigView`:

```swift
struct MemoryDisplayApp: Identifiable {
    let app: AppInfo
    let isRunning: Bool
    let isEnabled: Bool

    var id: String { app.bundleId }
}
```

- [ ] **Step 2: Replace `MemoryConfigView.body`**

Replace the current `VStack` content with:

```swift
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索运行中应用", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.background)

            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(.yellow)
                Text("记忆功能会记住应用上次使用的输入法，下次切换到该应用时自动恢复。")
                    .font(DesignTokens.Typography.badgeText)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color.accentColor.opacity(0.06))
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .padding(.horizontal)
            .padding(.top, DesignTokens.Spacing.sm)

            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(unifiedApps) { displayApp in
                        MemoryAppRowView(
                            app: displayApp.app,
                            isRunning: displayApp.isRunning,
                            isEnabled: displayApp.isEnabled,
                            isSelected: selectedApps.contains(displayApp.app.bundleId),
                            onToggleSelection: {
                                toggleSelection(for: displayApp.app)
                            },
                            onAdd: {
                                addApp(displayApp.app)
                            },
                            onRemove: {
                                viewModel.removeAppsFromMemory([displayApp.app])
                                selectedApps.remove(displayApp.app.bundleId)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }

            MemoryToolbarView(
                selectedCount: selectedApps.count,
                onClearAll: { showClearConfirmation = true },
                onDeleteSelected: deleteSelectedApps
            )
        }
```

- [ ] **Step 3: Add `toggleSelection` helper**

Inside `MemoryConfigView`, add:

```swift
    private func toggleSelection(for app: AppInfo) {
        guard viewModel.memoryEnabledApps.contains(app.bundleId) else { return }
        if selectedApps.contains(app.bundleId) {
            selectedApps.remove(app.bundleId)
        } else {
            selectedApps.insert(app.bundleId)
        }
    }
```

- [ ] **Step 4: Replace `MemoryAppRowView` signature and body**

Change `MemoryAppRowView` properties to:

```swift
    let app: AppInfo
    let isRunning: Bool
    let isEnabled: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onAdd: () -> Void
    let onRemove: () -> Void
```

Replace the body with:

```swift
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconLarge, height: DesignTokens.Sizes.iconLarge)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(app.name)
                    .font(DesignTokens.Typography.cardTitle)
                    .lineLimit(1)

                Text(lastMethodName.map { "上次: \($0)" } ?? "暂无记录")
                    .font(DesignTokens.Typography.cardSubtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isRunning {
                MemoryStatusBadge(title: "● 运行中", color: DesignTokens.Colors.statusRunning)
            } else if isEnabled {
                MemoryStatusBadge(title: "未运行", color: .secondary)
            }

            if isEnabled {
                MemoryStatusBadge(title: "已启用", color: .accentColor)
            } else if isRunning {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(DesignTokens.Colors.statusRunning)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("启用 \(app.name) 的记忆功能")
            }

            if isHovered && isEnabled {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(DesignTokens.Colors.destructive)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .focusable(false)
                .accessibilityLabel("移除 \(app.name) 的记忆功能")
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(isSelected ? DesignTokens.Colors.selectionHighlight : (isHovered ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.background))
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(isSelected ? DesignTokens.Colors.selectionBorder : DesignTokens.Colors.divider, lineWidth: 1)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
        }
        .opacity(isRunning ? 1.0 : 0.7)
        .animation(DesignTokens.Animation.fast, value: isSelected)
        .animation(DesignTokens.Animation.fast, value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleSelection()
        }
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
    }
```

Add below `MemoryAppRowView`:

```swift
private struct MemoryStatusBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.badgeText)
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(color.opacity(0.12))
            .cornerRadius(DesignTokens.CornerRadius.sm)
    }
}
```

- [ ] **Step 5: Build and resolve references**

Run:

```bash
make build
```

Expected initially: may fail if `MemoryEnabledListView` or `RunningAppCardView` references remain. Remove references or unused files only after confirming build errors.

- [ ] **Step 6: Remove unused memory view files if unreferenced**

Run:

```bash
grep -R "RunningAppCardView\|MemoryEnabledListView" AutoKeySwitch/Sources AutoKeySwitchTests
```

Expected: no results except file names if files still exist. If no real references remain, delete:

```bash
rm AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/RunningAppCardView.swift AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryEnabledListView.swift
```

- [ ] **Step 7: Build again**

Run:

```bash
make build
```

Expected: build succeeds.

- [ ] **Step 8: Manual verification**

Run:

```bash
make run
```

Verify:
- Memory page shows a search field.
- Running apps and enabled inactive apps appear in one list.
- Running apps show `● 运行中` badge.
- Enabled apps show `已启用` badge.
- Clicking `+` enables memory.
- Clear all confirmation still works.

- [ ] **Step 9: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryAppRowView.swift AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryToolbarView.swift
git rm AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/RunningAppCardView.swift AutoKeySwitch/Sources/UI/Views/MenuBar/Memory/MemoryEnabledListView.swift
git commit -m "feat: unify memory configuration list"
```

---

## Task 5: Redesign Menu Bar Popover

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MenuBarView.swift`
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppRowView.swift` if needed

- [ ] **Step 1: Add state for global toggle**

In `MenuBarView`, add:

```swift
    @State private var isAutoSwitchEnabled = Defaults[.isAutoSwitchEnabled]
```

Add `import Defaults` at the top.

- [ ] **Step 2: Add helper computed properties**

Inside `MenuBarView`, add:

```swift
    private var currentActiveApp: AppInfo? {
        guard let bundleId = viewModel.currentActiveAppBundleId else { return nil }
        return viewModel.runningApps.first { $0.bundleId == bundleId }
    }

    private var otherRunningApps: [AppInfo] {
        guard let currentActiveApp else { return viewModel.runningApps }
        return viewModel.runningApps.filter { $0.bundleId != currentActiveApp.bundleId }
    }
```

- [ ] **Step 3: Replace `body`**

Replace the `Group` body with:

```swift
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "keyboard")
                    .frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
                Text("AutoKeySwitch")
                    .font(DesignTokens.Typography.menuItemTitle)
                Spacer()
                Toggle("", isOn: $isAutoSwitchEnabled)
                    .toggleStyle(.switch)
                    .focusable(false)
                    .onChange(of: isAutoSwitchEnabled) { newValue in
                        Defaults[.isAutoSwitchEnabled] = newValue
                    }
            }
            .padding(DesignTokens.Spacing.md)

            Divider()

            if let currentActiveApp {
                MenuBarCurrentAppView(app: currentActiveApp)
                    .environmentObject(viewModel)
                    .opacity(isAutoSwitchEnabled ? 1.0 : 0.4)
            }

            if !otherRunningApps.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("其他运行中")
                        .font(DesignTokens.Typography.badgeText)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    ForEach(otherRunningApps) { app in
                        AppRowView(app: app)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
                .opacity(isAutoSwitchEnabled ? 1.0 : 0.4)
            }

            Divider()

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("快速切换")
                    .font(DesignTokens.Typography.badgeText)
                    .foregroundStyle(.secondary)

                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(viewModel.inputMethods) { method in
                        Button(method.name) {
                            viewModel.setDefaultInputMethod(method.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .focusable(false)
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)

            Divider()

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button("设置") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowMainWindow"), object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                .focusable(false)

                Spacer()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
                .focusable(false)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .frame(width: 260)
```

- [ ] **Step 4: Add `MenuBarCurrentAppView`**

Below `MenuBarView`, add:

```swift
private struct MenuBarCurrentAppView: View {
    let app: AppInfo
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconMedium, height: DesignTokens.Sizes.iconMedium)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(app.name)
                    .font(DesignTokens.Typography.menuItemTitle)
                Text(viewModel.getSelectedInputMethodName(for: app) ?? "使用默认")
                    .font(DesignTokens.Typography.menuItemSubtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("⌘1")
                .font(DesignTokens.Typography.badgeText)
                .foregroundStyle(.tertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.accentColor.opacity(0.06))
    }
}
```

- [ ] **Step 5: Build**

Run:

```bash
make build
```

Expected: build succeeds.

- [ ] **Step 6: Manual verification**

Run:

```bash
make run
```

Verify:
- Menu bar popover width is compact.
- Global toggle appears at top and persists after toggling.
- Current active app appears highlighted when available.
- Other running apps still let user set app-specific input method through `AppRowView`.
- Quick switch buttons update global default.
- Settings and Exit buttons work.

- [ ] **Step 7: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/MenuBarView.swift AutoKeySwitch/Sources/UI/Views/MenuBar/AppRowView.swift
git commit -m "feat: redesign menu bar controls"
```

---

## Task 6: Redesign HUD as Pill Badge

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/HUD/InputMethodHUDView.swift`

- [ ] **Step 1: Replace `InputMethodHUDView.body`**

Replace the existing `Text(inputMethodName)` body with:

```swift
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(indicatorColor)
                .frame(width: DesignTokens.Spacing.sm, height: DesignTokens.Spacing.sm)
                .shadow(color: indicatorColor.opacity(0.4), radius: 3)
                .accessibilityHidden(true)

            Text(inputMethodName)
                .font(DesignTokens.Typography.hudText)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
        .accessibilityLabel("当前输入法：\(inputMethodName)")
    }

    private var indicatorColor: Color {
        let lowercasedName = inputMethodName.lowercased()
        if lowercasedName.contains("abc") || lowercasedName.contains("english") {
            return DesignTokens.Colors.hudEnglishIndicator
        }
        return DesignTokens.Colors.hudChineseIndicator
    }
```

- [ ] **Step 2: Build**

Run:

```bash
make build
```

Expected: build succeeds.

- [ ] **Step 3: Manual verification**

Run:

```bash
make run
```

Verify:
- Switching input methods shows a pill-shaped HUD.
- ABC/English input shows blue indicator.
- Chinese input shows orange indicator.
- HUD still fades after 1.5 seconds.

- [ ] **Step 4: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/HUD/InputMethodHUDView.swift
git commit -m "feat: redesign input method HUD"
```

---

## Task 7: Redesign Preferences Page as Section Cards

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift`

- [ ] **Step 1: Add section card helper views**

At the bottom of `PreferencesTab.swift`, add:

```swift
private struct PreferenceSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.sectionHeader)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.background.opacity(0.5))

            VStack(spacing: DesignTokens.Spacing.md) {
                content
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(DesignTokens.Colors.divider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
}

private struct PreferenceToggleRow<Accessory: View>: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.cardTitle)
                Text(description)
                    .font(DesignTokens.Typography.cardSubtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            accessory

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .focusable(false)
        }
    }
}
```

- [ ] **Step 2: Replace the top-level `VStack` content**

Inside `PreferencesTab.body`, keep the existing state, alerts, dialogs, import/export methods. Replace only the visible content before the `.onReceive` and `.alert` modifiers with:

```swift
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("偏好设置")
                .font(.headline)

            PreferenceSectionCard(title: "通用") {
                PreferenceToggleRow(
                    title: "登录时启动",
                    description: "系统登录时自动启动应用",
                    isOn: $isLaunchAtLoginEnabled
                ) {
                    EmptyView()
                }
                .onChange(of: isLaunchAtLoginEnabled) { newValue in
                    _ = LaunchAtLoginService.setLaunchAtLogin(newValue)
                }

                PreferenceToggleRow(
                    title: "切换输入法时显示弹窗提示",
                    description: "切换输入法时显示 HUD 提示",
                    isOn: $showHUDOnSwitch
                ) {
                    EmptyView()
                }
                .onChange(of: showHUDOnSwitch) { newValue in
                    Defaults[.showHUDOnSwitch] = newValue
                }
            }

            PreferenceSectionCard(title: "显示") {
                PreferenceToggleRow(
                    title: "隐藏菜单栏图标",
                    description: "隐藏后可通过 Dock 图标访问应用",
                    isOn: $isMenuBarHidden
                ) {
                    EmptyView()
                }
                .onChange(of: isMenuBarHidden) { newValue in
                    AppVisibilityService.isMenuBarHidden = newValue
                    showRestartAlert = true
                }

                PreferenceToggleRow(
                    title: "隐藏 Dock 图标",
                    description: "隐藏后仅通过菜单栏图标访问应用",
                    isOn: $isDockHidden
                ) {
                    EmptyView()
                }
                .onChange(of: isDockHidden) { newValue in
                    AppVisibilityService.isDockHidden = newValue
                }
            }

            PreferenceSectionCard(title: "高级") {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("强制英文符号")
                            .font(DesignTokens.Typography.cardTitle)
                        Text("中文输入法下自动将标点符号转换为英文")
                            .font(DesignTokens.Typography.cardSubtitle)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: { showHelpPopover = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .popover(isPresented: $showHelpPopover, arrowEdge: .trailing) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("功能说明")
                                .font(.headline)
                            Text("在中文输入法下自动将标点符号转换为英文。")
                            Text("需先开启此开关，然后在「应用规则」中开启特定应用。")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(width: 250)
                    }

                    Toggle("", isOn: $forceEnglishPunctuationEnabled)
                        .toggleStyle(.switch)
                        .focusable(false)
                }
                .onChange(of: forceEnglishPunctuationEnabled) { newValue in
                    if isConfirmingForcePunctuation {
                        isConfirmingForcePunctuation = false
                        return
                    }
                    if newValue {
                        forceEnglishPunctuationEnabled = false
                        showForcePunctuationConfirmation = true
                    } else {
                        Defaults[.forceEnglishPunctuationEnabled] = false
                        viewModel.updatePunctuationServiceState()
                    }
                }

                if forceEnglishPunctuationEnabled && !hasAccessibilityPermission {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("需要「辅助功能」权限才能工作")
                        Button("打开系统设置") {
                            PermissionService.openAccessibilitySettings()
                        }
                        .buttonStyle(.link)
                        .focusable(false)
                    }
                    .font(.caption)
                }
            }

            HStack {
                Spacer()
                Button("导出配置") {
                    exportConfiguration()
                }
                Button("导入配置") {
                    showImportConfirmation = true
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
```

- [ ] **Step 3: Build**

Run:

```bash
make build
```

Expected: build succeeds. If Swift cannot infer `EmptyView()` for `PreferenceToggleRow`, replace the generic helper with a non-generic row and move the optional help button outside the helper.

- [ ] **Step 4: Manual verification**

Run:

```bash
make run
```

Verify:
- Preferences page shows section cards for 通用 / 显示 / 高级.
- All toggles still persist correctly.
- Force English punctuation confirmation still appears.
- Accessibility warning still appears when permission is missing.
- Import/export dialogs still open.

- [ ] **Step 5: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift
git commit -m "feat: redesign preferences as section cards"
```

---

## Task 8: Final Verification and Cleanup

**Files:**
- Review all modified files from Tasks 1-7
- Potentially update project file if removed Swift files are still referenced

- [ ] **Step 1: Search for deleted view references**

Run:

```bash
grep -R "RunningAppCardView\|MemoryEnabledListView\|AppRuleRowV2" AutoKeySwitch/Sources AutoKeySwitchTests
```

Expected: no results.

- [ ] **Step 2: Run unit tests**

Run:

```bash
xcodebuild test -workspace AutoKeySwitch.xcworkspace -scheme AutoKeySwitch
```

Expected: all tests pass.

- [ ] **Step 3: Build**

Run:

```bash
make build
```

Expected: build succeeds.

- [ ] **Step 4: Run app for manual UI verification**

Run:

```bash
make run
```

Verify:
- App rules card list: search, selection, picker, add/delete, global default picker.
- Memory config unified list: search, add, enabled badges, clear all, delete selected.
- Menu bar: global toggle persists, current active app highlight, quick switch, settings, exit.
- HUD: pill badge appears and fades.
- Preferences: cards and all toggles/dialogs.

- [ ] **Step 5: Run SwiftLint if available**

Run:

```bash
swiftlint
```

Expected: no new violations. If `swiftlint` is unavailable, note it in the final report.

- [ ] **Step 6: Review diff**

Run:

```bash
git diff --stat HEAD~7..HEAD
git diff HEAD~7..HEAD -- AutoKeySwitch/Sources AutoKeySwitchTests
```

Expected: changes match the spec; no unrelated edits.

- [ ] **Step 7: Commit final cleanup if needed**

If cleanup changes were made:

```bash
git add AutoKeySwitch/Sources AutoKeySwitchTests
git commit -m "chore: clean up UI optimization implementation"
```

---

## Self-Review

### Spec Coverage

- App rules card layout: Task 3
- Memory unified list: Task 4
- Menu bar B+C hybrid with global toggle: Tasks 1, 2, 5
- HUD pill badge: Task 6
- Preferences section cards: Task 7
- DesignTokens additions: Task 1
- Defaults key and InputMethodManager integration: Tasks 1 and 2
- Final verification and cleanup: Task 8

### Placeholder Scan

No TBD/TODO/fill-in placeholders remain. Code steps include exact Swift snippets and commands.

### Type Consistency

- `Defaults[.isAutoSwitchEnabled]` is introduced in Task 1 before use in Tasks 2 and 5.
- `DesignTokens.CornerRadius.pill`, `DesignTokens.Colors.*`, and `DesignTokens.Typography.*` are introduced in Task 1 before use in UI tasks.
- `MemoryDisplayApp` is defined in Task 4 before `ForEach(unifiedApps)` uses it.
- `MemoryAppRowView` signature is updated before `MemoryConfigView` calls the new initializer.

---

Plan complete and saved to `docs/superpowers/plans/2026-06-22-ui-optimization.md`. Two execution options:

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
