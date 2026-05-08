# 应用规则列表优化实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重构应用规则列表，从显示所有已安装应用改为只显示已配置+运行中未配置的应用，支持添加/删除操作。

**Architecture:** 新建 `AppRuleRow` 和 `AddAppSheet` 组件，重构 `AppSettingsTab` 主界面，在 `InputMethodManager` 中新增 `appRulesListApps` 计算属性。

**Tech Stack:** Swift 5.9, SwiftUI, macOS 13+, Defaults

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `InputMethodManager.swift` | 新增 `appRulesListApps` 计算属性 |
| `AppRuleRow.swift` | 应用规则行组件（选择圆圈 + 图标 + 名称 + 输入法选择器） |
| `AddAppSheet.swift` | 添加应用弹窗（搜索 + 应用列表） |
| `AppSettingsTab.swift` | 主界面重构（搜索框 + 列表 + 底部工具栏） |

---

## Task 1: InputMethodManager 新增 appRulesListApps 计算属性

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 添加 appRulesListApps 计算属性**

在 `InputMethodManager.swift` 的 `// MARK: - UI Helper Methods` 区域添加：

```swift
/// 获取应用规则列表显示的应用（已配置 + 运行中未配置）
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
    var seen = Set<String>()
    let allApps = (configuredApps + runningUnconfigured).filter { app in
        if seen.contains(app.bundleId) {
            return false
        }
        seen.insert(app.bundleId)
        return true
    }
    // 排序：已配置在前，运行中未配置在后
    return allApps.sorted { app1, app2 in
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

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | tail -5
```

---

## Task 2: 创建 AppRuleRow 组件

**Files:**
- Create: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppRuleRow.swift`

- [ ] **Step 1: 创建 AppRuleRow.swift**

```swift
import SwiftUI

/// 应用规则行组件
struct AppRuleRow: View {
    let app: AppInfo
    let isSelected: Bool
    let isConfigured: Bool
    let onToggleSelection: () -> Void
    let onInputChange: (String?) -> Void

    @EnvironmentObject private var viewModel: InputMethodManager

    var currentSelection: String {
        viewModel.getInputMethod(for: app) ?? ""
    }

    var body: some View {
        HStack(spacing: 12) {
            // 选择圆圈
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)

            // 应用图标
            app.icon
                .frame(width: 24, height: 24)

            // 应用名称
            Text(app.name)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            // 输入法选择器
            Picker("", selection: Binding(
                get: { currentSelection },
                set: { newValue in
                    onInputChange(newValue.isEmpty ? nil : newValue)
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
            .frame(width: 160)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleSelection()
        }
    }
}

#Preview {
    VStack {
        AppRuleRow(
            app: AppInfo(bundleId: "test", name: "Test App", iconPath: "/"),
            isSelected: true,
            isConfigured: true,
            onToggleSelection: {},
            onInputChange: { _ in }
        )
        AppRuleRow(
            app: AppInfo(bundleId: "test2", name: "Test App 2", iconPath: "/"),
            isSelected: false,
            isConfigured: false,
            onToggleSelection: {},
            onInputChange: { _ in }
        )
    }
    .environmentObject(InputMethodManager.shared)
    .frame(width: 500)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | tail -5
```

---

## Task 3: 创建 AddAppSheet 组件

**Files:**
- Create: `AutoKeySwitch/Sources/UI/Views/MenuBar/AddAppSheet.swift`

- [ ] **Step 1: 创建 AddAppSheet.swift**

```swift
import SwiftUI

/// 添加应用弹窗
struct AddAppSheet: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var searchResults: [AppInfo] {
        let apps = viewModel.installedApps
        let filtered = searchText.isEmpty ? apps : apps.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) 
        }
        // 排除已在规则列表中的应用
        return filtered.filter { !viewModel.isAppInRulesList($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("添加应用")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索应用", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // 应用列表
            if viewModel.installedApps.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    ProgressView("加载应用列表...")
                    Spacer()
                }
            } else if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text(searchText.isEmpty ? "所有应用已在列表中" : "未找到匹配应用")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List(searchResults) { app in
                    AddAppRow(app: app, onAdd: addApp)
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 400, height: 500)
        .task {
            // 确保已加载已安装应用列表
            await viewModel.forceRefreshInstalledApps()
        }
    }

    private func addApp(_ app: AppInfo) {
        // 设置为使用默认输入法
        viewModel.setInputMethod(for: app, to: nil)
    }
}

/// 添加应用行
struct AddAppRow: View {
    let app: AppInfo
    let onAdd: (AppInfo) -> Void

