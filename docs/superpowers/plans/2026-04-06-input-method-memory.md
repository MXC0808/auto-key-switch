# 输入法记忆功能实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现应用间切换时恢复上次使用的输入法状态（仅记录输入法 ID，不记录中英文状态）

**Architecture:** 使用内存缓存存储上次输入法状态，开关状态持久化到 UserDefaults。切换优先级：上次状态 > 手动配置 > 全局默认

**Tech Stack:** Swift 5.9, SwiftUI, Defaults 库, Carbon TIS API

---

## 文件结构

| 文件 | 变更类型 | 职责 |
|------|----------|------|
| `Core/Extensions/Defaults+Extensions.swift` | 修改 | 新增 `memoryEnabledApps` Key |
| `Services/InputMethod/InputMethodManager.swift` | 修改 | 新增内存存储属性、核心切换逻辑、辅助方法 |
| `UI/Views/MenuBar/AppRowView.swift` | 修改 | 新增「记住上次输入法」开关 |

---

## Task 1: 新增 Defaults Key

**Files:**
- Modify: `AutoKeySwitch/Sources/Core/Extensions/Defaults+Extensions.swift`

- [ ] **Step 1: 打开 Defaults+Extensions.swift 并添加新的 Key**

在现有 `defaultInputMethod` Key 下方添加：

```swift
/// 记忆功能开关列表（持久化）
/// 存储格式: Set<String>，包含所有启用记忆功能的应用 bundleId
nonisolated static let memoryEnabledApps = Key<Set<String>>(
    "memoryEnabledApps",
    default: [],
    suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!
)
```

完整的 `Defaults+Extensions.swift` 应该是：

```swift
@preconcurrency import Defaults
import Foundation

/// Defaults 扩展,统一管理所有应用设置 Keys
extension Defaults.Keys {
    /// 应用输入法设置存储 Key
    /// 存储格式: `[String: String?]`,其中 String 是应用的 bundleId,String? 是输入法 ID (nil 表示不配置)
    nonisolated static let appInputMethodSettings = Key<[String: String?]>("appInputMethodSettings", default: [:], suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!)

    /// Global default input method
    nonisolated static let defaultInputMethod = Key<String?>("defaultInputMethod", default: nil, suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!)

    /// 记忆功能开关列表（持久化）
    /// 存储格式: Set<String>，包含所有启用记忆功能的应用 bundleId
    nonisolated static let memoryEnabledApps = Key<Set<String>>(
        "memoryEnabledApps",
        default: [],
        suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!
    )
}
```

- [ ] **Step 2: 验证编译通过**

```bash
cd /Users/maoxiaochuang/IdeaProjects/auto-switch-input/AutoKeySwitch
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交变更**

```bash
git add AutoKeySwitch/Sources/Core/Extensions/Defaults+Extensions.swift
git commit -m "feat: add memoryEnabledApps Defaults Key for input method memory feature"
```

---

## Task 2: 添加内存存储属性和常量

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 在 InputMethodManager 类顶部添加常量枚举**

在文件开头（import 语句后）添加：

```swift
// MARK: - Constants
enum Constants {
    /// 最多允许启用记忆功能的应用数量
    static let maxMemoryEnabledApps = 20
}
```

- [ ] **Step 2: 在 InputMethodManager 类中添加内存存储属性**

在现有属性 `defaultInputMethod` 下方添加：

```swift
// MARK: - Memory Feature Properties

/// 记忆功能开关（按应用）- 持久化
/// 开关状态需要持久化，否则用户每次启动都要重新配置
@Published private(set) var memoryEnabledApps: Set<String> = Defaults[.memoryEnabledApps]

/// 上次输入法状态（内存存储）- 本次会话有效
/// Key: 应用 bundleId
/// Value: 输入法 ID
@Published private(set) var lastInputMethodStates: [String: String] = [:]

/// 当前活跃应用的 bundleId（用于追踪「正在离开的应用」）
/// 在 handleAppActivation 开始时代表「正在离开的应用」
/// 在 handleAppActivation 结束时更新为「新激活的应用」
private var currentActiveAppBundleId: String?
```

- [ ] **Step 3: 验证编译通过**

```bash
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: 提交变更**

