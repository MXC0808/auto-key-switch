# 输入法记忆功能设计

## 背景

用户在应用间切换时，希望恢复离开该应用时的输入法状态，而非每次都切换到预设的输入法。

## 需求

1. 记录用户离开应用时的输入法状态（输入法 ID）
2. 仅对用户开启「记忆功能」的应用进行记录
3. 切换到应用时的优先级：上次状态 > 手动配置 > 全局默认

## 设计原则

### 分阶段实现

| 阶段 | 存储方式 | 生命周期 | 说明 |
|------|----------|----------|------|
| **第一阶段** | 内存存储 | 本次会话 | 验证核心需求，快速迭代 |
| **第二阶段** | 可选持久化 | 跨会话 | 用户可开启「跨会话记忆」选项 |

### 为什么先做内存存储

1. **核心价值是短期记忆**：用户在应用间频繁切换时保持状态，而非跨天记忆
2. **避免长期状态过时**：一周前的输入法状态可能不符合当前需求
3. **业界主流做法**：macOS/Windows 自带输入法切换不记录历史
4. **降低实现复杂度**：无需数据迁移、清理策略，先验证需求再迭代

---

## 第一阶段：内存存储

### 数据模型

```swift
// InputMethodManager.swift
@MainActor
final class InputMethodManager: ObservableObject {
    // 现有属性...

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
}
```

### Defaults 新增 Key

```swift
// Defaults+Extensions.swift
extension Defaults.Keys {
    /// 记忆功能开关列表（持久化）
    nonisolated static let memoryEnabledApps = Key<Set<String>>(
        "memoryEnabledApps",
        default: [],
        suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!
    )
}
```

### 核心逻辑

#### 1. 初始化当前活跃应用

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

#### 2. 追踪正在离开的应用

```swift
// 在 handleAppActivation 开始时调用
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

#### 3. 切换逻辑（修改现有 handleAppActivation）

```swift
private func handleAppActivation(_ notification: Notification) async {
    // 1. 先记录正在离开的应用的状态
    await recordPreviousAppState()

    // 2. 获取当前激活的应用
    guard let userInfo = notification.userInfo,
          let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
          let bundleId = app.bundleIdentifier else {
        return
    }

    // 3. 确定目标输入法（优先级：上次状态 > 手动配置 > 全局默认）
    let targetInputMethodId = determineTargetInputMethod(for: bundleId)

    // 4. 执行切换
    if let targetId = targetInputMethodId {
        try? InputMethodService.switchToInputMethod(targetId)
    }

    // 5. 更新当前活跃应用追踪（为下次切换准备）
    currentActiveAppBundleId = bundleId
}

/// 确定目标输入法
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

### UI 变更

每个应用增加「记住上次输入法」开关，并显示提示信息：

```swift
// AppRowView.swift 或类似文件
VStack(alignment: .leading) {
    Toggle("记住上次输入法", isOn: Binding(
        get: { viewModel.isMemoryEnabled(for: app) },
        set: { viewModel.setMemoryEnabled(for: app, enabled: $0) }
    ))

    // 显示当前记忆状态
    if viewModel.isMemoryEnabled(for: app),
       let lastMethod = viewModel.getLastInputMethod(for: app),
       let methodName = viewModel.inputMethods.first(where: { $0.id == lastMethod })?.name {
        Text("上次使用：\(methodName)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// 开启时的提示
// "开启后，切回此应用时将恢复上次使用的输入法，而非配置的输入法"
```

### 辅助方法

```swift
// InputMethodManager.swift

/// 检查应用是否启用记忆
func isMemoryEnabled(for app: AppInfo) -> Bool {
    return memoryEnabledApps.contains(app.bundleId)
}

/// 设置应用记忆开关
func setMemoryEnabled(for app: AppInfo, enabled: Bool) {
    if enabled {
        guard memoryEnabledApps.count < Constants.maxMemoryEnabledApps else {
            // 提示用户已达上限
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

/// 获取应用的上次输入法
func getLastInputMethod(for app: AppInfo) -> String? {
    return lastInputMethodStates[app.bundleId]
}

/// 清除所有记忆数据（不清除开关状态）
func clearAllMemoryStates() {
    lastInputMethodStates.removeAll()
}
```

---

## 第二阶段：可选持久化（预留）

### 设计思路

当用户开启「跨会话记忆」选项时，将内存数据持久化到 UserDefaults：

```swift
// Defaults+Extensions.swift（第二阶段添加）
extension Defaults.Keys {
    /// 是否启用跨会话记忆
    nonisolated static let crossSessionMemory = Key<Bool>(
        "crossSessionMemory",
        default: false,
        suite: ...
    )

    /// 持久化的输入法状态（仅当 crossSessionMemory 为 true 时使用）
    nonisolated static let persistedInputMethodStates = Key<[String: String]>(
        "persistedInputMethodStates",
        default: [:],
        suite: ...
    )
}
```

