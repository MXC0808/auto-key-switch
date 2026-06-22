# UI Optimization Design — AutoKeySwitch

## Overview

Comprehensive UI optimization covering app rules page, memory config page, menu bar popover, and HUD. The goal is to improve layout precision, simplify operations, enhance HUD readability, and unify visual consistency across all views.

## Design Decisions

| Area | Decision |
|------|----------|
| Overall direction | Card-based layout (Direction B) |
| Card interaction | Direct operation with inline pickers |
| HUD | Pill badge style (B) |
| Menu bar popover | B+C hybrid: grouped focus + global toggle |
| Memory config | Unified list with inline add (B) |

## 1. App Rules Page

### Current Problems

- `AppSettingsTab` uses a table-like layout with `HStack` containing column headers ("应用", "英文标点", "输入法") and `AppRuleRowV2` rows. Column alignment depends on the `frame(minWidth: 100 + DesignTokens.Sizes.iconLarge + DesignTokens.Spacing.md)` on the app name and `frame(width: DesignTokens.Sizes.pickerWidth)` on the picker. Different input method name lengths cause visual misalignment.
- Selection highlight uses `DesignTokens.Colors.selectionHighlight` (accentColor at 12% opacity), which is too subtle.
- Row padding is `DesignTokens.Spacing.sm` (8px) vertical, making rows feel sparse.
- The force English punctuation toggle (`Toggle` with `.switch` style) and the input method `Picker` (`.menu` style, width `DesignTokens.Sizes.pickerWidth` = 160px) are placed inline in the HStack but their positions shift when the toggle state changes.

### New Design: Card-Based Layout

Each app rule becomes a self-contained card. The card contains all controls inline — no shared column alignment needed.

**Card content (left to right)**:
1. App icon — `DesignTokens.Sizes.iconLarge` (24px), rendered via `app.icon`
2. App name — `Text(app.name)`, `.font(.system(size: 13, weight: .medium))`, fixed min width 100px
3. Spacer
4. Force English punctuation toggle — `Toggle("", isOn:)` with `.switch` style, disabled state when global toggle is off (same logic as current `AppRuleRowV2`)
5. Input method picker — `Picker` with `.menu` style, width `DesignTokens.Sizes.pickerWidth` (160px), containing "使用默认" and all `viewModel.inputMethods` entries (same data source as current)

**Visual styling**:
- Card background: `Color(NSColor.controlBackgroundColor)` with `RoundedRectangle` corner radius `DesignTokens.CornerRadius.lg` (8px)
- Card border: 1px `Color(NSColor.separatorColor)`
- Selected state: border switches to `DesignTokens.Colors.selectionBorder` (accentColor at 30% opacity), left accent bar (3px wide, `Color.accentColor`, corner radius 1.5)
- Hover state: background switches to `DesignTokens.Colors.hoverBackground` (accentColor at 5%)
- Card gap: `DesignTokens.Spacing.sm` (8px)
- Card padding: `DesignTokens.Spacing.md` (12px) vertical, `DesignTokens.Spacing.md` horizontal

**Interaction** (same logic as current `AppSettingsTab.toggleSelection`):
- Normal click: single select (click again to deselect)
- Command+click: toggle individual selection
- Shift+click: range select from `lastSelectedIndex`

**Bottom toolbar** (same structure as current):
- Left: Add button (`plus.circle.fill`), Delete button (`trash`), selected count text
- Right: Global default input method picker (`viewModel.defaultInputMethod`, same data source)

### Key Changes from Current

- Remove the column headers HStack ("应用", "英文标点", "输入法") — no longer needed since each card is self-contained
- Remove `frame(alignment: .center)` and `frame(width:)` alignment constraints that caused misalignment
- The `AppRuleRowV2` struct is replaced by a new card-style component reusing the same `onToggleSelection` / `onInputChange` callback pattern
- Search bar, bottom toolbar, add/delete logic, and confirmation dialog remain unchanged

## 2. Memory Config Page

### Current Problems

