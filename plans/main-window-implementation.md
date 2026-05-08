# macOS SwiftUI 主界面实现方案

## 需求概述

创建一个 macOS SwiftUI 主界面窗口，包含两个 Tab：
1. **应用设置 Tab**：管理各应用的输入法配置
2. **偏好设置 Tab**：管理全局偏好设置

## 现有架构分析

### 核心组件
- `InputMethodManager` - 状态管理器（ObservableObject）
- `AppRowView` - 单个应用的输入法选择 UI
- `SettingsView` - 登录启动逻辑
- `Defaults[.appInputMethodSettings]` - 存储 [String: String?] 格式
- `AppListService.fetchInstalledApps()` - 获取已安装应用列表

### 关键发现
1. `InputMethodManager` 已包含 `inputMethods`、`installedApps`、`runningApps`
2. `AppRowView` 使用 Menu 组件实现输入法选择
3. `SettingsView` 已有登录启动逻辑
4. 当前 "默认" 选项表示不配置输入法，需要改为使用全局默认输入法

## 文件结构规划

### 新建文件
```
AutoSwitchInput/Sources/UI/Views/Main/
├── MainView.swift              # 主窗口视图（TabView）
├── AppSettingsTab.swift        # 应用设置 Tab
└── PreferencesTab.swift        # 偏好设置 Tab
```

### 修改文件
```
AutoSwitchInput/Sources/Core/Extensions/Defaults+Extensions.swift
AutoSwitchInput/Sources/Services/InputMethod/InputMethodManager.swift
AutoSwitchInput/Sources/App/AutoSwitchInputApp.swift
```

## 视图层次设计

```
MainView (TabView)
├── AppSettingsTab
│   ├── GlobalDefaultInputMethodSection
│   │   └── Menu (选择全局默认输入法)
│   └── ConfiguredAppsList
│       ├── List (已配置应用)
│       │   └── ForEach
│       │       ├── RemoveButton (-)
│       │       └── AppRowView (复用)
│       └── AddButton (+)
└── PreferencesTab
    └── LaunchAtLoginSection (复用 SettingsView 逻辑)
```

## 全局默认输入法存储方案

### 1. 存储层（Defaults+Extensions.swift）
```swift
extension Defaults.Keys {
    // 全局默认输入法 ID
    nonisolated static let defaultInputMethod = Key<String?>(
        "defaultInputMethod",
        default: nil,
        suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!
    )
}
```

### 2. 状态管理（InputMethodManager.swift）
```swift
@MainActor
final class InputMethodManager: ObservableObject {
    // 新增属性
    @Published var defaultInputMethod: String?

    // 新增方法
    func setDefaultInputMethod(_ inputMethodId: String?) {
        Defaults[.defaultInputMethod] = inputMethodId
        settingsVersion = UUID()
    }

    func getDefaultInputMethodName() -> String? {
        guard let inputMethodId = defaultInputMethod,
              !inputMethodId.isEmpty else {
            return nil
        }
        return inputMethods.first(where: { $0.id == inputMethodId })?.name
    }

    // 修改初始化方法
    private init() {
        defaultInputMethod = Defaults[.defaultInputMethod]
        Task { await refreshAllData() }
        setupSubscriptions()
    }
}
```

### 3. 语义变更
- 原 "默认" 选项：表示不配置输入法
- 新 "默认" 选项：表示使用全局默认输入法
- 应用激活时，优先使用应用配置，其次使用全局默认

## 应用添加/删除交互流程

### 添加应用流程
```
用户点击 "+" 按钮
    ↓
弹出应用选择列表（Menu 或 Sheet）
    ↓
显示所有已安装但未配置的应用
    ↓
用户选择应用
    ↓
调用 InputMethodManager.addAppToConfigured(_ app: AppInfo)
    ↓
应用添加到配置列表，默认使用全局默认输入法
    ↓
UI 自动更新
```

