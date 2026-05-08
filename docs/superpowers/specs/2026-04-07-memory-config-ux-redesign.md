# 短期记忆配置交互优化设计

## 背景

当前短期记忆功能的配置方式存在严重的可用性问题：

- 配置需要在**所有应用列表**中逐个查找、逐个勾选
- 取消配置也要在庞大的列表中一个个找
- 已配置的应用分散在长列表中，缺乏整体视图
- 无法快速批量操作

## 设计目标

1. **独立配置入口**：将记忆配置从通用应用列表中分离出来
2. **手动添加模式**：不预配置应用，用户手动往列表添加
3. **便捷的批量操作**：支持编辑模式下多选删除
4. **清晰的已配置视图**：只显示已启用记忆的应用

---

## 界面设计

### 整体布局

```
┌─────────────────────────────────────────────────────┐
│ 短期记忆配置                                          │
├─────────────────────────────────────────────────────┤
│ 正在运行的应用                                        │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │ Safari  │ │Terminal │ │ WeChat  │ │ Preview │    │
│ │   [+]   │ │   [+]   │ │   [+]   │ │   [+]   │    │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
│                                                     │
│ 搜索应用: [________________________] [搜索]          │
│ ┌─────────┐ ┌─────────┐                            │
│ │ VS Code │ │  Slack  │                            │
│ │   [+]   │ │   [+]   │                            │
│ └─────────┘ └─────────┘                            │
├─────────────────────────────────────────────────────┤
│ 已启用记忆 (3)              [编辑]  [清空全部]       │
│ ┌─────────────────────────────────────────────────┐│
│ │ WeChat                              上次: 拼音  ││
│ │ Terminal                            上次: ABC   ││
│ │ Safari                              上次: 拼音  ││
│ └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

### 编辑模式布局

```
├─────────────────────────────────────────────────────┤
│ 已启用记忆 (3)             [取消]  [删除选中(0)]    │
│ ┌─────────────────────────────────────────────────┐│
│ │ ○ WeChat                              上次: 拼音││
│ │ ● Terminal                            上次: ABC ││
│ │ ○ Safari                              上次: 拼音││
│ └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

选中 2 个应用后：

```
├─────────────────────────────────────────────────────┤
│ 已启用记忆 (3)             [取消]  [删除选中(2)]    │
│ ┌─────────────────────────────────────────────────┐│
│ │ ● WeChat                              上次: 拼音││
│ │ ● Terminal                            上次: ABC ││
│ │ ○ Safari                              上次: 拼音││
│ └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

---

## 交互流程

### 添加应用

**方式一：从运行中的应用添加**

1. 查看「正在运行的应用」区域
2. 点击目标应用卡片上的 [+] 按钮
3. 应用添加到「已启用记忆」列表

**方式二：搜索添加**

1. 在搜索框输入应用名称
2. 点击搜索结果中目标应用卡片的 [+] 按钮
3. 应用添加到「已启用记忆」列表

**约束：**
- 已达到上限（20 个）时，点击 [+] 显示提示：「已达最大数量限制（20 个）」
- 已在记忆列表中的应用，[+] 按钮显示为已添加状态（灰色或显示勾号）

### 移除应用

**单个移除：**

1. 点击「编辑」按钮进入编辑模式
2. 点击目标应用左侧的圆形选择框选中
3. 点击底部「删除选中」按钮

**批量移除：**

1. 点击「编辑」按钮进入编辑模式
2. 点击多个应用左侧的圆形选择框选中
3. 点击底部「删除选中」按钮

**清空全部：**

1. 点击「清空全部」按钮
2. 弹出确认弹窗：「确定要清空所有记忆配置吗？」
3. 点击「确认」清空列表

### 编辑模式状态

| 状态 | 顶部按钮 | 底部操作 |
|------|----------|----------|
| 正常模式 | [编辑] [清空全部] | 无 |
| 编辑模式 | [取消] [删除选中(N)] | 无 |

**进入编辑模式：**
- 顶部按钮变为 [取消] 和 [删除选中(N)]
- 每个应用行左侧出现圆形选择框

**退出编辑模式：**
- 点击 [取消] → 返回正常模式，清空选择
- 删除完成后 → 自动返回正常模式

---

## 数据模型变更

### 新增属性

```swift
// InputMethodManager.swift

/// 已启用记忆的应用信息（用于 UI 展示）
var memoryEnabledAppsInfo: [AppInfo] {
    installedApps.filter { memoryEnabledApps.contains($0.bundleId) }
}
```

### 新增方法

```swift
/// 添加应用到记忆列表
/// - Parameter app: 要添加的应用
/// - Returns: 是否添加成功（可能因已达上限而失败）
@discardableResult
func addAppToMemory(_ app: AppInfo) -> Bool {
    guard memoryEnabledApps.count < Constants.maxMemoryEnabledApps else {
        return false
    }
    memoryEnabledApps.insert(app.bundleId)
    Defaults[.memoryEnabledApps] = memoryEnabledApps
    return true
}

