# UI Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 4 UI optimizations: toggle switch with confirmation for force punctuation, remove shortcut hints, rename navigation label, and add fixed scroll-forward button for running apps.

**Architecture:** Each optimization is an independent UI change with no cross-dependencies. Tasks are ordered by file dependency — Task 1 and 2 both modify PreferencesTab but at different locations; Task 3-5 are fully independent files.

**Tech Stack:** Swift 5.9, SwiftUI, macOS 13+, Defaults library

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift` | Modify | Global toggle style + confirmation dialog |
| `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift` | Modify | Remove shortcut hint + per-app toggle style |
| `AutoKeySwitch/Sources/Models/NavigationVM.swift` | Modify | Rename displayName |
| `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift` | Modify | Fixed > button + swipe hint + ScrollViewReader |

---

### Task 1: Global Force Punctuation Toggle — Switch Style + Confirmation Dialog

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift`

- [ ] **Step 1: Add confirmation state variable**

In `PreferencesTab.swift`, add a new `@State` variable after line 14 (`showHelpPopover`):

```swift
@State private var showForcePunctuationConfirmation = false
```

- [ ] **Step 2: Remove checkbox style from global toggle**

In `PreferencesTab.swift`, change the Toggle at line 77-79 from:

```swift
Toggle("启用功能", isOn: $forceEnglishPunctuationEnabled)
    .toggleStyle(.checkbox)
    .focusable(false)
```

to:

```swift
Toggle("启用功能", isOn: $forceEnglishPunctuationEnabled)
    .focusable(false)
```

This makes it use the default switch style instead of checkbox.

- [ ] **Step 3: Update the popover hint text**

In `PreferencesTab.swift`, change the popover text at line 92 from:

```swift
Text("需先开启此开关，然后在「应用规则」中勾选特定应用。")
```

to:

```swift
Text("需先开启此开关，然后在「应用规则」中开启特定应用。")
```

- [ ] **Step 4: Replace onChange with confirmation interception logic**

In `PreferencesTab.swift`, replace the onChange handler at lines 99-108:

```swift
.onChange(of: forceEnglishPunctuationEnabled) { newValue in
    Defaults[.forceEnglishPunctuationEnabled] = newValue
    // 仅在首次开启且无权限时提示
    hasAccessibilityPermission = PermissionService.checkAccessibility()
    if newValue && !hasAccessibilityPermission {
        showPermissionAlert = true
    }
    // 切换后立即刷新标点服务状态
    viewModel.updatePunctuationServiceState()
}
```

with:

```swift
.onChange(of: forceEnglishPunctuationEnabled) { newValue in
    if newValue {
        // Intercept: revert and show confirmation
        forceEnglishPunctuationEnabled = false
        showForcePunctuationConfirmation = true
    } else {
        // Directly disable, no confirmation needed
        Defaults[.forceEnglishPunctuationEnabled] = false
        viewModel.updatePunctuationServiceState()
    }
}
```

- [ ] **Step 5: Add confirmation dialog modifier**

In `PreferencesTab.swift`, add a new `.alert` modifier after the existing `showPermissionAlert` alert (after line 151). Add it before the closing `}` of the view:

```swift
.alert("开启强制英文标点", isPresented: $showForcePunctuationConfirmation) {
    Button("取消", role: .cancel) {}
    Button("确认开启") {
        forceEnglishPunctuationEnabled = true
        Defaults[.forceEnglishPunctuationEnabled] = true
        hasAccessibilityPermission = PermissionService.checkAccessibility()
        if !hasAccessibilityPermission {
            showPermissionAlert = true
        }
        viewModel.updatePunctuationServiceState()
    }
} message: {
    Text("启用后将在指定应用中强制使用英文标点符号。确认开启？")
}
```

- [ ] **Step 6: Build and verify**

Run: `cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && tuist generate && xcodebuild build -scheme AutoKeySwitch -configuration Debug`

Expected: Build succeeds with no errors.

- [ ] **Step 7: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift
git commit -m "feat: change force punctuation toggle to switch style with confirmation dialog"
```

---

### Task 2: Remove Shortcut Hint + Per-App Toggle Switch Style

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`

- [ ] **Step 1: Remove the shortcut hint HStack**

In `AppSettingsTab.swift`, delete the entire HStack block at lines 33-43:

```swift
// 多选提示
HStack {
    Image(systemName: "command")
        .font(.caption)
    Text("Command 点选多个, Shift 范围选择")
        .font(.caption)
        .foregroundStyle(.secondary)
    Spacer()
}
.padding(.horizontal)
.padding(.vertical, DesignTokens.Spacing.xs)
```

- [ ] **Step 2: Remove checkbox style from per-app toggle**

In `AppSettingsTab.swift` (AppRuleRowV2 struct), change the Toggle at lines 244-245 from:

