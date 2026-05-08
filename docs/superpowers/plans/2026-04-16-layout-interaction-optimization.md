# Layout & Interaction Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize the newly implemented sidebar layout with cleanup, interaction improvements, and polish across 19 items in 3 batches.

**Architecture:** Add Typography tokens to DesignSystem, migrate hardcoded values, implement keyboard navigation, fix animations and cleanup dead code.

**Tech Stack:** SwiftUI, macOS 13+, DesignTokens pattern

---

## File Structure

### Files to DELETE (6 V1 legacy files exist)
- `AutoKeySwitch/Sources/UI/Views/MenuBar/AppRuleRow.swift`
- `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryEnabledListView.swift`
- `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryEditToolbar.swift`
- `AutoKeySwitch/Sources/UI/Views/MenuBar/RunningAppsPicker.swift`
- `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSearchPicker.swift`
- `AutoKeySwitch/Sources/UI/Views/MenuBar/AppInfoView.swift`

Note: `MemoryAppRow.swift` and `RunningAppCard.swift` already deleted.

### Files to MODIFY
- `AutoKeySwitch/Sources/Core/DesignSystem.swift` — Typography + Color tokens
- `AutoKeySwitch/Sources/UI/Views/MenuBar/SidebarView.swift` — Typography, spacing, colors, keyboard shortcuts, animations
- `AutoKeySwitch/Sources/UI/Views/MenuBar/ContentHeaderView.swift` — Typography tokens
- `AutoKeySwitch/Sources/UI/Views/MenuBar/MainView.swift` — Tab transition, double Spacer cleanup
- `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift` — Delete confirmation, accessibility, arrow keys
- `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift` — Hover animation, accessibility, arrow keys
- `AutoKeySwitch/Sources/UI/Views/MenuBar/AddAppSheet.swift` — cornerRadius token
- `AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift` — Accessibility labels

---

## Batch A: Cleanup

### Task 1: Delete V1 Dead Code Files

**Files:**
- Delete: 6 files (listed above)

- [ ] **Step 1: Delete the 6 legacy view files**
  ```bash
  rm AutoKeySwitch/Sources/UI/Views/MenuBar/AppRuleRow.swift
  rm AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryEnabledListView.swift
  rm AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryEditToolbar.swift
  rm AutoKeySwitch/Sources/UI/Views/MenuBar/RunningAppsPicker.swift
  rm AutoKeySwitch/Sources/UI/Views/MenuBar/AppSearchPicker.swift
  rm AutoKeySwitch/Sources/UI/Views/MenuBar/AppInfoView.swift
  ```

- [ ] **Step 2: Build to verify no compilation errors**
  Run: `xcodebuild -scheme AutoKeySwitch -destination 'platform=macOS' build 2>&1 | head -50`
  Expected: BUILD SUCCEEDED

---

### Task 2: Add Typography DesignTokens

**Files:**
- Modify: `AutoKeySwitch/Sources/Core/DesignSystem.swift`

- [ ] **Step 1: Add Typography enum after Colors enum**
  Add after line 48 (after `enum Colors`):
  ```swift
  // MARK: - Typography

  /// 字体
  enum Typography {
      static let sidebarGroupTitle: Font = .system(size: 10)
      static let sidebarItem: Font = .system(size: 13)
      static let sidebarVersion: Font = .system(size: 12)
      static let contentHeaderIcon: Font = .system(size: 18, weight: .medium)
      static let contentHeaderTitle: Font = .system(size: 12, weight: .semibold)
      static let contentHeaderSubtitle: Font = .system(size: 11)
  }
  ```

- [ ] **Step 2: Build to verify**
  Run: `xcodebuild -scheme AutoKeySwitch -destination 'platform=macOS' build 2>&1 | head -30`
  Expected: BUILD SUCCEEDED

---

### Task 3: Add Sidebar Color Tokens

**Files:**
- Modify: `AutoKeySwitch/Sources/Core/DesignSystem.swift`

- [ ] **Step 1: Add sidebar color tokens to Colors enum**
  Add inside `enum Colors` (after line 47, before closing brace):
  ```swift
  static let sidebarActiveBackground = Color.gray.opacity(0.2)
  static let sidebarPressedBackground = Color.gray.opacity(0.1)
  static let cardHoverBackground = Color.blue.opacity(0.08)
  static let warningBackground = Color.yellow.opacity(0.08)
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 4: Migrate SidebarView Typography and Spacing

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/SidebarView.swift`

- [ ] **Step 1: Replace hardcoded font in group title**
  Change line 22:
  ```swift
  // Before:
  .font(.system(size: 10))
  // After:
  .font(DesignTokens.Typography.sidebarGroupTitle)
  ```