- `MemoryConfigView` shows running apps in a horizontal `ScrollView` with `LazyHStack` containing `RunningAppCardView` items. When more than 3 apps are running, a custom scroll-forward button appears. This requires horizontal scrolling to find apps.
- Adding an app to memory requires clicking the `+` button on a `RunningAppCardView`, which calls `viewModel.addAppToMemory(app)`. The button shows a checkmark when already added (`isAlreadyAdded`).
- The enabled list (`MemoryEnabledListView`) is a separate section below a `Divider`, creating a two-zone layout that splits the user's attention.
- No search/filter capability for either section.

### New Design: Unified List

Replace the two-zone layout with a single scrollable list. All memory-relevant apps appear in one list, differentiated by status badges.

**App row content (left to right)**:
1. App icon — `DesignTokens.Sizes.iconLarge` (24px)
2. App name — `Text(app.name)`, `.font(.system(size: 12, weight: .medium))`
3. Last input method — `Text("上次: \(name)")` using `viewModel.lastInputMethodStates[app.bundleId]` (same data source as current `MemoryAppRowView.lastMethodName`), or "暂无记录" if nil
4. Spacer
5. Status badge — see below
6. Add button (only for running apps not yet enabled) — circular button with `+` icon

**Status badges** (implemented as styled `Text` with background):
- Running: green dot prefix + "运行中" text, `Color.green` foreground, `Color.green.opacity(0.12)` background, 4px corner radius
- Enabled: "已启用" text, `Color.accentColor` foreground, `Color.accentColor.opacity(0.12)` background
- Not running (enabled but app closed): gray "未运行" text, `Color.secondary` foreground, `Color.secondary.opacity(0.08)` background

**App ordering**: Running apps first (sorted by name), then not-running enabled apps (sorted by name, dimmed to 0.7 opacity).

**Add interaction**: Click the `+` button calls `viewModel.addAppToMemory(app)`. If it returns false (max limit reached, `Constants.maxMemoryEnabledApps` = 20), show the existing `showLimitAlert`. The `+` button transitions to a checkmark when added (same pattern as current `RunningAppCardView.isAdded` state).

**Info banner**: Below the search bar, a rounded rectangle with `Color.accentColor.opacity(0.06)` background, containing a lightbulb icon and explanation text: "记忆功能会记住应用上次使用的输入法，下次切换到该应用时自动恢复。"

**Search bar**: Same style as app rules page search bar, filters by `app.name.localizedCaseInsensitiveContains(searchText)`.

**Bottom toolbar**:
- Left: "清空全部" button (same `showClearConfirmation` dialog as current `MemoryToolbarView`)
- Right: "共 N 个" count text using `viewModel.memoryEnabledAppsInfo.count`
- Selected count and delete-selected button (same logic as current `MemoryToolbarView`)

### Files Affected

- `MemoryConfigView.swift`: Remove the horizontal `ScrollView`/`LazyHStack`/`RunningAppCardView` section. Replace with unified list.
- `MemoryEnabledListView.swift`: Merge its content into the unified list in `MemoryConfigView`. This file can be removed.
- `MemoryAppRowView.swift`: Adapt to include status badges and add button, or replace with new unified row component.
- `RunningAppCardView.swift`: Remove — no longer needed.
- `MemoryToolbarView.swift`: Keep as-is, or inline into `MemoryConfigView` bottom bar.

## 3. Menu Bar Popover

### Current Problems

- `MenuBarView` shows `RunningAppsView` which renders a `Section` with `AppRowView` items. Each `AppRowView` is a `Menu` that opens a submenu to select input methods — two levels of nesting to change an input method.
- No global toggle to pause/resume auto-switching.
- The current active app is not visually distinguished from other running apps.
- No quick way to switch the global default input method from the menu bar.

### New Design (B+C Hybrid)

Replace the current `MenuBarView` content with a custom popover-style layout rendered as SwiftUI views (not NSMenu items).

**Layout (top to bottom)**:

