# UI Optimization Design

4 UI improvements for AutoKeySwitch: toggle switch with confirmation, remove shortcut hints, rename navigation label, and add scroll-forward button.

## 1. Force English Punctuation: Checkbox → Toggle + Confirmation

### Global Toggle (PreferencesTab)

- Remove `.toggleStyle(.checkbox)` from the "启用功能" Toggle, use default switch style
- Add `@State private var showForcePunctuationConfirmation = false`
- When user toggles ON: intercept the toggle, set it back to OFF, show confirmation dialog
- Confirmation dialog: title "开启强制英文标点", message "启用后将在指定应用中强制使用英文标点符号。确认开启？", buttons "取消" / "确认开启"
- On "确认开启": set `forceEnglishPunctuationEnabled = true`, persist to Defaults, check accessibility permission
- On "取消": toggle stays OFF, no action
- When toggling OFF: directly set to false, persist to Defaults, no confirmation
- Keep existing accessibility permission alert logic unchanged

### Per-App Toggle (AppSettingsTab - AppRuleRowV2)

- Remove `.toggleStyle(.checkbox)` from the per-app Toggle, use default switch style
- No confirmation dialog for per-app toggles (only the global toggle has confirmation)
- Keep existing disabled/opacity behavior when global toggle is OFF

## 2. Remove Shortcut Hint

- Delete the HStack block (lines 33-43) in `AppSettingsTab.swift` that shows "Command 点选多个, Shift 范围选择"
- Pure UI removal, no functional impact

## 3. Rename "短期记忆" → "应用记忆"

- Change `NavigationVM.NavItem.memory.displayName` from `"短期记忆"` to `"应用记忆"`
- This is the single source of truth for the sidebar label and content header subtitle
- Other "记忆" strings in `MemoryConfigView` (已启用记忆, 记忆配置, etc.) remain unchanged — they use "记忆" without the "短期" prefix already

## 4. Running Apps: Fixed > Button + Swipe Hint

### Layout Change

- Title row: add "右滑查看更多" hint text (secondary color, caption font) to the right of "正在运行的应用"
- Scroll area: wrap ScrollView in an HStack with a fixed > button on the right
- > button: 44×56pt, rounded rectangle, chevron.right SF Symbol, accent color, placed outside ScrollView so it doesn't scroll
- Clicking > button: programmatically scroll the horizontal ScrollView forward by one screen width

### Implementation

- Add `@State private var scrollOffset: CGFloat = 0` and a ScrollViewReader with proxy
- > button action: `withAnimation { proxy.scrollTo(nextAppId, anchor: .leading) }`
- "右滑查看更多" hint: only visible when there are more apps than visible area can show (can use a simple check on runningApps count > 4)
- When running apps list is empty: hide the > button and hint (current empty state unchanged)

### Files to Modify

| File | Change |
|------|--------|
| `PreferencesTab.swift` | Toggle style, confirmation dialog state and logic |
| `AppSettingsTab.swift` | Remove shortcut hint HStack, per-app toggle style |
| `NavigationVM.swift` | displayName change |
| `MemoryConfigView.swift` | > button, swipe hint, ScrollViewReader |