- [ ] **Step 2: Replace hardcoded font in version text**
  Change lines 46-48:
  ```swift
  // Before:
  Text("v0.4")
  .opacity(0.5)
  .font(.system(size: 12))
  // After:
  Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.4")")
  .opacity(0.5)
  .font(DesignTokens.Typography.sidebarVersion)
  ```

- [ ] **Step 3: Replace hardcoded spacing in NavButtonStyle**
  Change lines 74-86:
  ```swift
  // Before:
  .padding(.leading, 10)
  .padding(.trailing, 5)
  .padding(.vertical, 8)
  ...
  .padding(.horizontal, 10)
  // After:
  .padding(.leading, DesignTokens.Spacing.md)
  .padding(.trailing, DesignTokens.Spacing.xs)
  .padding(.vertical, DesignTokens.Spacing.sm)
  ...
  .padding(.horizontal, DesignTokens.Spacing.md)
  ```

- [ ] **Step 4: Replace hardcoded colors in NavButtonStyle background**
  Change lines 78-81:
  ```swift
  // Before:
  .background(
      configuration.isPressed ? Color.gray.opacity(0.1) :
      isActive ? Color.gray.opacity(0.2) :
      Color.clear
  )
  // After:
  .background(
      configuration.isPressed ? DesignTokens.Colors.sidebarPressedBackground :
      isActive ? DesignTokens.Colors.sidebarActiveBackground :
      Color.clear
  )
  ```

- [ ] **Step 5: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 5: Migrate ContentHeaderView Typography

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/ContentHeaderView.swift`

- [ ] **Step 1: Replace icon font**
  Change line 10:
  ```swift
  // Before:
  .font(.system(size: 18, weight: .medium))
  // After:
  .font(DesignTokens.Typography.contentHeaderIcon)
  ```

- [ ] **Step 2: Replace title font**
  Change line 16:
  ```swift
  // Before:
  .font(.system(size: 12, weight: .semibold))
  // After:
  .font(DesignTokens.Typography.contentHeaderTitle)
  ```

- [ ] **Step 3: Replace subtitle font**
  Change line 20:
  ```swift
  // Before:
  .font(.system(size: 11))
  // After:
  .font(DesignTokens.Typography.contentHeaderSubtitle)
  ```

- [ ] **Step 4: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 6: Migrate AddAppSheet cornerRadius

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AddAppSheet.swift`

- [ ] **Step 1: Find and replace cornerRadius**
  Search for `.cornerRadius(6)` and replace with:
  ```swift
  .cornerRadius(DesignTokens.CornerRadius.md)
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

## Batch B: Interaction

### Task 7: Add Cmd+1/2/3 Keyboard Shortcuts

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/SidebarView.swift`

- [ ] **Step 1: Add keyboardShortcut to each navigation button**
  Add after line 33 (inside the Button, before `.buttonStyle`):
  ```swift
  Button(action: { navigationVM.selection = item }) {
      Text(item.displayName)
  }
  .keyboardShortcut(item.shortcut, modifiers: .command)  // ADD THIS LINE
  .buttonStyle(...)
  ```

- [ ] **Step 2: Add shortcut computed property to NavItem**
  This requires extending NavigationVM.NavItem. First check the NavigationVM file location, then add:
  ```swift
  extension NavigationVM.NavItem {
      var shortcut: KeyEquivalent {
          switch self {
          case .appRules: return "1"
          case .memory: return "2"
          case .preferences: return "3"
          }
      }
  }
  ```

