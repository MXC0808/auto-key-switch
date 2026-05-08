# 强制英文符号功能 - 测试集设计

## Context

强制英文符号功能已实现完毕（包含 KeyboardLayoutMapper、PunctuationService、PermissionService、UI 联动等模块），但项目当前没有任何测试。需要构建完整的测试集来验证功能正确性和回归防护。

**用户选择**：
- 测试范围：单元测试 + 集成测试 + E2E 手动测试
- 测试框架：Swift Testing（`@Test` + `#expect`）
- 组织方式：集成到 Tuist 项目
- Mock 策略：Protocol 抽象 + Mock 实现
- 键位测试数据：硬编码基准 + 动态系统布局验证
- E2E 执行方式：AppleScript 自动化 + 手动测试清单

---

## 整体架构

### 目录结构
```
AutoKeySwitchTests/
├── UnitTests/
│   ├── KeyboardLayoutMapperTests.swift
│   ├── PunctuationServiceLogicTests.swift
├── IntegrationTests/
│   └── PunctuationServiceIntegrationTests.swift
├── Mocks/
│   ├── MockPermissionProvider.swift
│   ├── MockInputSourceProvider.swift
│   └── MockKeyboardLayoutProvider.swift
├── TestHelpers/
│   └── InputMethodTestHelpers.swift
└── E2E/
    ├── punctuation_basic_test.scpt
    ├── shift_number_test.scpt
    ├── run_e2e_tests.sh
    └── ManualTestChecklist.md
```

### Tuist 配置变更

在 `Project.swift` 的 `targets` 数组中新增：

```swift
.target(
    name: "AutoKeySwitchTests",
    destinations: .macOS,
    product: .unitTests,
    bundleId: "top.ygsgdbd.AutoKeySwitchTests",
    sources: ["AutoKeySwitchTests/**"],
    dependencies: [
        .target(name: "AutoKeySwitch"),
        .package(product: "Defaults")
    ]
)
```

---

## 生产代码重构（测试前置条件）

### 重构 1: Protocol 抽象

#### PermissionProviding

```swift
protocol PermissionProviding: Sendable {
    func checkAccessibility() -> Bool
    func requestAccessibility() -> Bool
}

struct SystemPermissionProvider: PermissionProviding {
    func checkAccessibility() -> Bool { AXIsProcessTrusted() }
    func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
```

#### InputSourceProviding

```swift
/// Must be safe to call from nonisolated context (CGEvent callback)
protocol InputSourceProviding: Sendable {
    func currentLanguages() -> [String]?
    func isCJKV() -> Bool
}

struct SystemInputSourceProvider: InputSourceProviding {
    func currentLanguages() -> [String]? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let langPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return nil }
        return Unmanaged<CFArray>.fromOpaque(langPtr).takeUnretainedValue() as? [String]
    }

    func isCJKV() -> Bool {
        guard let lang = currentLanguages()?.first else { return false }
        return lang.hasPrefix("zh") || lang == "ja" || lang == "ko" || lang == "vi"
    }
}
```

#### KeyboardLayoutProviding

```swift
/// Must be safe to call from nonisolated context (CGEvent callback)
protocol KeyboardLayoutProviding: Sendable {
    func getMappings() -> [UInt16: KeyMapping]
    func getMapping(forKeyCode keyCode: UInt16) -> KeyMapping?
    func rebuildMappings() -> Void
}

/// Wraps KeyboardLayoutMapper static calls for protocol-based injection
struct SystemKeyboardLayoutProvider: KeyboardLayoutProviding {
    func getMappings() -> [UInt16: KeyMapping] {
        KeyboardLayoutMapper.getMappings()
    }
    func getMapping(forKeyCode keyCode: UInt16) -> KeyMapping? {
        KeyboardLayoutMapper.getMapping(forKeyCode: keyCode)
    }
    func rebuildMappings() {
        KeyboardLayoutMapper.rebuildMappings()
    }
}
```

### 重构 2: PunctuationService 依赖注入

**关键约束**：CGEvent 回调中访问的属性必须是 `nonisolated(unsafe)` 或线程安全的。

```swift
@MainActor
class PunctuationService: ObservableObject {
    private nonisolated(unsafe) var isEnabled = false
    private var eventTap: CFMachPort?

    // 注入的依赖 — nonisolated(unsafe) 以支持 CGEvent 回调访问
    private nonisolated(unsafe) let permissionProvider: PermissionProviding
    private nonisolated(unsafe) let inputSourceProvider: InputSourceProviding
    private nonisolated(unsafe) let keyboardLayoutProvider: KeyboardLayoutProviding

    init(
        permissionProvider: PermissionProviding = SystemPermissionProvider(),
        inputSourceProvider: InputSourceProviding = SystemInputSourceProvider(),
        keyboardLayoutProvider: KeyboardLayoutProviding = SystemKeyboardLayoutProvider()
    ) {
        self.permissionProvider = permissionProvider
        self.inputSourceProvider = inputSourceProvider
        self.keyboardLayoutProvider = keyboardLayoutProvider
    }

    // enable() 中改用 permissionProvider.checkAccessibility()
    // isCJKVInputMethod() 改用 inputSourceProvider.isCJKV()
    // handleKeyEvent() 中改用 keyboardLayoutProvider.getMapping(forKeyCode:)
}
```