/// 从记忆列表移除应用
/// - Parameter app: 要移除的应用
func removeAppFromMemory(_ app: AppInfo) {
    memoryEnabledApps.remove(app.bundleId)
    lastInputMethodStates.removeValue(forKey: app.bundleId)
    Defaults[.memoryEnabledApps] = memoryEnabledApps
}

/// 批量从记忆列表移除应用
/// - Parameter apps: 要移除的应用列表
func removeAppsFromMemory(_ apps: [AppInfo]) {
    for app in apps {
        memoryEnabledApps.remove(app.bundleId)
        lastInputMethodStates.removeValue(forKey: app.bundleId)
    }
    Defaults[.memoryEnabledApps] = memoryEnabledApps
}

/// 清空所有记忆配置
func clearAllMemory() {
    memoryEnabledApps.removeAll()
    lastInputMethodStates.removeAll()
    Defaults[.memoryEnabledApps] = memoryEnabledApps
}
```

---

## UI 组件设计

### 新建视图文件

| 文件 | 职责 |
|------|------|
| `MemoryConfigView.swift` | 记忆配置主界面 |
| `RunningAppsPicker.swift` | 运行中应用选择区域 |
| `AppSearchPicker.swift` | 应用搜索选择区域 |
| `MemoryEnabledListView.swift` | 已启用记忆的应用列表 |
| `MemoryEditToolbar.swift` | 编辑模式工具栏 |

### MemoryConfigView 结构

```swift
struct MemoryConfigView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var isEditMode = false
    @State private var selectedApps: Set<String> = []
    @State private var searchText = ""
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // 添加区域
            VStack(spacing: 12) {
                RunningAppsPicker(onAdd: addApp)
                AppSearchPicker(searchText: $searchText, onAdd: addApp)
            }
            .padding()

            Divider()

            // 已启用列表
            MemoryEnabledListView(
                isEditMode: isEditMode,
                selectedApps: $selectedApps,
                onRemove: removeSelectedApps
            )

            // 编辑工具栏
            MemoryEditToolbar(
                isEditMode: isEditMode,
                selectedCount: selectedApps.count,
                onEditToggle: toggleEditMode,
                onClearAll: { showClearConfirmation = true }
            )
        }
        .confirmationDialog("确定要清空所有记忆配置吗？", isPresented: $showClearConfirmation) {
            Button("确认清空", role: .destructive) {
                viewModel.clearAllMemory()
            }
        }
    }
}
```

---

## 与现有代码的整合

### 移除的内容

从 `AppSettingsTab.swift` 中移除：
- 「记住上次输入法」Toggle 开关
- 相关的 memory 判断逻辑

保留 `AppSettingsTab` 作为「应用规则配置」界面（仅配置固定输入法规则）。

### 新增 Tab

在菜单栏视图中新增「短期记忆」Tab，放置在「应用规则」Tab 旁边。

---

## 文件变更清单

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `UI/Views/MenuBar/MemoryConfigView.swift` | 新建 | 记忆配置主界面 |
| `UI/Views/MenuBar/RunningAppsPicker.swift` | 新建 | 运行中应用选择组件 |
| `UI/Views/MenuBar/AppSearchPicker.swift` | 新建 | 应用搜索选择组件 |
| `UI/Views/MenuBar/MemoryEnabledListView.swift` | 新建 | 已启用记忆列表组件 |
| `UI/Views/MenuBar/MemoryEditToolbar.swift` | 新建 | 编辑模式工具栏组件 |
| `Services/InputMethod/InputMethodManager.swift` | 修改 | 新增批量操作方法 |
| `UI/Views/MenuBar/AppSettingsTab.swift` | 修改 | 移除记忆相关 Toggle |
| `UI/Views/MenuBar/MenuBarView.swift` | 修改 | 新增「短期记忆」Tab |

---

## 验证方案

### 手动测试用例

1. **添加应用**
   - 点击运行中应用的 [+]，验证添加成功
   - 搜索应用后点击 [+]，验证添加成功
   - 达到上限后点击 [+]，验证显示提示

2. **单个移除**
   - 进入编辑模式，选中一个应用，删除，验证移除成功

3. **批量移除**
   - 进入编辑模式，选中多个应用，删除，验证全部移除成功

4. **清空全部**
   - 点击清空全部，确认，验证列表清空
   - 点击清空全部，取消，验证列表不变

5. **编辑模式状态**
   - 进入编辑模式，点击取消，验证返回正常模式且清空选择
   - 删除后验证自动退出编辑模式

6. **记忆功能核心逻辑**
   - 添加应用到记忆列表，切换应用，验证输入法恢复正确

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 运行中应用列表变化频繁 | 用户点击时应用可能已退出 | 点击时检查应用是否仍在运行，若已退出则提示 |
| 搜索结果为空 | 用户找不到目标应用 | 显示「未找到匹配应用」提示 |
| 批量删除误操作 | 用户误删多个配置 | 删除需两步确认（编辑模式 + 点击删除） |