### 同步逻辑（第二阶段）

```swift
// 应用退出或进入后台时
func syncToPersistence() {
    guard Defaults[.crossSessionMemory] else { return }
    Defaults[.persistedInputMethodStates] = lastInputMethodStates
}

// 应用启动时
func loadFromPersistence() {
    guard Defaults[.crossSessionMemory] else { return }
    lastInputMethodStates = Defaults[.persistedInputMethodStates]
}
```

---

## 应用数量限制

```swift
enum Constants {
    static let maxMemoryEnabledApps = 20
}

func setMemoryEnabled(for app: AppInfo, enabled: Bool) {
    if enabled {
        guard memoryEnabledApps.count < Constants.maxMemoryEnabledApps else {
            // 提示用户已达上限
            return
        }
        memoryEnabledApps.insert(app.bundleId)
    } else {
        memoryEnabledApps.remove(app.bundleId)
        lastInputMethodStates.removeValue(forKey: app.bundleId)
    }
}
```

---

## 文件变更清单（第一阶段）

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `Core/Extensions/Defaults+Extensions.swift` | 修改 | 新增 `memoryEnabledApps` Key |
| `Services/InputMethod/InputMethodManager.swift` | 修改 | 新增内存存储属性和核心逻辑 |
| `UI/Views/MenuBar/AppRowView.swift` | 修改 | 新增「记住上次输入法」开关和状态显示 |

---

## 验证方案

### 手动测试用例

1. **基本功能**
   - 应用 A 启用记忆，切换输入法，切到应用 B，再切回 A
   - 验证输入法状态恢复

2. **禁用记忆**
   - 应用 A 禁用记忆，切换输入法，切到应用 B，再切回 A
   - 验证使用手动配置或全局默认

3. **优先级验证**
   - 应用 A 同时有手动配置和记忆状态
   - 验证记忆状态优先于手动配置

4. **数量限制**
   - 启用 20 个应用的记忆
   - 尝试启用第 21 个，验证提示已达上限

5. **会话生命周期**
   - 启用记忆，切换输入法，退出应用
   - 重新打开应用，验证记忆数据已清除

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 首次切换状态丢失 | 第一个应用的状态不被记录 | init() 中初始化 currentActiveAppBundleId |
| 应用快速切换 | 状态记录不完整 | 使用 debounce 防抖处理（现有 300ms） |
| 内存占用 | 应用过多时内存增加 | 限制最多 20 个应用启用记忆 |
| 用户困惑 | 不理解优先级逻辑 | UI 提示：「上次状态优先于配置」 |
| 同一应用多窗口 | 可能误触发记录 | 测试验证 didActivateApplicationNotification 行为 |
| 时序竞争 | 输入法切换和应用切换竞争 | 增加监听输入法切换事件缓存值 |

## 已知限制

1. **中英文状态**：暂不实现，macOS TIS API 不直接支持，需后续研究第三方输入法适配方案
   - **参考项目验证**：[InputSourcePro](https://github.com/runjuu/InputSourcePro) 作为成熟的开源项目，也只记录输入法 ID，未实现中英文状态记录
   - 这验证了我们的设计决策是合理的
2. **同一应用多窗口**：需测试验证是否触发 didActivateApplicationNotification

---

## 参考资料

### InputSourcePro 项目分析

[InputSourcePro](https://github.com/runjuu/InputSourcePro) 是一个成熟的 macOS 输入法自动切换工具，我们的设计可借鉴其实现：

**核心架构**：
| 模块 | 实现 | 说明 |
|------|------|------|
| `AppKeyboardCache` | 内存缓存 `[String: String]` | 存储应用上次使用的输入法 ID |
| `KeyboardRestoreStrategy` | 枚举策略 | 用户可选恢复或不恢复 |
| `InputSourceSwitcher` | 切换器 | 处理 CJKV 输入法特殊逻辑 |

**优先级逻辑**（与我们一致）：
```
缓存输入法 > 应用配置输入法 > 系统默认输入法
```

**关键发现**：
- ✅ 使用纯内存缓存（`AppKeyboardCache`），不持久化状态
- ✅ 缓存仅存储 `inputSourceId`，**不存储中英文状态**
- ✅ 用户可选择恢复策略（全局 + 按应用）
- ✅ 提供 `inputModeID` 属性，用于某些输入法的模式区分

**可借鉴的 TISInputSource 扩展**：
```swift
extension TISInputSource {
    var id: String { getProperty(kTISPropertyInputSourceID) as! String }
    var inputModeID: String? { getProperty(kTISPropertyInputModeID) as? String }
    var sourceLanguages: [String] { getProperty(kTISPropertyInputSourceLanguages) as? [String] ?? [] }
}
```

---

## 后续迭代方向

1. **第二阶段**：增加「跨会话记忆」选项
2. **过期策略**：持久化数据可设置 7 天过期
3. **中英文状态**：针对主流输入法适配中英文状态获取
