# AutoKeySwitch

<div align="center">

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](LICENSE)

[:us: English](README.md) | [:package: 安装方法](#安装方法) | [:book: 使用说明](#使用说明)

一款轻量、智能的 macOS 输入法自动切换工具，在应用间无缝切换输入法 — 再也不用手动切换了。

> **注意：** 本项目基于 [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch) 修改，移除了 SwiftUIX 依赖并增加了大量功能增强。

## :sparkles: 功能特性

- :repeat: **自动切换** — 切换应用时自动切换到预设的输入法
- :iphone: **菜单栏控制** — 通过菜单栏快速访问运行中的应用并切换输入法
- :brain: **应用记忆** — 记住每个应用上次使用的输入法状态，切换回来时自动恢复（最多 20 个应用）
- :pencil: **强制英文标点** — 在指定应用中使用中文输入法时，标点仍输出英文标点
- :gear: **按应用设置规则** — 为每个应用设置独立的输入法偏好
- :rocket: **开机启动** — 支持登录时自动启动
- :eye: **可见性控制** — 自由控制菜单栏图标和 Dock 图标的显示与隐藏

## :wrench: 系统要求

- macOS 13.0 或更高版本（兼容至 macOS 26）
- 辅助功能权限（用于检测应用切换）
- 输入监听权限（用于标点拦截功能）

## :package: 安装方法

### 从源码构建

1. 安装 [Tuist](https://github.com/tuist/tuist#install)

2. 克隆仓库
   ```bash
   git clone https://github.com/MXC0808/AutoKeySwitch.git
   cd AutoKeySwitch
   ```

3. 构建并运行
   ```bash
   make run          # 生成、编译并运行应用
   # 或分步执行：
   make generate     # 生成 Xcode 项目
   make build        # 编译项目
   make open         # 打开已编译的应用
   make clean        # 清理构建缓存
   make clean-build  # 完全清理后重新构建
   make help         # 显示所有可用命令
   ```

### 手动操作

```bash
tuist generate
open AutoKeySwitch.xcworkspace
```

## :book: 使用说明

### 菜单栏

1. 启动后，键盘图标出现在菜单栏中
2. 点击图标查看运行中的应用并快速切换输入法
3. 点击"打开主窗口"进入完整设置界面
4. 通过"登录时启动"设置开机自启

### 主窗口

主窗口通过侧边栏导航提供三个功能区域：

| 区域 | 说明 |
|------|------|
| **应用规则** | 管理每个应用的输入法偏好设置 |
| **应用记忆** | 为指定应用启用记忆功能，恢复上次使用的输入法状态 |
| **偏好设置** | 设置全局默认输入法，控制菜单栏/Dock 图标可见性 |

## :lock: 安全与隐私

AutoKeySwitch 重视你的隐私：

- :house: 所有数据本地存储，不会上传网络
- :no_entry_sign: 不收集任何用户信息或使用数据
- :book: 源代码完全开放，欢迎审查
- :shield: 权限仅用于声明的用途：
  - **辅助功能**：检测应用切换
  - **输入监听**：拦截标点按键（强制英文标点功能）
  - **登录项**：开机自动启动

## 依赖说明

- [Defaults](https://github.com/sindresorhus/Defaults) (7.3.1) — 持久化设置存储
- [SwifterSwift](https://github.com/SwifterSwift/SwifterSwift) (8.0.0) — Swift 原生扩展
- [VisualEffects](https://github.com/ArcticLeon/VisualEffects) — SwiftUI 模糊效果

构建工具：

- [Tuist](https://github.com/tuist/tuist) — 项目生成和管理

## 开发相关

### 环境要求

- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+（兼容至 macOS 26）
- [Tuist](https://github.com/tuist/tuist)

### 项目结构

```
AutoKeySwitch/
├── Project.swift                     # Tuist 项目配置
├── Tuist/                            # Tuist 配置
│   └── Signing/
│       └── AutoKeySwitch.entitlements
├── AutoKeySwitch/
│   └── Sources/
│       ├── App/                      # 应用入口
│       │   └── AutoSwitchInputApp.swift
│       ├── Core/
│       │   ├── DesignSystem.swift    # 设计令牌和主题
│       │   ├── Models/               # 数据模型
│       │   │   ├── AppInfo.swift
│       │   │   ├── InputMethod.swift
│       │   │   └── InputSourceProperties.swift
│       │   └── Extensions/           # Swift 扩展
│       │       ├── Defaults+Extensions.swift
│       │       └── View+Border.swift
│       ├── Models/
│       │   └── NavigationVM.swift    # 侧边栏导航模型
│       ├── Services/
│       │   ├── AppManagement/        # 应用发现和列表
│       │   │   ├── AppInfoService.swift
│       │   │   └── AppListService.swift
│       │   ├── InputMethod/          # 输入法切换
│       │   │   ├── InputMethodManager.swift
│       │   │   └── InputMethodService.swift
│       │   ├── Punctuation/          # 强制英文标点
│       │   │   ├── PunctuationService.swift
│       │   │   ├── InputSourceProviding.swift
│       │   │   ├── KeyboardLayoutProviding.swift
│       │   │   ├── KeyboardLayoutMapper.swift
│       │   │   └── PermissionProviding.swift
│       │   └── System/               # 系统服务
│       │       ├── AppVisibilityService.swift
│       │       ├── ConfigurationExportService.swift
│       │       ├── LaunchAtLoginService.swift
│       │       └── PermissionService.swift
│       └── UI/
│           └── Views/
│               ├── HUD/                   # 输入法切换 HUD
│               │   └── InputMethodHUDView.swift
│               └── MenuBar/               # 菜单栏和主窗口视图
│                   ├── MainView.swift
│                   ├── SidebarView.swift
│                   ├── MenuBarView.swift
│                   ├── AppSettingsTab.swift
│                   ├── ConfiguredAppsView.swift
│                   ├── RunningAppsView.swift
│                   ├── MemoryConfigView.swift
│                   ├── Memory/
│                   │   ├── MemoryAppRowView.swift
│                   │   ├── MemoryEnabledListView.swift
│                   │   ├── MemoryToolbarView.swift
│                   │   └── RunningAppCardView.swift
│                   ├── PreferencesTab.swift
│                   ├── SettingsView.swift
│                   ├── AddAppSheet.swift
│                   ├── AppRowView.swift
│                   ├── ContentHeaderView.swift
│                   └── ...
├── AutoKeySwitchTests/                    # 测试套件
│   ├── UnitTests/
│   ├── IntegrationTests/
│   ├── Mocks/
│   └── TestHelpers/
└── Makefile                               # 构建自动化
```

## 贡献指南

欢迎提交 Pull Request 和创建 Issue，在提交 PR 之前，请确保：

1. 代码符合项目的代码风格
2. 添加了必要的测试
3. 更新了相关文档

## 许可证

本项目基于 GNU General Public License v3.0 开源。详见 [LICENSE](LICENSE) 文件。

## 致谢

- [TypeSwitch](https://github.com/ygsgdbd/TypeSwitch) — AutoKeySwitch 所基于的原始项目
- [SwitchKey](https://github.com/itsuhane/SwitchKey) — 输入法切换的宝贵参考
- [InputSourcePro](https://github.com/runjuu/InputSourcePro) — 输入法管理的优秀参考
