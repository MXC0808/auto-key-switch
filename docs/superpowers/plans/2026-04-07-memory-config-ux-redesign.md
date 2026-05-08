# 短期记忆配置交互优化实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将短期记忆配置从「全部应用列表逐个勾选」改为「独立配置界面 + 手动添加」，支持批量删除。

**Architecture:** 新建独立的 MemoryConfigView 作为配置入口，包含运行中应用选择、搜索添加、已启用列表三个区域。在 MainView 中新增 Tab 页。InputMethodManager 新增批量操作方法。

**Tech Stack:** Swift 5.9, SwiftUI, macOS 13+, Defaults

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `InputMethodManager.swift` | 新增批量操作方法 |
| `MemoryConfigView.swift` | 记忆配置主界面 |
| `RunningAppsPicker.swift` | 运行中应用选择区域 |
| `AppSearchPicker.swift` | 应用搜索选择区域 |
| `MemoryEnabledListView.swift` | 已启用记忆列表（含编辑模式） |
| `MemoryEditToolbar.swift` | 底部工具栏（编辑/清空） |
| `MainView.swift` | 新增「短期记忆」Tab |
| `AppSettingsTab.swift` | 移除记忆相关 Toggle |

---

## Task 1: InputMethodManager 新增批量操作方法

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 添加 memoryEnabledAppsInfo 计算属性**

在 `InputMethodManager.swift` 的 `// MARK: - Memory Feature Properties` 区域后添加：

```swift
/// 已启用记忆的应用信息（用于 UI 展示）
var memoryEnabledAppsInfo: [AppInfo] {
    installedApps.filter { memoryEnabledApps.contains($0.bundleId) }
}
```

- [ ] **Step 2: 添加 addAppToMemory 方法**

在 `// MARK: - Memory Feature Methods` 区域添加：

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
```

- [ ] **Step 3: 添加 removeAppFromMemory 方法**

```swift
/// 从记忆列表移除应用
/// - Parameter app: 要移除的应用
func removeAppFromMemory(_ app: AppInfo) {
    memoryEnabledApps.remove(app.bundleId)
    lastInputMethodStates.removeValue(forKey: app.bundleId)
    Defaults[.memoryEnabledApps] = memoryEnabledApps
}
```

- [ ] **Step 4: 添加 removeAppsFromMemory 批量移除方法**

```swift
/// 批量从记忆列表移除应用
/// - Parameter apps: 要移除的应用列表
func removeAppsFromMemory(_ apps: [AppInfo]) {
    for app in apps {
        memoryEnabledApps.remove(app.bundleId)
        lastInputMethodStates.removeValue(forKey: app.bundleId)
    }
    Defaults[.memoryEnabledApps] = memoryEnabledApps
}
```

- [ ] **Step 5: 添加 clearAllMemory 方法**

```swift
/// 清空所有记忆配置
func clearAllMemory() {
    memoryEnabledApps.removeAll()
    lastInputMethodStates.removeAll()
    Defaults[.memoryEnabledApps] = memoryEnabledApps
}
```

- [ ] **Step 6: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build
```

---

## Task 2: 创建 RunningAppsPicker 组件

**Files:**
- Create: `AutoKeySwitch/Sources/UI/Views/MenuBar/RunningAppsPicker.swift`

- [ ] **Step 1: 创建 RunningAppsPicker.swift**

```swift
import SwiftUI

/// 运行中应用选择区域
struct RunningAppsPicker: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let onAdd: (AppInfo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("正在运行的应用")
                .font(.headline)

            if viewModel.runningApps.isEmpty {
                Text("暂无运行中的应用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.runningApps) { app in
                            RunningAppCard(app: app, onAdd: onAdd)
                        }
                    }
                }
            }
        }
    }
}

/// 运行中应用卡片
struct RunningAppCard: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let app: AppInfo
    let onAdd: (AppInfo) -> Void

    var isAlreadyAdded: Bool {
        viewModel.memoryEnabledApps.contains(app.bundleId)
    }

    var body: some View {
        VStack(spacing: 6) {
            app.icon
                .frame(width: 40, height: 40)

            Text(app.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 60)

            Button(action: {
                onAdd(app)
            }) {
                Image(systemName: isAlreadyAdded ? "checkmark" : "plus")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .disabled(isAlreadyAdded)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    RunningAppsPicker(onAdd: { _ in })
        .environmentObject(InputMethodManager.shared)
        .frame(width: 400)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | grep -E "(error:|warning:)" | head -20
```

---

## Task 3: 创建 AppSearchPicker 组件

**Files:**
- Create: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSearchPicker.swift`

- [ ] **Step 1: 创建 AppSearchPicker.swift**

```swift
import SwiftUI