### 删除应用流程
```
用户点击应用行的 "-" 按钮
    ↓
调用 InputMethodManager.removeAppFromConfigured(_ app: AppInfo)
    ↓
从配置列表中移除该应用
    ↓
该应用恢复使用全局默认输入法
    ↓
UI 自动更新
```

### InputMethodManager 新增方法
```swift
/// 添加应用到配置列表
func addAppToConfigured(_ app: AppInfo) {
    // 使用全局默认输入法
    setInputMethod(for: app, to: defaultInputMethod)
}

/// 从配置列表移除应用
func removeAppFromConfigured(_ app: AppInfo) {
    setInputMethod(for: app, to: nil)
}

/// 获取未配置的应用列表
var unconfiguredApps: [AppInfo] {
    let settings = Defaults[.appInputMethodSettings]
    return installedApps.filter { app in
        settings[app.bundleId] == nil
    }
}
```

## 详细实现方案

### 1. AppSettingsTab.swift
```swift
import SwiftUI

struct AppSettingsTab: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var showingAddAppSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 全局默认输入法
            GlobalDefaultInputMethodSection()

            Divider()

            // 已配置应用列表
            ConfiguredAppsList(showingAddAppSheet: $showingAddAppSheet)
        }
        .padding()
        .sheet(isPresented: $showingAddAppSheet) {
            AddAppSheet()
        }
    }
}

struct GlobalDefaultInputMethodSection: View {
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("全局默认输入法")
                .font(.headline)

            Menu {
                // 不设置默认输入法选项
                Button(action: {
                    viewModel.setDefaultInputMethod(nil)
                }) {
                    if viewModel.defaultInputMethod == nil {
                        Image(systemName: "checkmark")
                    }
                    Text("不设置")
                }

                Divider()

                // 已安装的输入法选项
                ForEach(viewModel.inputMethods, id: \.id) { inputMethod in
                    Button(action: {
                        viewModel.setDefaultInputMethod(inputMethod.id)
                    }) {
                        if viewModel.defaultInputMethod == inputMethod.id {
                            Image(systemName: "checkmark")
                        }
                        Text(inputMethod.name)
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.getDefaultInputMethodName() ?? "不设置")
                    Spacer()
                    Image(systemName: "chevron.down")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
}

struct ConfiguredAppsList: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Binding var showingAddAppSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("已配置应用")
                    .font(.headline)

                Spacer()

                Button(action: {
                    showingAddAppSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }

            List {
                ForEach(viewModel.configuredApps) { app in
                    HStack {
                        // 删除按钮
                        Button(action: {
                            viewModel.removeAppFromConfigured(app)
                        }) {
                            Image(systemName: "minus")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)

                        // 复用 AppRowView
                        AppRowView(app: app)
                    }
                }
            }
            .frame(height: 300)
        }
    }
}

struct AddAppSheet: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("添加应用")
                .font(.headline)

            List {
                ForEach(viewModel.unconfiguredApps) { app in
                    Button(action: {
                        viewModel.addAppToConfigured(app)
                        dismiss()
                    }) {
                        HStack {
                            app.icon
                            Text(app.name)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 300)

            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400, height: 400)
    }
}
```

### 2. PreferencesTab.swift
```swift
import SwiftUI

struct PreferencesTab: View {
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 复用 SettingsView 的登录启动逻辑
            LaunchAtLoginSection()
        }
        .padding()
    }
}

struct LaunchAtLoginSection: View {
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("启动设置")
                .font(.headline)

            Toggle(
                AutoSwitchInputStrings.Settings.General.autoLaunch,
                isOn: Binding(
                    get: { LaunchAtLoginService.isEnabled },
                    set: { LaunchAtLoginService.isEnabled = $0 }
                )
            )
        }
    }
}
```

### 3. MainView.swift
```swift
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AppSettingsTab()
                .tabItem {
                    Label("应用设置", systemImage: "app.badge")
                }
                .tag(0)

            PreferencesTab()
                .tabItem {
                    Label("偏好设置", systemImage: "gearshape")
                }
                .tag(1)
        }
        .frame(width: 500, height: 600)
    }
}
```

