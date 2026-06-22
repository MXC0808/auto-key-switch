# UI Optimization Design — AutoKeySwitch

## Overview

Comprehensive UI optimization for AutoKeySwitch covering all four main areas: app rules page, memory config page, menu bar popover, and HUD. The goal is to improve layout precision, simplify operations, enhance HUD readability, and unify visual consistency.

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

- Column alignment relies on hardcoded widths, causing misalignment across different input method name lengths
- Selection highlight is not prominent enough
- Row height is too large, low information density
- Force English punctuation toggle and Picker positions are unstable

### New Design

**Card-based layout**: Each app rule is a self-contained card with:
- App icon (32x32, 7px corner radius) on the left
- App name + bundle ID in the middle
- Force English punctuation toggle (fixed position)
- Input method picker (fixed on right side)

**Card structure** (left to right):
```
[Icon] [Name + BundleID] ........... [English Punctuation Toggle] [Input Method Picker ▼]
```

**Interaction**:
- Click card to select (single select by default)
- Command+click for multi-select
- Shift+click for range select
- Inline Picker directly accessible, no extra click needed

**Visual**:
- Card background: `#222` with `1px #2a2a2a` border
- Selected state: `rgba(100,149,237,0.3)` border + left accent bar (3px, accent color)
- Hover state: subtle background change
- Card corner radius: 10px
- Card gap: 8px
- Card padding: 12px 14px

**Search bar**: Rounded (8px), with magnifying glass icon, placed above the list.

**Bottom toolbar**:
- Left: Add button (+), Delete button (trash), selected count
- Right: Global default input method picker

### Key Changes

- Remove column headers (no longer needed with card layout)
- Each card is self-contained, no cross-card alignment issues
- Picker width fixed at a reasonable size, truncates long names

## 2. Memory Config Page

### Current Problems

- Running apps use horizontal scroll cards, requires left-right scrolling
- Adding apps requires finding the card and clicking + button
- Enabled list and running apps are separated, creating a fragmented mental model
- No search functionality

### New Design

**Unified list**: All apps (running, enabled, not-running) in a single scrollable list.

**App row structure**:
```
[Icon] [Name] [Last Input Method] [Status Badge] [Add Button]
```

**Status badges**:
- `● 运行中` — green dot + text, green-tinted background
- `已启用` — blue text, blue-tinted background
- `未运行` — gray text, gray background

**Add interaction**: Each non-enabled running app shows a circular `+` button on the right. Click to add immediately (inline, no sheet/dialog).

**Info banner**: Light blue banner below search bar explaining the memory feature.

**Search bar**: Same style as app rules page, filters by app name.

**Bottom toolbar**:
- Left: "清空全部" button (destructive)
- Right: Total enabled count

**Enabled app row** (when app is also running):
```
[Icon] [Name] [上次: 简体拼音] [● 运行中] [已启用]
```

**Not-running enabled app** (dimmed, 70% opacity):
```
[Icon] [Name] [上次: ABC] [未运行] [已启用]
```

## 3. Menu Bar Popover

### Current Problems

- Running apps nested in secondary menus, deep hierarchy
- No global toggle to pause/resume
- Current active app not highlighted
- No quick way to switch global input method

### New Design (B+C Hybrid)

**Layout** (top to bottom):
1. **Global toggle header**: App icon + "AutoKeySwitch" + ON/OFF switch
2. **Current active app**: Highlighted with blue-tinted background, shows current input method
3. **Other running apps**: Grouped under "其他运行中" label
4. **Quick switch**: Two buttons for switching global input method (e.g., "简体拼音" / "ABC")
5. **Actions toolbar**: "设置" button + "退出" button

**Global toggle**:
- When OFF: auto-switching of input methods is paused (no automatic switching on app focus change). Manual switching via menu bar still works.
- State persisted in Defaults as a new key `isAutoSwitchEnabled` (default: true)
- UI dims the running apps section when OFF, but settings remain accessible

**Current active app section**:
- Blue-tinted background (`rgba(100,149,237,0.06)`)
- Shows app icon, name, current input method
- Keyboard shortcut hint (⌘1)