- [ ] **Step 3: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 8: Add focusable to Sidebar Buttons

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/SidebarView.swift`

- [ ] **Step 1: Add focusable to NavButtonStyle**
  Add after the `.clipShape` line in NavButtonStyle:
  ```swift
  .focusable()
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 9: Add Delete Confirmation Dialog to AppSettingsTab

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`

- [ ] **Step 1: Add state variable for confirmation**
  Add after line 10:
  ```swift
  @State private var showDeleteConfirmation = false
  ```

- [ ] **Step 2: Change delete button action**
  Change line 89:
  ```swift
  // Before:
  Button(action: deleteSelectedApps) {
  // After:
  Button(action: { showDeleteConfirmation = true }) {
  ```

- [ ] **Step 3: Add confirmationDialog modifier**
  Add after line 144 (before closing brace of body):
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

- [ ] **Step 4: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 10: Add Accessibility Labels

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift`
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/PreferencesTab.swift`
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/ContentHeaderView.swift`

- [ ] **Step 1: Add accessibility to AppSettingsTab buttons**
  After the plus button's `.help("添加应用")`, add:
  ```swift
  .accessibilityLabel("添加应用")
  ```
  After the trash button's `.help(...)`, add:
  ```swift
  .accessibilityLabel("删除选中应用")
  ```

- [ ] **Step 2: Add accessibility to ContentHeaderView icon**
  After line 12 (`.frame(width: 20, height: 20)`), add:
  ```swift
  .accessibilityLabel("当前页面: \(item.displayName)")
  ```

- [ ] **Step 3: Build to verify**
  Expected: BUILD SUCCEEDED

---

## Batch C: Polish

### Task 11: Add Sidebar Selection Animation

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/SidebarView.swift`

- [ ] **Step 1: Add animation to background state**
  Add after the `.background(...)` in NavButtonStyle:
  ```swift
  .animation(DesignTokens.Animation.fast, value: isActive)
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 12: Add Content Tab Transition Animation

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MainView.swift`

- [ ] **Step 1: Update onChange with animation**
  Change lines 28-30:
  ```swift
  // Before:
  .onChange(of: navigationVM.selection) { _ in
      asyncSelection = navigationVM.selection
  }
  // After:
  .onChange(of: navigationVM.selection) { _ in
      withAnimation(DesignTokens.Animation.fast) {
          asyncSelection = navigationVM.selection
      }
  }
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 13: Clean Up MainView Double Spacer

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MainView.swift`

- [ ] **Step 1: Remove redundant HStack wrapper**
  Change lines 13-23:
  ```swift
  // Before:
  HStack {
      VStack(spacing: 0) {
          ContentHeaderView(item: asyncSelection)
          asyncSelection.getView()
          Spacer(minLength: 0)
      }
      Spacer(minLength: 0)
  }
  // After:
  VStack(spacing: 0) {
      ContentHeaderView(item: asyncSelection)
      asyncSelection.getView()
      Spacer(minLength: 0)
  }
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 14: Fix MemoryAppRowV2 Hover Animation

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift`

- [ ] **Step 1: Find MemoryAppRowV2 delete button**
  Locate the conditional delete button rendering and replace with opacity-based approach:
  ```swift
  // Before:
  if isHovered {
      Button(action: onRemove) { ... }
      .transition(.opacity)
  }
  // After:
  Button(action: onRemove) {
      Image(systemName: "trash")
      .foregroundStyle(.red)
  }
  .buttonStyle(.plain)
  .opacity(isHovered ? 1 : 0)
  .disabled(!isHovered)
  .animation(DesignTokens.Animation.fast, value: isHovered)
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 15: Add Window Max Size Limit

**Files:**
- Modify: `AutoKeySwitch/Sources/App/AutoSwitchInputApp.swift`

- [ ] **Step 1: Find showMainWindow function**
  Locate the window setup code and add after setting window properties:
  ```swift
  window.maxSize = NSSize(width: 900, height: 680)
  ```

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 16: Fix Invisible Menu Bar Icon

**Files:**
- Modify: `AutoKeySwitch/Sources/App/AutoSwitchInputApp.swift`

- [ ] **Step 1: Remove opacity(0) hack**
  Find the `isMenuBarHidden` conditional that sets opacity and remove the opacity(0) approach. Always show the menu bar icon.

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 17: Clean Up Empty AppDelegate Methods

**Files:**
- Modify: `AutoKeySwitch/Sources/App/AppDelegate.swift`

- [ ] **Step 1: Remove empty delegate methods**
  Delete `windowWillClose` and `windowDidClose` methods if they are empty.

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

### Task 18: Fix AppRuleRowV2 Indentation

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`

- [ ] **Step 1: Fix modifier indentation**
  Ensure `.onChange` and `.onAppear` modifiers in AppRuleRowV2 are properly indented.

- [ ] **Step 2: Build to verify**
  Expected: BUILD SUCCEEDED

---

## Verification Checklist

After all tasks complete:

- [ ] Build succeeds: `xcodebuild -scheme AutoKeySwitch -destination 'platform=macOS' build`
- [ ] All deleted files no longer referenced (no compile errors)
- [ ] No hardcoded spacing/color/font values in modified files (grep for `.font(.system`, `Color.gray.opacity`, `.padding(`)
- [ ] Cmd+1/2/3 switches sidebar tabs (manual test)
- [ ] Tab key navigates between controls (manual test)
- [ ] Delete confirmation dialog appears in AppSettingsTab (manual test)
- [ ] VoiceOver reads meaningful labels (manual test)
- [ ] Memory delete button fades smoothly (manual test)
- [ ] Sidebar selection transitions animate (manual test)
- [ ] Content area has subtle transition on tab switch (manual test)
- [ ] Window cannot be stretched beyond 900x680 (manual test)
- [ ] Version string reads from Bundle (manual test - check version display)
