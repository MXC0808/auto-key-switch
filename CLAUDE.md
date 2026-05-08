# AutoKeySwitch - macOS 输入法自动切换工具

## 项目概述
SwiftUI macOS 菜单栏应用，用于在不同应用间自动切换输入法。

## 技术栈
- **语言**: Swift 5.9
- **UI 框架**: SwiftUI
- **最低版本**: macOS 13.0
- **构建工具**: Tuist
- **持久化**: Defaults (App Group)
- **并发模型**: async/await + Combine

## 依赖库
- [Defaults](https://github.com/sindresorhus/Defaults) - UserDefaults 封装
- [SwifterSwift](https://github.com/SwifterSwift/SwifterSwift) - Swift 原生扩展

## 系统兼容性
- 最低支持 macOS 13 Ventura
- 兼容至 macOS 26
- 优先使用 macOS 13+ 新特性

## 代码规范

### 命名规范
- 类型命名: 4-40 字符，驼峰命名
- 变量命名: 语义化驼峰命名，避免无意义缩写
- 使用英文命名，注释可用中文

### 格式规范
- 单行不超过 110 字符
- 函数参数不超过 5 个
- 冒号紧跟变量名，后面加空格
- 运算符前后必须有空格
- 控制语句条件不使用括号

### SwiftLint 规则
```swift
// 行长度
line_length: 110

// 类型命名
type_name:
  min_length: 4
  max_length: 40

// 标识符命名
identifier_name:
  min_length: 4
  max_length: 40
```

## 设计规范

### Apple HIG 准则
- 保持界面整洁简约
- 视觉层次分明
- 重视细节完整性
- 支持浅色/深色模式

### UI 规范
- 合理使用留白
- 保持元素对齐
- 使用系统标准颜色和字体
- 提供清晰的交互反馈

## 第三方库使用

### Defaults
- 统一在 `Defaults+Extensions.swift` 声明 Keys
- Key 名称符合 ASCII 且不以 @ 开头
- 为每个 Key 提供默认值

### SwifterSwift
- 优先使用其扩展方法
- 利用语法糖优化代码

## 错误处理
- 使用 Result 类型
- 提供清晰的错误提示
- 避免强制解包
- 合理使用 `try?` 和 `try!`

## 性能优化
- 优先使用系统原生组件
- 利用 async/await 并发
- 避免重复造轮子

## 测试规范
- 使用 Swift Testing 框架（`@Test` + `#expect`）
- 单元测试覆盖核心功能
- 每个测试用例只测试一个功能点
- 需要系统权限的测试使用 `.condition()` 修饰符跳过

## 上下文优化
- 使用 `offset` 和 `limit` 参数分页读取大文件，避免重复读取整个文件
- 优先读取文件的关键部分，而非全量读取
- 减少不必要的文件读取，节省上下文空间

## 文件结构
```
AutoKeySwitch/Sources/
├── App/                    # 应用入口
├── Core/
│   ├── Models/             # 数据模型
│   └── Extensions/         # 扩展
├── Services/
│   ├── InputMethod/        # 输入法服务
│   ├── AppManagement/      # 应用管理
│   └── System/             # 系统服务
└── UI/Views/MenuBar/       # 菜单栏视图
```

## 工作方式
- 使用 Spec Coding，不做 Vibe Coding
- 实现前先说明方法
- 需求有歧义或风险较高时，先澄清并等待批准
- 代码中只使用英文，注释可用中文
- **拆分任务时使用 `/subagent-driven-development`**：将复杂任务拆分为多个子任务，分配给不同的 subagent 并行或串行执行，保持边界清晰、职责明确