```bash
git add AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift
git commit -m "feat: add memory storage properties to InputMethodManager"
```

---

## Task 3: 初始化当前活跃应用

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 修改 init() 方法，初始化 currentActiveAppBundleId**

找到现有的 `private init()` 方法，修改为：

```swift
private init() {
    Task {
        await refreshAllData()
        // 初始化当前活跃应用，确保首次切换时能正确记录
        currentActiveAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
    setupSubscriptions()
}
```

- [ ] **Step 2: 验证编译通过**

```bash
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交变更**

```bash
git add AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift
git commit -m "feat: initialize currentActiveAppBundleId in InputMethodManager init"
```

---

## Task 4: 添加记录上一个应用状态的方法

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 在 Private Methods 区域添加 recordPreviousAppState 方法**

在 `handleAppActivation` 方法之前添加：

```swift
/// 记录正在离开的应用的输入法状态
private func recordPreviousAppState() async {
    // currentActiveAppBundleId 在此时代表「正在离开的应用」
    guard let leavingAppId = currentActiveAppBundleId,
          memoryEnabledApps.contains(leavingAppId) else {
        return
    }

    // 记录当前输入法状态到正在离开的应用
    if let currentInputMethod = try? InputMethodService.getCurrentInputMethodId() {
        lastInputMethodStates[leavingAppId] = currentInputMethod
    }
}
```

- [ ] **Step 2: 验证编译通过**

```bash
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交变更**

```bash
git add AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift
git commit -m "feat: add recordPreviousAppState method for tracking leaving app state"
```

---

## Task 5: 添加确定目标输入法的方法

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 在 Private Methods 区域添加 determineTargetInputMethod 方法**

在 `recordPreviousAppState` 方法之后添加：

```swift
/// 确定目标输入法（优先级：上次状态 > 手动配置 > 全局默认）
/// - Parameter bundleId: 应用 bundleId
/// - Returns: 目标输入法 ID
private func determineTargetInputMethod(for bundleId: String) -> String? {
    // 优先级 1：上次状态（仅当启用记忆时）
    if memoryEnabledApps.contains(bundleId),
       let lastState = lastInputMethodStates[bundleId] {
        return lastState
    }

    // 优先级 2：手动配置
    if let manualConfig = getInputMethod(for: bundleId) {
        return manualConfig
    }

    // 优先级 3：全局默认
    return defaultInputMethod
}
```

- [ ] **Step 2: 验证编译通过**

```bash
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交变更**

```bash
git add AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift
git commit -m "feat: add determineTargetInputMethod method with priority logic"
```

---

## Task 6: 修改 handleAppActivation 方法

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 替换现有的 handleAppActivation 方法**

将现有的 `handleAppActivation` 方法替换为：

```swift
/// 处理应用激活事件
private func handleAppActivation(_ notification: Notification) async {
    // 1. 先记录正在离开的应用的状态
    await recordPreviousAppState()

    // 2. 获取当前激活的应用
    guard let userInfo = notification.userInfo,
          let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
          let bundleId = app.bundleIdentifier else {
        return
    }

    // 3. 查找对应的应用信息（用于手动配置）
    guard let appInfo = installedApps.first(where: { $0.bundleId == bundleId }) else {
        // 不在已安装应用列表中，更新追踪并返回
        currentActiveAppBundleId = bundleId
        return
    }

    // 4. 确定目标输入法（优先级：上次状态 > 手动配置 > 全局默认）
    let targetInputMethodId = determineTargetInputMethod(for: bundleId)

    // 5. 执行切换
    if let targetId = targetInputMethodId {
        do {
            try InputMethodService.switchToInputMethod(targetId)
        } catch {
            print("❌ 切换到输入法失败: \(error.localizedDescription)")
        }
    }

    // 6. 更新当前活跃应用追踪（为下次切换准备）
    currentActiveAppBundleId = bundleId
}
```

- [ ] **Step 2: 验证编译通过**

```bash
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交变更**

