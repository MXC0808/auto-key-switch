# 应用规则列表优化设计

## 背景

当前「应用规则」Tab 显示所有已安装应用，用户需要在长列表中逐个查找和配置，交互体验不佳。需要优化为：

1. 初始只显示「已配置的应用」+「运行中未配置的应用」
2. 支持添加和删除应用
3. UI 更加精致

## 设计目标

1. **精简列表**：不显示所有已安装应用，只显示相关应用
2. **添加功能**：用户可以主动添加想要配置的应用
3. **删除功能**：支持单选/多选删除
4. **优化 UI**：提升视觉效果和交互体验

---

## 界面设计

### 整体布局

```
┌─────────────────────────────────────────────────────┐
│ 应用规则                                              │
├─────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────┐│
│ │ [ 搜索应用... ] 🔍                               ││
│ │                                                 ││
│ └─────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────┤
│ ┌─────┬──────────┬───────────────────┐              │
│ │ ○   │ Terminal │ ABC ▼             │              │
│ ├─────┼──────────┼───────────────────┤              │
│ │ ○   │ WeChat   │ 拼音 ▼            │              │
│ ├─────┼──────────┼───────────────────┤              │
│ │ ○   │ Mail     │ 使用默认 ▼        │              │
│ ├─────┼──────────┼───────────────────┤              │
│ │ ○   │ Safari   │ 使用默认 ▼        │              │
│ └─────┴──────────┴───────────────────┘              │
├─────────────────────────────────────────────────────┤
│ 全局默认输入法: [ 选择输入法 ▼ ]                     │
│                                                     │
│ [ 添加应用 ]  [ 删除选中(0) ]                        │
└─────────────────────────────────────────────────────┘
```

### 选中状态

```
├─────────────────────────────────────────────────────┤
│ ┌─────┬──────────┬───────────────────┐              │
│ │ ●   │ WeChat   │ 拼音 ▼            │ ← 选中高亮   │
│ ├─────┼──────────┼───────────────────┤              │
│ │ ○   │ Terminal │ ABC ▼             │              │
│ └─────┴──────────┴───────────────────┘              │
├─────────────────────────────────────────────────────┤
│ [ 添加应用 ]  [ 删除选中(1) ]                        │
└─────────────────────────────────────────────────────┘
```

### 添加应用弹窗

```
┌─────────────────────────────────────────┐
│ 添加应用                                 │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐│
│ │ [ 搜索应用... ]                     ││
│ └─────────────────────────────────────┘│
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐│
│ │ AppIcon  Safari          [ + ]     ││
│ │ AppIcon  Preview         [ + ]     ││
│ │ AppIcon  Slack           [ + ]     ││
│ │ AppIcon  VS Code         [ + ]     ││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

---

## 列表内容规则

### 显示内容

列表显示以下应用的并集：

1. **已配置输入法的应用** - 存在于 `appInputMethodSettings` 中的应用
2. **运行中未配置的应用** - 在 `runningApps` 中但未配置输入法的应用

### 排序规则

```
已配置的应用（按应用名升序）
↓
运行中未配置的应用（按应用名升序）
```

### 示例

假设：
- 已配置：WeChat、Terminal
- 运行中：Mail、Safari、WeChat、Preview

列表顺序：
```
Terminal  (已配置，按名称排)
WeChat    (已配置，按名称排)
Mail      (运行中未配置，按名称排)
Safari    (运行中未配置，按名称排)
Preview   (运行中未配置，按名称排)
```

---

## 交互流程

### 选择应用

| 操作 | 结果 |
|------|------|
| 点击某行 | 选中该行，取消其他选中 |
| Cmd + 点击 | 多选，切换选中状态 |
| 点击空白区域 | 取消所有选中 |

### 删除应用

1. 选中一个或多个应用
2. 点击底部「删除选中(N)」按钮
3. 从列表中移除，同时清除该应用的输入法配置

### 添加应用

1. 点击底部「添加应用」按钮
2. 弹出添加应用弹窗
3. 在搜索框输入应用名或直接浏览列表
4. 点击应用右侧的 [+] 按钮
5. 应用添加到列表，弹窗保持打开（可继续添加）
6. 点击弹窗外部或关闭按钮关闭弹窗

**约束：**
- 已在列表中的应用，[+] 按钮显示为已添加状态（灰色或显示勾号）
- 搜索结果不显示已在列表中的应用

---

## 数据模型变更

### InputMethodManager 新增方法

```swift
/// 获取应用规则列表显示的应用
var appRulesListApps: [AppInfo] {
    // 已配置的应用
    let configuredApps = installedApps.filter { app in
        getInputMethod(for: app) != nil
    }
    // 运行中未配置的应用
    let runningUnconfigured = runningApps.filter { app in
        getInputMethod(for: app) == nil
    }
    // 合并去重
    let allApps = configuredApps + runningUnconfigured
    let uniqueApps = Dictionary(grouping: allApps, by: { $0.bundleId })
        .values
        .compactMap { $0.first }
    // 排序：已配置在前，运行中未配置在后
    return uniqueApps.sorted { app1, app2 in
        let app1Configured = getInputMethod(for: app1) != nil
        let app2Configured = getInputMethod(for: app2) != nil
        if app1Configured != app2Configured {
            return app1Configured
        }
        return app1.name.localizedCompare(app2.name) == .orderedAscending
    }
}