1. **Global toggle header**: App icon (16px) + "AutoKeySwitch" title + ON/OFF toggle switch. Uses a new `Defaults` key `isAutoSwitchEnabled` (Bool, default true, stored in appGroup suite). When OFF, the running apps section below dims to 0.4 opacity and auto-switching is paused in `InputMethodManager.handleAppActivation` (early return when disabled).

2. **Current active app section**: Only shown when `viewModel.currentActiveAppBundleId` is non-nil. Blue-tinted background (`Color.accentColor.opacity(0.06)`). Shows the active app's icon, name, and current input method name (resolved via `viewModel.getSelectedInputMethodName(for:)`). Displays keyboard shortcut hint `⌘1`.

3. **Other running apps section**: Label "其他运行中" in `.font(.caption)` with `.secondary` foreground. Lists remaining running apps (filtered to exclude the current active app) using the same `AppRowView` pattern but with a single-level menu (no submenu nesting — input method options shown directly in the menu).

4. **Quick switch section**: Label "快速切换" in `.font(.caption)`. Pill-shaped buttons for each `viewModel.inputMethods` entry. Active global default (`viewModel.defaultInputMethod`) gets accent-colored background. Click calls `viewModel.setDefaultInputMethod(method.id)`.

5. **Actions toolbar**: "设置" button (opens main window via existing `NotificationCenter` post for "ShowMainWindow"), "退出" button (calls `NSApplication.shared.terminate`). Styled as bordered buttons in a horizontal HStack.

**Popover width**: 260px (fixed frame).

### New Defaults Key

Add to `Defaults+Extensions.swift`:
```
Key: isAutoSwitchEnabled
Type: Bool
Default: true
Suite: appGroup
```

### Integration Point

In `InputMethodManager.handleAppActivation`, add an early return when `Defaults[.isAutoSwitchEnabled]` is false. This pauses all automatic input method switching without affecting manual switching or settings access.

## 4. HUD (Input Method Switch Indicator)

### Current Problems

- `InputMethodHUDView` renders only a `Text(inputMethodName)` with `.title2` font weight `.medium`. No icon, no color coding.
- `InputMethodHUDPanel` creates an `NSVisualEffectView` with `.hudWindow` material, positions the panel at screen center, and auto-hides after 1.5s with a 0.3s fade. The content is plain text on a blur background.

### New Design — Pill Badge

Replace the `Text`-only content with a pill-shaped badge containing a color-coded indicator dot and the input method name.