```bash
git add AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift
git commit -m "feat: modify handleAppActivation to support memory feature with priority logic"
```

---

## Task 7: 添加辅助方法

**Files:**
- Modify: `AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift`

- [ ] **Step 1: 在 Public Methods 区域添加记忆功能辅助方法**

在 `removeAppFromConfigured` 方法之后添加：

```swift
// MARK: - Memory Feature Methods

/// 检查应用是否启用记忆功能
/// - Parameter app: 应用信息
/// - Returns: 是否启用记忆
func isMemoryEnabled(for app: AppInfo) -> Bool {
    return memoryEnabledApps.contains(app.bundleId)
}

/// 设置应用记忆开关
/// - Parameters:
///   - app: 应用信息
///   - enabled: 是否启用
func setMemoryEnabled(for app: AppInfo, enabled: Bool) {
    if enabled {
        guard memoryEnabledApps.count < Constants.maxMemoryEnabledApps else {
            // 已达上限，不执行操作
            // UI 层应该显示提示，这里静默返回
            return
        }
        memoryEnabledApps.insert(app.bundleId)
    } else {
        memoryEnabledApps.remove(app.bundleId)
        // 清除该应用的记忆数据
        lastInputMethodStates.removeValue(forKey: app.bundleId)
    }
    // 持久化开关状态
    Defaults[.memoryEnabledApps] = memoryEnabledApps
}

/// 获取应用的上次输入法 ID
/// - Parameter app: 应用信息
/// - Returns: 上次使用的输入法 ID，如果没有则返回 nil
func getLastInputMethod(for app: AppInfo) -> String? {
    return lastInputMethodStates[app.bundleId]
}

/// 清除所有记忆数据（不清除开关状态）
func clearAllMemoryStates() {
    lastInputMethodStates.removeAll()
}

/// 获取已启用记忆功能的应用数量
/// - Returns: 应用数量
func getMemoryEnabledCount() -> Int {
    return memoryEnabledApps.count
}
```

- [ ] **Step 2: 验证编译通过**

```bash
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交变更**

```bash
git add AutoKeySwitch/Sources/Services/InputMethod/InputMethodManager.swift
git commit -m "feat: add helper methods for memory feature (isMemoryEnabled, setMemoryEnabled, etc.)"
```

---

## Task 8: 修改 AppRowView 添加记忆开关

**Files:**
- Modify: `AutoKeySwitch/Sources/UI/Views/MenuBar/AppRowView.swift`

- [ ] **Step 1: 替换 AppRowView 的完整实现**

将 `AppRowView.swift` 替换为：

```swift
import SwiftUI