/// 应用搜索选择区域
struct AppSearchPicker: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Binding var searchText: String
    let onAdd: (AppInfo) -> Void

    var searchResults: [AppInfo] {
        guard !searchText.isEmpty else { return [] }
        return viewModel.installedApps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) &&
            !viewModel.memoryEnabledApps.contains(app.bundleId)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索应用", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)

            if !searchText.isEmpty {
                if searchResults.isEmpty {
                    Text("未找到匹配应用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(searchResults.prefix(10)) { app in
                                SearchAppCard(app: app, onAdd: onAdd)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// 搜索结果应用卡片
struct SearchAppCard: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let app: AppInfo
    let onAdd: (AppInfo) -> Void

    var body: some View {
        VStack(spacing: 6) {
            app.icon
                .frame(width: 32, height: 32)

            Text(app.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 70)

            Button(action: {
                onAdd(app)
            }) {
                Image(systemName: "plus")
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

#Preview {
    AppSearchPicker(searchText: .constant("Safari"), onAdd: { _ in })
        .environmentObject(InputMethodManager.shared)
        .frame(width: 400)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | grep -E "(error:|warning:)" | head -20
```

---

## Task 4: 创建 MemoryEnabledListView 组件

**Files:**
- Create: `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryEnabledListView.swift`

- [ ] **Step 1: 创建 MemoryEnabledListView.swift**

```swift
import SwiftUI

/// 已启用记忆的应用列表
struct MemoryEnabledListView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let isEditMode: Bool
    @Binding var selectedApps: Set<String>
    let onRemove: ([AppInfo]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("已启用记忆 (\(viewModel.memoryEnabledAppsInfo.count))")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            // List
            if viewModel.memoryEnabledAppsInfo.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("暂无已启用记忆的应用")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("从上方运行中应用或搜索添加")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxHeight: .infinity)
            } else {
                List(viewModel.memoryEnabledAppsInfo, id: \.bundleId) { app in
                    MemoryAppRow(
                        app: app,
                        isEditMode: isEditMode,
                        isSelected: selectedApps.contains(app.bundleId),
                        onToggleSelection: {
                            if selectedApps.contains(app.bundleId) {
                                selectedApps.remove(app.bundleId)
                            } else {
                                selectedApps.insert(app.bundleId)
                            }
                        }
                    )
                }
                .listStyle(.plain)
            }
        }
    }
}

/// 记忆应用行视图
struct MemoryAppRow: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let app: AppInfo
    let isEditMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var lastMethodName: String? {
        guard let lastId = viewModel.lastInputMethodStates[app.bundleId],
              let method = viewModel.inputMethods.first(where: { $0.id == lastId }) else {
            return nil
        }
        return method.name
    }

    var body: some View {
        HStack(spacing: 12) {
            // Selection circle (edit mode)
            if isEditMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)
            }

            // App icon
            app.icon
                .frame(width: 24, height: 24)

            // App name
            Text(app.name)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            // Last used input method
            if let name = lastMethodName {
                Text("上次: \(name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("暂无记录")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditMode {
                onToggleSelection()
            }
        }
    }
}

#Preview {
    MemoryEnabledListView(
        isEditMode: false,
        selectedApps: .constant([]),
        onRemove: { _ in }
    )
    .environmentObject(InputMethodManager.shared)
    .frame(width: 400, height: 300)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | grep -E "(error:|warning:)" | head -20
```

---

## Task 5: 创建 MemoryEditToolbar 组件

**Files:**
- Create: `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryEditToolbar.swift`

- [ ] **Step 1: 创建 MemoryEditToolbar.swift**

```swift
import SwiftUI