**HUD content**:
- Horizontal `HStack` with 8px spacing
- Indicator dot: 8px circle (`Circle()` frame), colored based on input method type:
  - English input (name contains "ABC" or "English"): `Color(red: 0.42, green: 0.66, blue: 0.86)` (#6fa8dc equivalent), with `shadow(color: .blue.opacity(0.4), radius: 3)`
  - Chinese input (all others): `Color.orange`, with `shadow(color: .orange.opacity(0.4), radius: 3)`
- Input method name: `Text(inputMethodName)`, `.font(.system(size: 15, weight: .medium))`, `.foregroundColor(.white.opacity(0.9))`

**Container styling**:
- `RoundedRectangle(cornerRadius: 20)` filled with `Color.black.opacity(0.7)`
- Background: `NSVisualEffectView` with `.hudWindow` material (same as current `InputMethodHUDPanel`) — provides the blur effect
- Padding: 8px vertical, 20px horizontal
- The `NSHostingView` wraps the SwiftUI pill badge content

**No changes to**: Panel positioning (screen center, slightly above middle), display duration (1.5s), fade animation (0.3s), window level (`.floating`), collection behavior (`.canJoinAllSpaces`).

### Files Affected

- `InputMethodHUDView.swift`: Replace `Text(inputMethodName)` body with the pill badge `HStack` layout
- `InputMethodHUDPanel.swift`: No structural changes needed — it already wraps the SwiftUI view in an `NSVisualEffectView`. May need to adjust `contentHuggingPriority` if the new content size differs.

## 5. Preferences Page

### Current Problems

- `PreferencesTab` uses `GroupBox` wrappers for each section ("启动", "显示", "提示", "强制英文符号"). `GroupBox` provides a system-standard look but the visual hierarchy between sections is weak — they all look the same weight.
- Spacing between `GroupBox` sections is inconsistent (the `VStack` spacing is 20px but the `GroupBox` internal padding varies).
- Toggle descriptions are in `.help()` tooltips (hidden by default) rather than visible subtitle text.

### New Design: Section Cards

Replace `GroupBox` with custom rounded-rect section containers.

**Section container**:
- `RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)` (8px) filled with `Color(NSColor.controlBackgroundColor)`
- Border: 1px `Color(NSColor.separatorColor)`
- Section header: a separate HStack with `.background(Color(NSColor.controlBackgroundColor).opacity(0.5))` and the section title in `.font(.system(size: 12, weight: .medium))` with `.secondary` foreground

**Section groups** (same content as current, reorganized):
1. **通用**: "登录时启动" toggle + "切换输入法时显示弹窗提示" toggle (moved from the separate "提示" GroupBox)
2. **显示**: "隐藏菜单栏图标" toggle + "隐藏 Dock 图标" toggle
3. **高级**: "强制英文符号" toggle + help popover + accessibility permission warning (same logic as current)

**Toggle row**: `VStack(alignment: .leading)` containing the label in `.font(.system(size: 12))` and description in `.font(.system(size: 10))` with `.foregroundStyle(.tertiary)`. Toggle switch aligned to the trailing edge via `Spacer()`.

**Import/Export buttons**: Right-aligned `HStack` at the bottom, outside the section cards. Same button labels and actions as current.

**All existing logic preserved**: `isLaunchAtLoginEnabled`, `isMenuBarHidden`, `isDockHidden`, `showHUDOnSwitch`, `forceEnglishPunctuationEnabled`, accessibility permission checks, import/export via `ConfigurationExportService`, all alert/confirmation dialogs.

## 6. Visual Consistency Rules

All values reference existing `DesignTokens` where possible. New tokens are noted.

### Spacing (existing DesignTokens.Spacing)

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Tight gaps |
| `sm` | 8px | Card gap, badge padding |
| `md` | 12px | Card padding, content margins |
| `lg` | 16px | Section gap, header padding |
| `xl` | 20px | HUD horizontal padding |

### Corner Radius (existing DesignTokens.CornerRadius)

| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 4px | Badge corners |
| `md` | 6px | Button corners |
| `lg` | 8px | Card corners, input field corners |
| `xl` | 12px | (existing, unused in new design) |

**New token needed**: `pill: CGFloat = 20` for HUD pill badge and menu bar quick-switch pills.

### Colors (existing DesignTokens.Colors + new)

| Token | Value | Usage |
|-------|-------|-------|
| `selectionHighlight` | accentColor 12% | Card selected background |
| `selectionBorder` | accentColor 30% | Card selected border |
| `hoverBackground` | accentColor 5% | Card hover background |
| `background` | NSColor.controlBackgroundColor | Card background, section background |
| `divider` | NSColor.separatorColor | Card borders |

**New colors needed**:
- `hudEnglishIndicator`: `Color(red: 0.42, green: 0.66, blue: 0.86)` — HUD dot for English input
- `hudChineseIndicator`: `Color.orange` — HUD dot for Chinese input
- `statusRunning`: `Color.green` — Memory page running badge
- `destructive`: `Color(red: 1.0, green: 0.42, blue: 0.42)` — Menu bar exit button

### Typography (existing DesignTokens.Typography + new)

**New tokens needed**:
- `cardTitle`: `.system(size: 13, weight: .medium)` — App name in cards
- `cardSubtitle`: `.system(size: 10)` — Bundle ID, last input method
- `badgeText`: `.system(size: 10)` — Status badge text
- `sectionHeader`: `.system(size: 12, weight: .medium)` — Preference section title
- `menuItemTitle`: `.system(size: 13, weight: .medium)` — Menu bar app name
- `menuItemSubtitle`: `.system(size: 10)` — Menu bar input method name
- `hudText`: `.system(size: 15, weight: .medium)` — HUD input method name

## 7. Files to Modify

| File | Changes |
|------|---------|
| `AppSettingsTab.swift` | Remove column headers. Replace row layout with card layout. Keep search bar, bottom toolbar, add/delete logic, confirmation dialog unchanged. |
| `AppRuleRowV2` (in `AppSettingsTab.swift`) | Redesign body: replace HStack column-aligned layout with card-style HStack containing icon, name, spacer, toggle, picker. Keep `onToggleSelection`, `onInputChange`, `isSelected`, `isHovered` state and callbacks. |
| `MemoryConfigView.swift` | Remove the `VStack` containing the "正在运行的应用" horizontal `ScrollView` section. Replace entire body with search bar + info banner + unified `LazyVStack` list + bottom toolbar. |
| `MemoryEnabledListView.swift` | Remove file — its content is merged into the unified list in `MemoryConfigView`. |
| `MemoryAppRowView.swift` | Adapt or replace: add status badge display, add inline `+` button for non-enabled running apps. Keep `onToggleSelection` and `onRemove` callbacks. |
| `MemoryToolbarView.swift` | Keep file, minor adjustments if bottom toolbar is inlined into `MemoryConfigView`. |
| `RunningAppCardView.swift` | Remove file — horizontal card layout is no longer used. |
| `MenuBarView.swift` | Replace `Group` body with new layout: global toggle header, current active app section, other running apps section, quick switch section, actions toolbar. |
| `InputMethodHUDView.swift` | Replace `Text(inputMethodName)` body with pill badge `HStack` (indicator dot + name). |
| `InputMethodHUDPanel.swift` | No structural changes. Verify `fittingSize` calculation still works with new content dimensions. |
| `PreferencesTab.swift` | Replace `GroupBox` wrappers with custom section card containers. Reorganize sections (merge "提示" into "通用"). Move toggle descriptions from `.help()` to visible subtitle text. |
| `DesignSystem.swift` | Add new tokens: `CornerRadius.pill`, `Colors.hudEnglishIndicator`, `Colors.hudChineseIndicator`, `Colors.statusRunning`, `Colors.destructive`, and new Typography entries listed in section 6. |
| `Defaults+Extensions.swift` | Add `isAutoSwitchEnabled` key (Bool, default true, appGroup suite). |
| `InputMethodManager.swift` | Add early return in `handleAppActivation` when `Defaults[.isAutoSwitchEnabled]` is false. |

## 8. Non-Goals

- No changes to sidebar navigation structure (`SidebarView.swift`, `NavigationVM`)
- No changes to `AddAppSheet.swift` (the add-app modal)
- No changes to data model (`AppInfo`, `InputMethod`) or service layer (`AppListService`, `InputMethodService`, `PermissionService`)
- No new features beyond UI presentation improvements (except the global toggle which is a presentation-layer control for existing behavior)
- No changes to keyboard shortcuts (existing `.keyboardShortcut` modifiers preserved)
- No changes to `MainView.swift` frame size or layout structure

## 9. Risks

- **Migration**: Existing user configurations in `Defaults[.appInputMethodSettings]`, `Defaults[.memoryEnabledApps]`, etc. are not affected — no schema changes.
- **Accessibility**: All new interactive elements (`Toggle`, `Picker`, `Button`) use standard SwiftUI controls which provide built-in accessibility. The pill badge indicator dot should have an `accessibilityLabel` describing the input method type.
- **Performance**: Card layout with many apps (50+) uses `LazyVStack` (same as current `AppSettingsTab`) for efficient rendering.
- **Dark/Light mode**: The design uses semantic colors (`NSColor.controlBackgroundColor`, `NSColor.separatorColor`) which adapt automatically. Custom colors (HUD indicators, status badges) are defined as fixed values — acceptable given the app's primary dark-mode usage.
- **MenuBarView rendering**: The new layout uses standard SwiftUI views inside the menu bar popover. If the popover doesn't render correctly as SwiftUI (vs NSMenu items), fallback to the existing `Section`/`Menu` pattern with the global toggle added as a `Toggle` at the top.