    var body: some View {
        HStack(spacing: 12) {
            app.icon
                .frame(width: 24, height: 24)

            Text(app.name)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            Button(action: { onAdd(app) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddAppSheet()
        .environmentObject(InputMethodManager.shared)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | tail -5
```

---

## Task 4: 重构 AppSettingsTab 主界面

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppSettingsTab.swift`

- [ ] **Step 1: 重写 AppSettingsTab.swift**

```swift
import SwiftUI

/// 应用规则设置界面
struct AppSettingsTab: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var selectedApps: Set<String> = []
    @State private var searchText = ""
    @State private var showAddSheet = false

    var filteredApps: [AppInfo] {
        let apps = viewModel.appRulesListApps
        if searchText.isEmpty {
            return apps
        }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索应用", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))

            // 应用列表
            List(filteredApps, id: \.bundleId) { app in
                AppRuleRow(
                    app: app,
                    isSelected: selectedApps.contains(app.bundleId),
                    isConfigured: viewModel.getInputMethod(for: app) != nil,
                    onToggleSelection: {
                        toggleSelection(for: app)
                    },
                    onInputChange: { inputMethodId in
                        viewModel.setInputMethod(for: app, to: inputMethodId)
                    }
                )
            }
            .listStyle(.plain)

            Divider()

            // 底部工具栏
            VStack(spacing: 12) {
                // 全局默认输入法
                HStack {
                    Text("全局默认输入法:")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { viewModel.defaultInputMethod ?? "" },
                        set: { newValue in
                            viewModel.setDefaultInputMethod(newValue.isEmpty ? nil : newValue)
                        }
                    )) {
                        Text("---").tag("")
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
                    .frame(width: 180)
                }

                // 操作按钮
                HStack {
                    Button(action: { showAddSheet = true }) {
                        Label("添加应用", systemImage: "plus")
                    }

                    Spacer()

                    Button(action: deleteSelectedApps) {
                        Text("删除选中(\(selectedApps.count))")
                    }
                    .disabled(selectedApps.isEmpty)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .sheet(isPresented: $showAddSheet) {
            AddAppSheet()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Actions

    private func toggleSelection(for app: AppInfo) {
        if NSEvent.modifierFlags.contains(.command) {
            // Cmd + 点击：多选切换
            if selectedApps.contains(app.bundleId) {
                selectedApps.remove(app.bundleId)
            } else {
                selectedApps.insert(app.bundleId)
            }
        } else {
            // 普通点击：单选
            if selectedApps.contains(app.bundleId) && selectedApps.count == 1 {
                selectedApps.removeAll()
            } else {
                selectedApps = [app.bundleId]
            }
        }
    }

    private func deleteSelectedApps() {
        for bundleId in selectedApps {
            if let app = viewModel.installedApps.first(where: { $0.bundleId == bundleId }) {
                viewModel.setInputMethod(for: app, to: nil)
            }
        }
        selectedApps.removeAll()
    }
}

#Preview {
    AppSettingsTab()
        .environmentObject(InputMethodManager.shared)
        .frame(width: 550, height: 500)
}
```

- [ ] **Step 2: 编译验证**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug build 2>&1 | tail -5
```

---

## Task 5: 完整构建验证

- [ ] **Step 1: 清理并完整构建**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch && xcodebuild -project AutoKeySwitch.xcodeproj -scheme AutoKeySwitch -configuration Debug clean build 2>&1 | tail -10
```

- [ ] **Step 2: 运行应用进行手动测试**

测试项目：
1. 打开「应用规则」Tab，验证列表只显示已配置 + 运行中未配置的应用
2. 验证排序：已配置在前（按名称），运行中未配置在后（按名称）
3. 点击某行选中，验证高亮显示
4. Cmd + 点击多选，验证多选功能
5. 点击「删除选中」按钮，验证删除功能
6. 点击「添加应用」按钮，验证弹窗显示
7. 在弹窗中搜索应用，点击 [+] 添加
8. 切换某应用的输入法，验证列表实时更新

---

## Spec 覆盖检查

| Spec 要求 | 任务 |
|-----------|------|
| appRulesListApps 计算属性 | Task 1: InputMethodManager |
| AppRuleRow 组件 | Task 2: AppRuleRow |
| AddAppSheet 组件 | Task 3: AddAppSheet |
| 主界面重构 | Task 4: AppSettingsTab |
| 选择功能（单选/多选） | Task 4: AppSettingsTab |
| 删除功能 | Task 4: AppSettingsTab |
| 添加功能 | Task 3 + Task 4 |
| 搜索功能 | Task 4: AppSettingsTab |