/// 检查应用是否在规则列表中
func isAppInRulesList(_ app: AppInfo) -> Bool {
    return getInputMethod(for: app) != nil || runningApps.contains(where: { $0.bundleId == app.bundleId })
}
```

---

## UI 组件设计

### 文件结构

| 文件 | 职责 |
|------|------|
| `AppSettingsTab.swift` | 主界面（重构） |
| `AppRuleRow.swift` | 应用规则行组件（新建） |
| `AddAppSheet.swift` | 添加应用弹窗（新建） |

### AppSettingsTab 结构

```swift
struct AppSettingsTab: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var selectedApps: Set<String> = []
    @State private var searchText = ""
    @State private var showAddSheet = false

    var filteredApps: [AppInfo] {
        // 搜索过滤逻辑
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            // 应用列表
            // 底部工具栏（全局默认 + 添加/删除按钮）
        }
        .sheet(isPresented: $showAddSheet) {
            AddAppSheet()
        }
    }
}
```

### AppRuleRow 结构

```swift
struct AppRuleRow: View {
    let app: AppInfo
    let isSelected: Bool
    let isConfigured: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 选择圆圈
            // 应用图标
            // 应用名称
            // 输入法选择器
        }
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .onTapGesture {
            // 处理选择逻辑
        }
    }
}
```

### AddAppSheet 结构

```swift
struct AddAppSheet: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var searchResults: [AppInfo] {
        // 搜索已安装应用，排除已在列表中的
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            // 搜索框
            // 搜索结果列表
        }
        .frame(width: 400, height: 500)
    }
}
```

---

## 文件变更清单

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `AppSettingsTab.swift` | 重写 | 重新设计主界面 |
| `AppRuleRow.swift` | 新建 | 应用规则行组件 |
| `AddAppSheet.swift` | 新建 | 添加应用弹窗组件 |
| `InputMethodManager.swift` | 修改 | 新增 `appRulesListApps` 计算属性 |

---

## 与现有功能的兼容

### 删除应用

- 从列表中移除 = 清除该应用的输入法配置
- 调用 `setInputMethod(for: app, to: nil)`
- 下次该应用运行时，会显示在「运行中未配置的应用」部分

### 搜索功能

- 搜索框同时过滤已配置和运行中未配置的应用
- 搜索结果按原有排序规则显示

---

## 验证方案

### 手动测试用例

1. **列表显示**
   - 验证已配置应用显示在前
   - 验证运行中未配置应用显示在后
   - 验证排序正确

2. **选择功能**
   - 点击单选
   - Cmd + 点击多选
   - 点击空白取消选中

3. **删除功能**
   - 单选删除
   - 多选删除
   - 验证删除后应用从列表消失

4. **添加功能**
   - 打开添加弹窗
   - 搜索应用
   - 点击添加
   - 验证已添加应用不重复显示

5. **输入法切换**
   - 切换某应用的输入法
   - 验证列表实时更新