**Quick switch section**:
- Pill-shaped buttons for each available input method
- Active method highlighted with blue tint
- Click to switch the **global default input method** (not the current app's method). This is equivalent to changing the "全局默认" picker in the app rules page.

**Popover width**: 260px (fixed)

## 4. HUD (Input Method Switch Indicator)

### Current Problems

- Plain text only, no visual icon
- Low recognition at a glance
- No color coding for input method type

### New Design — Pill Badge

**Shape**: Rounded pill (20px border-radius)

**Structure**:
```
[●  Indicator Dot] [Input Method Name]
```

**Visual**:
- Background: `rgba(40,40,40,0.9)` with `backdrop-filter: blur(20px)`
- Border: `1px rgba(255,255,255,0.08)`
- Shadow: `0 4px 24px rgba(0,0,0,0.4)`
- Padding: `8px 20px`

**Indicator dot**:
- English input (ABC): `#6fa8dc` (blue), with `box-shadow: 0 0 6px rgba(111,168,220,0.4)`
- Chinese input: `#ff9500` (orange), with `box-shadow: 0 0 6px rgba(255,149,0,0.4)`

**Text**: 15px, weight 500, `#e0e0e0`, letter-spacing 0.3px

**App context variant**: App icon + divider + indicator dot + name. Only shown when the HUD is triggered by an app-specific rule (not global default switch). This is an optional enhancement — implement only if it adds no significant complexity.

**Position**: Center of screen, slightly above middle (same as current)

**Duration**: 1.5s display, 0.3s fade-out animation (same as current)

## 5. Preferences Page

### Current Problems

- Flat GroupBox layout, visual hierarchy unclear
- Inconsistent spacing between sections
- Toggle descriptions mixed with labels

### New Design

**Section cards**: Each preference group is a rounded card (10px corner radius) with:
- Section header: darker background (`#252525`), shows section name
- Content area: toggle rows with label + description + switch

**Section groups**:
1. **通用**: 启动时登录, 切换时显示 HUD
2. **显示**: 隐藏菜单栏图标, 隐藏 Dock 图标
3. **高级**: 强制英文符号

**Toggle row structure**:
```
[Label + Description] ......................... [Toggle Switch]
```

- Label: 12px, `#ccc`
- Description: 10px, `#555`
- Toggle: standard iOS-style switch

**Import/Export**: Right-aligned buttons at the bottom, outside the cards.

## 6. Visual Consistency Rules

### Spacing

- Card gap: 8px
- Card padding: 12px 14px
- Section gap: 16px
- Content padding: 16px

### Corner Radius

- Cards: 10px
- Buttons: 6px
- Input fields: 8px
- Pills/badges: 20px

### Colors

- Card background: `#222`
- Card border: `#2a2a2a`
- Selected border: `rgba(100,149,237,0.3)`
- Active accent: `#6fa8dc`
- Success/running: `#34c759`
- Warning: `#ff9500`
- Destructive: `#ff6b6b`
- Text primary: `#ddd` / `#ccc`
- Text secondary: `#888` / `#666`
- Text tertiary: `#555`

### Typography

- Card title: 12-13px, weight 500
- Card subtitle: 10px
- Badge text: 9-10px
- Section header: 12px, weight 500

## 7. Files to Modify

| File | Changes |
|------|---------|
| `AppSettingsTab.swift` | Replace table layout with card layout |
| `AppRowView.swift` / `AppRuleRowV2` | Redesign as card component |
| `MemoryConfigView.swift` | Replace horizontal cards with unified list |
| `MemoryEnabledListView.swift` | Merge into unified list |
| `MemoryAppRowView.swift` | Add status badges, inline add |
| `MemoryToolbarView.swift` | Simplify bottom toolbar |
| `RunningAppCardView.swift` | Remove (no longer needed) |
| `MenuBarView.swift` | Add global toggle, restructure layout |
| `InputMethodHUDView.swift` | Replace with pill badge design |
| `InputMethodHUDPanel.swift` | Update styling for pill badge |
| `PreferencesTab.swift` | Replace GroupBox with section cards |
| `ContentHeaderView.swift` | Minor alignment adjustments |
| `SidebarView.swift` | No changes needed |
| `DesignSystem.swift` | Add new color/spacing tokens if needed |

## 8. Non-Goals

- No changes to the sidebar navigation structure
- No changes to the add app sheet (AddAppSheet.swift)
- No changes to the data model or service layer
- No new features beyond UI presentation improvements
- No changes to keyboard shortcuts

## 9. Risks

- **Migration**: Existing user configurations must continue to work without changes
- **Accessibility**: All new interactive elements must have proper accessibility labels
- **Performance**: Card layout with many apps (50+) should remain smooth with LazyVStack
- **Dark/Light mode**: All colors must be tested in both appearances (currently dark-only is acceptable given the app's nature)