### 重构 3: handleKeyEvent 可访问性

将 `handleKeyEvent` 从 `private` 改为 `internal`，以便测试中通过 `@testable import` 直接调用：

```swift
// Before: private func handleKeyEvent(...)
// After:  internal func handleKeyEvent(...)
```

### 重构 4: KeyboardLayoutMapper.fallbackMappings 暴露

将 `buildFallbackMappings()` 中的数据作为公开属性暴露，避免测试数据与生产代码重复：

```swift
@MainActor
enum KeyboardLayoutMapper {
    /// Fallback mappings for US keyboard layout (used in tests)
    static let fallbackMappings: [UInt16: KeyMapping] = [
        43: KeyMapping(normal: ",", shifted: "<"),
        // ... 其余 17 个映射
    ]

    private static func buildFallbackMappings() {
        cachedMappings = fallbackMappings
    }
}
```

### 重构 5: InputMethodManager 适配

`InputMethodManager.init()` 中创建 `PunctuationService` 时无需改动（使用默认参数）：

```swift
private init() {
    punctuationService = PunctuationService()  // 默认使用 System*Provider
    // ...
}
```

---

## 第一层：单元测试

### 1.1 KeyboardLayoutMapper 测试

**文件**: `UnitTests/KeyboardLayoutMapperTests.swift`

| ID | 名称 | 验证内容 |
|----|------|----------|
| ULM-001 | testFallbackMappingsComplete | 验证 `fallbackMappings` 包含 18 个键且 normal/shifted 均非空 |
| ULM-002 | testFallbackMappingsCorrectness | 参数化测试：逐个验证 fallback 映射值（引用 `KeyboardLayoutMapper.fallbackMappings`） |
| ULM-003 | testShiftedValuesAreSymbols | 验证数字键(20-29)的 shifted 值不含数字 |
| ULM-004 | testAllPunctuationKeysMapped | 验证 `getMappings()` 返回所有 punctuationKeyCodes 的映射 |
| ULM-005 | testNonPunctuationKeyReturnsNil | 验证非标点键（如字母键 keyCode=0）返回 nil |
| ULM-006 | testRebuildMappingsPreservesCount | 验证 `rebuildMappings()` 后映射数量不变 |

**注意**：ULM-004 和 ULM-006 调用 `getMappings()` 会触发动态布局读取，在 US 布局机器上返回与 fallback 一致的结果。测试中需记录当前布局环境。

### 1.2 PunctuationService 逻辑测试（使用 Mock）

**文件**: `UnitTests/PunctuationServiceLogicTests.swift`

| ID | 名称 | 验证内容 |
|----|------|----------|
| PSL-001 | testEnableFailsWhenPermissionDenied | Mock `checkAccessibility()` 返回 false → `enable()` 返回 false |
| PSL-002 | testEnableSucceedsWhenPermissionGranted | Mock `checkAccessibility()` 返回 true → `enable()` 返回 true（需 Accessibility 权限） |
| PSL-003 | testDisableWhenNotEnabledIsNoop | 未 enable 时调用 `disable()` 不崩溃 |
| PSL-004 | testIsCJKVWithMockChinese | Mock 中文语言 → `isCJKV()` 返回 true |
| PSL-005 | testIsCJKVWithMockEnglish | Mock 英文语言 → `isCJKV()` 返回 false |
| PSL-006 | testIsCJKVWithNoInputSource | Mock 无输入源 → `isCJKV()` 返回 false |
| PSL-007 | testHandleKeyEventReplacesPunctuation | Mock 中文 + 有映射 → 返回替换事件 |
| PSL-008 | testHandleKeyEventSkipsEnglishInput | Mock 英文 → 返回原始事件 |
| PSL-009 | testHandleKeyEventSkipsNonPunctuation | Mock 中文 + 无映射键 → 返回原始事件 |

**注意**：PSL-007~009 直接调用 `handleKeyEvent`（需重构为 internal），构造模拟 CGEvent 进行测试。

---

## 第二层：集成测试

**文件**: `IntegrationTests/PunctuationServiceIntegrationTests.swift`