### 4. AutoSwitchInputApp.swift 修改
```swift
import SwiftUI

@main
struct AutoSwitchInputApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 菜单栏场景
        MenuBarScene()

        // 主窗口场景
        Window("AutoSwitchInput", id: "mainWindow") {
            MainView()
                .environmentObject(InputMethodManager.shared)
        }
        .defaultSize(width: 500, height: 600)
    }
}
```

## 实现步骤

### Phase 1: 存储和状态管理
1. 修改 `Defaults+Extensions.swift`，添加 `defaultInputMethod` Key
2. 修改 `InputMethodManager.swift`，添加全局默认输入法相关属性和方法

### Phase 2: 应用设置 Tab
3. 创建 `AppSettingsTab.swift`，实现应用设置 Tab
4. 实现 `GlobalDefaultInputMethodSection` 组件
5. 实现 `ConfiguredAppsList` 组件
6. 实现 `AddAppSheet` 组件

### Phase 3: 偏好设置 Tab
7. 创建 `PreferencesTab.swift`，实现偏好设置 Tab
8. 实现 `LaunchAtLoginSection` 组件（复用 SettingsView 逻辑）

### Phase 4: 主窗口
9. 创建 `MainView.swift`，组合两个 Tab
10. 修改 `AutoSwitchInputApp.swift`，添加主窗口场景

## 需要修改的现有文件清单

1. `/Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoSwitchInput/AutoSwitchInput/Sources/Core/Extensions/Defaults+Extensions.swift`
   - 添加 `defaultInputMethod` Key

2. `/Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoSwitchInput/AutoSwitchInput/Sources/Services/InputMethod/InputMethodManager.swift`
   - 添加 `defaultInputMethod` 属性
   - 添加 `setDefaultInputMethod()` 方法
   - 添加 `getDefaultInputMethodName()` 方法
   - 添加 `addAppToConfigured()` 方法
   - 添加 `removeAppFromConfigured()` 方法
   - 添加 `unconfiguredApps` 计算属性
   - 修改 `init()` 方法初始化 `defaultInputMethod`

3. `/Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoSwitchInput/AutoSwitchInput/Sources/App/AutoSwitchInputApp.swift`
   - 添加主窗口 Scene

## 需要新建的文件清单

1. `/Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoSwitchInput/AutoSwitchInput/Sources/UI/Views/Main/MainView.swift`
2. `/Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoSwitchInput/AutoSwitchInput/Sources/UI/Views/Main/AppSettingsTab.swift`
3. `/Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoSwitchInput/AutoSwitchInput/Sources/UI/Views/Main/PreferencesTab.swift`

## 复用的现有组件

- `AppRowView` - 应用行视图
- `SettingsView` - 登录启动逻辑参考
- `InputMethodManager` - 状态管理
- `AppListService` - 应用列表获取
- `LaunchAtLoginService` - 登录启动服务

## 设计原则

1. **复用优先**：最大化复用现有组件，不重复造轮子
2. **简洁性**：保持代码简洁，避免过度设计
3. **一致性**：遵循现有代码风格和命名规范
4. **可维护性**：清晰的文件结构和职责分离
5. **用户体验**：符合 macOS HIG 规范

## 潜在挑战和解决方案

### 挑战 1：应用列表性能
- **问题**：已安装应用数量可能很大
- **解决**：使用 List 的懒加载特性，限制显示数量

### 挑战 2：状态同步
- **问题**：菜单栏和主窗口需要同步状态
- **解决**：使用 `InputMethodManager` 作为单一数据源，通过 `@Published` 自动同步

### 挑战 3：窗口管理
- **问题**：主窗口和菜单栏窗口的协调
- **解决**：使用 SwiftUI 的 Window API，每个窗口独立管理

## 测试要点

1. 全局默认输入法的设置和获取
2. 应用的添加和删除
3. 应用配置的持久化
4. UI 的响应式更新
5. 窗口的显示和隐藏