/// 编辑模式工具栏
struct MemoryEditToolbar: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let isEditMode: Bool
    let selectedCount: Int
    let onEditToggle: () -> Void
    let onClearAll: () -> Void

    var body: some View {
        HStack {
            if isEditMode {
                // Edit mode buttons
                Button("取消") {
                    onEditToggle()
                }

                Spacer()

                Button(action: {}) {
                    Text("删除选中(\(selectedCount))")
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
            } else {
                // Normal mode buttons
                Button("编辑") {
                    onEditToggle()
                }
                .disabled(viewModel.memoryEnabledAppsInfo.isEmpty)

                Button("清空全部") {
                    onClearAll()
                }
                .disabled(viewModel.memoryEnabledAppsInfo.isEmpty)

                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    VStack {
        MemoryEditToolbar(
            isEditMode: false,
            selectedCount: 0,
            onEditToggle: {},
            onClearAll: {}
        )
        MemoryEditToolbar(
            isEditMode: true,
            selectedCount: 2,
            onEditToggle: {},
            onClearAll: {}
        )
    }
    .environmentObject(InputMethodManager.shared)
    .frame(width: 400)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | grep -E "(error:|warning:)" | head -20
```

---

## Task 6: 创建 MemoryConfigView 主界面

**Files:**
- Create: `AutoKeySwitch/Sources/UI/Views/MenuBar/MemoryConfigView.swift`

- [ ] **Step 1: 创建 MemoryConfigView.swift**

```swift
import SwiftUI

/// 短期记忆配置主界面
struct MemoryConfigView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var isEditMode = false
    @State private var selectedApps: Set<String> = []
    @State private var searchText = ""
    @State private var showClearConfirmation = false
    @State private var showLimitAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Add section
            VStack(spacing: 12) {
                RunningAppsPicker(onAdd: addApp)
                AppSearchPicker(searchText: $searchText, onAdd: addApp)
            }
            .padding()

            Divider()

            // Enabled list
            MemoryEnabledListView(
                isEditMode: isEditMode,
                selectedApps: $selectedApps,
                onRemove: removeSelectedApps
            )

            // Edit toolbar
            MemoryEditToolbar(
                isEditMode: isEditMode,
                selectedCount: selectedApps.count,
                onEditToggle: toggleEditMode,
                onClearAll: { showClearConfirmation = true }
            )
        }
        .alert("已达最大数量限制（20 个）", isPresented: $showLimitAlert) {
            Button("确定", role: .cancel) {}
        }
        .confirmationDialog(
            "确定要清空所有记忆配置吗？",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("确认清空", role: .destructive) {
                viewModel.clearAllMemory()
            }
        } message: {
            Text("此操作不可撤销")
        }
    }

    // MARK: - Actions

    private func addApp(_ app: AppInfo) {
        let success = viewModel.addAppToMemory(app)
        if !success {
            showLimitAlert = true
        }
        // Clear search after adding
        searchText = ""
    }

    private func toggleEditMode() {
        withAnimation {
            isEditMode.toggle()
            if !isEditMode {
                selectedApps.removeAll()
            }
        }
    }

    private func removeSelectedApps(_ apps: [AppInfo]) {
        let toRemove = apps.filter { selectedApps.contains($0.bundleId) }
        viewModel.removeAppsFromMemory(toRemove)
        selectedApps.removeAll()
        withAnimation {
            isEditMode = false
        }
    }
}

#Preview {
    MemoryConfigView()
        .environmentObject(InputMethodManager.shared)
        .frame(width: 500, height: 500)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | grep -E "(error:|warning:)" | head -20
```

---

## Task 7: 更新 MainView 添加短期记忆 Tab

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/MainView.swift`

- [ ] **Step 1: 添加短期记忆 Tab**

修改 `MainView.swift`：

```swift
import SwiftUI

/// Main window view with tabs
struct MainView: View {
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        TabView {
            AppSettingsTab()
                .tabItem {
                    Label("应用规则", systemImage: "app.badge")
                }

            MemoryConfigView()
                .tabItem {
                    Label("短期记忆", systemImage: "brain")
                }

            PreferencesTab()
                .tabItem {
                    Label("偏好设置", systemImage: "gear")
                }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    MainView()
        .environmentObject(InputMethodManager.shared)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | grep -E "(error:|warning:)" | head -20
```

---

## Task 8: 从 AppSettingsTab 移除记忆相关 Toggle

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`

- [ ] **Step 1: 移除 AppSettingRow 中的记忆 Toggle**

修改 `AppSettingsTab.swift`，将 `AppSettingRow` 修改为：

```swift
/// Single app row with input method selector
struct AppSettingRow: View {
    let app: AppInfo
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        HStack(spacing: 12) {
            // App icon and name
            app.icon
                .frame(width: 24, height: 24)
            Text(app.name)
                .frame(minWidth: 120, alignment: .leading)

            Spacer()

            // Input method selector
            Picker("", selection: Binding(
                get: { viewModel.getInputMethod(for: app) ?? "" },
                set: { newValue in
                    viewModel.setInputMethod(for: app, to: newValue.isEmpty ? nil : newValue)
                }
            )) {
                HStack(spacing: 4) {
                    Image(systemName: "circle.dashed")
                    Text("使用默认")
                }.tag("")
                ForEach(viewModel.inputMethods) { method in
                    HStack(spacing: 4) {
                        if let icon = method.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "keyboard")
                                .frame(width: 16, height: 16)
                        }
                        Text(method.name)
                    }.tag(method.id)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)
        }
        .padding(.vertical, 4)
    }
}
```

同时移除顶部的 `VStack(alignment: .leading, spacing: 6)` 包装和底部的记忆相关行。

- [ ] **Step 2: 更新 body 移除 VStack 包装**

`AppSettingsTab` 的 body 部分保持不变，只是 `AppSettingRow` 不再包含记忆 Toggle。

- [ ] **Step 3: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | grep -E "(error:|warning:)" | head -20
```

---

## Task 9: 完整构建验证

- [ ] **Step 1: 清理并完整构建**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug clean build
```

- [ ] **Step 2: 运行应用进行手动测试**

测试项目：
1. 点击「短期记忆」Tab，验证界面正常显示
2. 点击运行中应用的 [+] 按钮，验证添加成功
3. 搜索应用并点击 [+]，验证添加成功
4. 点击「编辑」进入编辑模式，选中多个应用，删除
5. 点击「清空全部」，确认清空

---

## Spec 覆盖检查

| Spec 要求 | 任务 |
|-----------|------|
| 独立配置入口 | Task 6: MemoryConfigView |
| 手动添加模式 | Task 2, 3: RunningAppsPicker + AppSearchPicker |
| 批量删除 | Task 4, 5: MemoryEnabledListView + MemoryEditToolbar |
| 清晰的已配置视图 | Task 4: MemoryEnabledListView |
| 新增 Tab | Task 7: MainView |
| 移除旧 Toggle | Task 8: AppSettingsTab |
| 批量操作方法 | Task 1: InputMethodManager |