| ID | 名称 | 验证内容 |
|----|------|----------|
| INT-001 | testFullEnableDisableCycle | 完整 enable → disable → 验证 isEnabled 状态 |
| INT-002 | testEnableCreatesEventTap | Mock 权限 true 时 enable → eventTap 非空 |
| INT-003 | testDisableInvalidatesEventTap | enable 后 disable → eventTap 被清理 |
| INT-004 | testDoubleEnableIsIdempotent | 连续两次 enable → 只创建一个 eventTap |
| INT-005 | testKeyboardLayoutMapperConsistency | 动态映射与 fallback 映射在 US 布局下一致 |

**注意**：INT-002~003 需暴露 `eventTap` 属性或添加 `var isMonitoring: Bool` 计算属性用于测试断言。

---

## 第三层：E2E 测试

### 3.1 AppleScript 自动化

**文件**: `E2E/punctuation_basic_test.scpt`
- 切换到中文输入法
- 打开 TextEdit
- 模拟输入标点键
- 读取文档内容验证输出

**文件**: `E2E/shift_number_test.scpt`
- 切换到中文输入法
- 模拟 Shift+1 到 Shift+0
- 验证输出为 `!@#$%^&*()`

**文件**: `E2E/run_e2e_tests.sh`
- 检查前置条件
- 依次执行 AppleScript 测试
- 输出测试结果

### 3.2 手动测试清单

**文件**: `E2E/ManualTestChecklist.md`

| 用例ID | 场景 | 验证点 |
|--------|------|--------|
| TC-001 | 基本标点转换 | 中文输入法下逗号/句号/分号/引号输出英文 |
| TC-002 | Shift 组合符号 | Shift+1~0 输出 `!@#$%^&*()` |
| TC-003 | 括号类符号 | `[]` 和 Shift+`[]` 输出 `[]{}` |
| TC-004 | 应用切换联动 | 切换到已配置/未配置应用时功能生效/不生效 |
| TC-005 | 全局开关联动 | 关闭总开关后应用规则勾选框置灰、功能不生效 |
| TC-006 | 边界条件 | 无权限时提示、多修饰键、快速连续按键 |
| TC-007 | 不同输入法 | 搜狗拼音、系统拼音、日语、英语输入法 |
| TC-008 | 反引号和反斜杠 | `` ` `` 和 `\` 以及 Shift 组合 `~` 和 `\|` |

---

## 实现步骤

### Step 1: Protocol 抽象 + 生产代码重构
- 定义 `PermissionProviding`、`InputSourceProviding`、`KeyboardLayoutProviding` 协议
- 创建 `System*Provider` 生产实现
- 重构 `PunctuationService`：init 注入依赖，改用 provider 调用
- 重构 `KeyboardLayoutMapper`：暴露 `fallbackMappings` 为 public static
- `handleKeyEvent` 改为 `internal`
- 添加 `isMonitoring` 计算属性用于测试断言
- 手动验证功能不变

### Step 2: Tuist 配置 + 目录结构
- 在 `Project.swift` 中添加测试目标
- 创建 `AutoKeySwitchTests/` 目录结构
- 验证 `tuist generate && tuist test` 可运行

### Step 3: Mock 实现
- 实现 `MockPermissionProvider`
- 实现 `MockInputSourceProvider`
- 实现 `MockKeyboardLayoutProvider`

### Step 4: 单元测试
- 实现 `KeyboardLayoutMapperTests`（ULM-001~006）
- 实现 `PunctuationServiceLogicTests`（PSL-001~009）
- 运行 `tuist test` 验证通过

### Step 5: 集成测试
- 实现 `PunctuationServiceIntegrationTests`（INT-001~005）
- 运行验证

### Step 6: E2E 测试
- 编写 AppleScript 自动化脚本
- 编写 shell 运行脚本
- 编写手动测试清单
- 手动执行验证

---

## 验证标准

1. `tuist test` 单元测试 + 集成测试全部通过
2. 单元测试覆盖 `KeyboardLayoutMapper` 所有 18 个标点键映射
3. 集成测试覆盖权限检查、输入法检测、键位替换完整流程
4. E2E 手动测试 8 个用例全部通过
5. 代码覆盖率 >= 80%（针对 Punctuation 相关模块）
6. 生产代码重构后功能不变（手动验证）

---

## 风险与注意事项

1. **Actor 隔离**：Protocol 注入属性必须用 `nonisolated(unsafe)` 标记，协议方法必须线程安全
2. **环境依赖**：涉及 TISInputSource 和 UCKeyTranslate 的测试在非 US 布局机器上可能结果不同
3. **CGEvent 测试**：构造 CGEvent 对象需要 Accessibility 权限，CI 中可能需要特殊配置
4. **AppleScript E2E**：需要 Accessibility 权限 + 辅助功能控制，首次运行需授权