```swift
Toggle("", isOn: $forceEnglishPunctuation)
    .toggleStyle(.checkbox)
```

to:

```swift
Toggle("", isOn: $forceEnglishPunctuation)
```

- [ ] **Step 3: Build and verify**

Run: `cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && tuist generate && xcodebuild build -scheme AutoKeySwitch -configuration Debug`

Expected: Build succeeds with no errors.

- [ ] **Step 4: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift
git commit -m "feat: remove shortcut hint and change per-app punctuation toggle to switch style"
```

---

### Task 3: Rename "短期记忆" to "应用记忆"

**Files:**
- Modify: `AutoKeySwitch/Sources/Models/NavigationVM.swift`

- [ ] **Step 1: Update displayName**

In `NavigationVM.swift`, change line 33 from:

```swift
case .memory: return "短期记忆"
```

to:

```swift
case .memory: return "应用记忆"
```

- [ ] **Step 2: Build and verify**

Run: `cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && tuist generate && xcodebuild build -scheme AutoKeySwitch -configuration Debug`

Expected: Build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add AutoKeySwitch/Sources/Models/NavigationVM.swift
git commit -m "feat: rename navigation label from short-term memory to app memory"
```

---

### Task 4: Running Apps — Fixed > Button + Swipe Hint + ScrollViewReader

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift`

This is the most complex change. The running apps section needs:
1. A "右滑查看更多" hint in the title row
2. An HStack that places the ScrollView and a fixed > button side by side
3. A ScrollViewReader to enable programmatic scrolling
4. The > button scrolls the list forward

- [ ] **Step 1: Add scrollTarget state and > button action**

In `MemoryConfigView.swift`, add a new state variable after `showLimitAlert` (after line 8):

```swift
@State private var scrollTargetId: String? = nil
```

- [ ] **Step 2: Restructure the running apps section**

In `MemoryConfigView.swift`, replace the entire running apps VStack (lines 13-41):

```swift
VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
    Text("正在运行的应用")
        .font(.headline)

    if viewModel.runningApps.isEmpty {
        HStack {
            Image(systemName: "app.badge")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("暂无运行中的应用")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(DesignTokens.CornerRadius.lg)
    } else {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: DesignTokens.Spacing.md) {
                ForEach(viewModel.runningApps) { app in
                    RunningAppCardV2(app: app, onAdd: addApp)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xs)
        }
    }
}
```

with:

```swift
VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
    HStack {
        Text("正在运行的应用")
            .font(.headline)
        Spacer()
        if !viewModel.runningApps.isEmpty && viewModel.runningApps.count > 3 {
            Text("右滑查看更多")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    if viewModel.runningApps.isEmpty {
        HStack {
            Image(systemName: "app.badge")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("暂无运行中的应用")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(DesignTokens.CornerRadius.lg)
    } else {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(viewModel.runningApps) { app in
                            RunningAppCardV2(app: app, onAdd: addApp)
                                .id(app.bundleId)
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .onChange(of: scrollTargetId) { targetId in
                    if let targetId {
                        withAnimation(DesignTokens.Animation.normal) {
                            proxy.scrollTo(targetId, anchor: .leading)
                        }
                        scrollTargetId = nil
                    }
                }
            }

            if viewModel.runningApps.count > 3 {
                Button(action: scrollForward) {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(.accent)
                        .frame(width: 32, height: 44)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(DesignTokens.CornerRadius.lg)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
        }
    }
}
```

- [ ] **Step 3: Add scrollForward action method**

In `MemoryConfigView.swift`, add the `scrollForward` method in the `// MARK: - Actions` section (after `addApp` method, around line 81):

```swift
private func scrollForward() {
    // Find the first app whose ID is after the currently visible area
    // Simple approach: find the app at roughly the 4th position onward
    let apps = viewModel.runningApps
    if apps.count > 3 {
        scrollTargetId = apps[3].bundleId
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && tuist generate && xcodebuild build -scheme AutoKeySwitch -configuration Debug`

Expected: Build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift
git commit -m "feat: add fixed scroll-forward button and swipe hint to running apps section"
```

---

### Task 5: Final Verification

- [ ] **Step 1: Full build**

Run: `cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && tuist generate && xcodebuild build -scheme AutoKeySwitch -configuration Debug`

Expected: Build succeeds with no errors.

- [ ] **Step 2: Visual verification checklist**

Launch the app and verify:
1. Preferences tab: "强制英文符号" toggle is a switch (not checkbox), toggling ON shows confirmation dialog, toggling OFF works directly
2. App rules tab: no shortcut hint visible, per-app punctuation toggle is a switch
3. Sidebar: navigation label shows "应用记忆" instead of "短期记忆"
4. Memory config: "右滑查看更多" hint visible when >3 running apps, > button fixed on right, clicking > scrolls the list forward