/// 应用行视图，处理单个应用的显示、输入法选择和记忆开关
struct AppRowView: View {
    let app: AppInfo
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 应用名称行
            HStack {
                app.icon
                Text(app.name)
                    .lineLimit(1)

                Spacer()

                // 显示当前配置的输入法
                if let name = viewModel.getSelectedInputMethodName(for: app) {
                    Text(name)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            // 记忆开关行
            HStack {
                Toggle("记住上次输入法", isOn: Binding(
                    get: { viewModel.isMemoryEnabled(for: app) },
                    set: { enabled in
                        if enabled && viewModel.getMemoryEnabledCount() >= Constants.maxMemoryEnabledApps {
                            // 已达上限，显示提示（这里简化处理，实际应用可能需要 Alert）
                            return
                        }
                        viewModel.setMemoryEnabled(for: app, enabled: enabled)
                    }
                ))
                .font(.caption)
                .controlSize(.small)

                Spacer()

                // 显示上次使用的输入法
                if viewModel.isMemoryEnabled(for: app),
                   let lastMethod = viewModel.getLastInputMethod(for: app),
                   let methodName = viewModel.inputMethods.first(where: { $0.id == lastMethod })?.name {
                    Text("上次: \(methodName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .contextMenu {
            // 默认输入法选项
            Button(action: {
                viewModel.setInputMethod(for: app, to: nil)
            }) {
                if viewModel.getInputMethod(for: app) == nil {
                    Image(systemName: "checkmark")
                }
                Text(AutoKeySwitchStrings.InputMethod.defaultOption)
            }

            Divider()

            // 已安装的输入法选项
            ForEach(viewModel.inputMethods, id: \.id) { inputMethod in
                Button(action: {
                    viewModel.setInputMethod(for: app, to: inputMethod.id)
                }) {
                    if viewModel.getInputMethod(for: app) == inputMethod.id {
                        Image(systemName: "checkmark")
                    }
                    Text(inputMethod.name)
                }
            }

            Divider()

            // 记忆开关
            Button(action: {
                let isEnabled = viewModel.isMemoryEnabled(for: app)
                if !isEnabled && viewModel.getMemoryEnabledCount() >= Constants.maxMemoryEnabledApps {
                    return
                }
                viewModel.setMemoryEnabled(for: app, enabled: !isEnabled)
            }) {
                if viewModel.isMemoryEnabled(for: app) {
                    Image(systemName: "checkmark")
                }
                Text("记住上次输入法")
            }
        }
    }
}
```

- [ ] **Step 2: 验证编译通过**

```bash
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: 提交变更**

```bash
git add AutoKeySwitch/Sources/UI/Views/MenuBar/AppRowView.swift
git commit -m "feat: add memory toggle to AppRowView with last input method display"
```

---

## Task 9: 手动测试验证

- [ ] **Step 1: 构建并运行应用**

```bash
open -a Xcode AutoKeySwitch.xcodeproj
# 或通过命令行构建
xcodebuild -scheme AutoKeySwitch -configuration Debug build
```

- [ ] **Step 2: 测试基本功能**

1. 打开应用，选择一个应用（如 VS Code）
2. 右键点击应用，勾选「记住上次输入法」
3. 切换输入法到非默认的输入法
4. 切换到另一个应用
5. 切回 VS Code
6. 验证：输入法恢复到上次使用的输入法

- [ ] **Step 3: 测试禁用记忆**

1. 取消勾选 VS Code 的「记住上次输入法」
2. 切换输入法
3. 切到其他应用再切回
4. 验证：输入法使用手动配置或全局默认

- [ ] **Step 4: 测试优先级**

1. 为 VS Code 设置手动配置的输入法
2. 启用记忆功能
3. 切换到另一个输入法
4. 切到其他应用再切回
5. 验证：使用上次状态的输入法（优先级高于手动配置）

- [ ] **Step 5: 测试数量限制**

1. 尝试启用超过 20 个应用的记忆功能
2. 验证：第 21 个无法启用（静默失败）

- [ ] **Step 6: 测试会话生命周期**

1. 启用某应用的记忆
2. 切换输入法
3. 完全退出应用（Command+Q）
4. 重新打开应用
5. 验证：开关状态保留，但上次输入法数据已清空

---

## Task 10: 最终提交

- [ ] **Step 1: 确认所有变更已提交**

```bash
git status
git log --oneline -10
```

- [ ] **Step 2: 如果有未提交的变更，提交它们**

```bash
git add -A
git commit -m "feat: complete input method memory feature implementation"
```

---

## 实现完成检查清单

- [ ] `memoryEnabledApps` Defaults Key 已添加
- [ ] `Constants.maxMemoryEnabledApps` 常量已定义
- [ ] 内存存储属性已添加到 InputMethodManager
- [ ] `currentActiveAppBundleId` 在 init 中正确初始化
- [ ] `recordPreviousAppState` 方法正确记录离开应用的状态
- [ ] `determineTargetInputMethod` 方法正确实现优先级逻辑
- [ ] `handleAppActivation` 方法已修改支持记忆功能
- [ ] 辅助方法 `isMemoryEnabled`, `setMemoryEnabled`, `getLastInputMethod` 已添加
- [ ] AppRowView UI 已添加记忆开关
- [ ] 手动测试验证通过

---

## 已知限制

1. 中英文状态不记录（macOS API 限制）
2. 同一应用多窗口切换行为需实际测试验证
3. 第 21 个应用启用记忆时静默失败（UI 层可后续添加 Alert 提示）
