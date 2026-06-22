import SwiftUI
import Defaults
import UniformTypeIdentifiers

/// Preferences tab
struct PreferencesTab: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var isLaunchAtLoginEnabled = LaunchAtLoginService.isEnabled
    @State private var isMenuBarHidden = AppVisibilityService.isMenuBarHidden
    @State private var isDockHidden = AppVisibilityService.isDockHidden
    @State private var showRestartAlert = false
    @State private var forceEnglishPunctuationEnabled = Defaults[.forceEnglishPunctuationEnabled]
    @State private var hasAccessibilityPermission = PermissionService.checkAccessibility()
    @State private var showPermissionAlert = false
    @State private var showHelpPopover = false
    @State private var showForcePunctuationConfirmation = false
    @State private var isConfirmingForcePunctuation = false
    @State private var showImportConfirmation = false
    @State private var showImportError = false
    @State private var showHUDOnSwitch = Defaults[.showHUDOnSwitch]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            Text("偏好设置")
                .font(.headline)

            // 通用
            PreferenceSectionCard(title: "通用") {
                PreferenceToggleRow(
                    title: "登录时启动",
                    description: "系统登录时自动启动应用",
                    isOn: $isLaunchAtLoginEnabled
                )
                .onChange(of: isLaunchAtLoginEnabled) { newValue in
                    _ = LaunchAtLoginService.setLaunchAtLogin(newValue)
                }

                PreferenceToggleRow(
                    title: "切换输入法时显示弹窗提示",
                    description: "切换输入法时显示 HUD 提示",
                    isOn: $showHUDOnSwitch
                )
                .onChange(of: showHUDOnSwitch) { newValue in
                    Defaults[.showHUDOnSwitch] = newValue
                }
            }

            // 显示
            PreferenceSectionCard(title: "显示") {
                PreferenceToggleRow(
                    title: "隐藏菜单栏图标",
                    description: "隐藏后可通过 Dock 图标访问应用",
                    isOn: $isMenuBarHidden
                )
                .onChange(of: isMenuBarHidden) { newValue in
                    AppVisibilityService.isMenuBarHidden = newValue
                    showRestartAlert = true
                }

                PreferenceToggleRow(
                    title: "隐藏 Dock 图标",
                    description: "隐藏后仅通过菜单栏图标访问应用",
                    isOn: $isDockHidden
                )
                .onChange(of: isDockHidden) { newValue in
                    AppVisibilityService.isDockHidden = newValue
                }
            }

            // 高级
            PreferenceSectionCard(title: "高级") {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("强制英文符号")
                            .font(DesignTokens.Typography.cardTitle)
                        Text("中文输入法下自动将标点符号转换为英文")
                            .font(DesignTokens.Typography.cardSubtitle)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: { showHelpPopover = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .popover(isPresented: $showHelpPopover, arrowEdge: .trailing) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("功能说明")
                                .font(.headline)
                            Text("在中文输入法下自动将标点符号转换为英文。")
                            Text("需先开启此开关，然后在「应用规则」中开启特定应用。")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(width: 250)
                    }

                    Toggle("", isOn: $forceEnglishPunctuationEnabled)
                        .toggleStyle(.switch)
                        .focusable(false)
                }
                .onChange(of: forceEnglishPunctuationEnabled) { newValue in
                    if isConfirmingForcePunctuation {
                        isConfirmingForcePunctuation = false
                        return
                    }
                    if newValue {
                        forceEnglishPunctuationEnabled = false
                        showForcePunctuationConfirmation = true
                    } else {
                        Defaults[.forceEnglishPunctuationEnabled] = false
                        viewModel.updatePunctuationServiceState()
                    }
                }

                if forceEnglishPunctuationEnabled && !hasAccessibilityPermission {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("需要「辅助功能」权限才能工作")
                        Button("打开系统设置") {
                            PermissionService.openAccessibilitySettings()
                        }
                        .buttonStyle(.link)
                        .focusable(false)
                    }
                    .font(.caption)
                }
            }

            HStack {
                Spacer()
                Button("导出配置") {
                    exportConfiguration()
                }
                Button("导入配置") {
                    showImportConfirmation = true
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasAccessibilityPermission = PermissionService.checkAccessibility()
        }
        .alert("需要重启应用", isPresented: $showRestartAlert) {
            Button("立即重启") {
                AppVisibilityService.showRestartAlert()
            }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("菜单栏图标的显示/隐藏设置需要重启应用才能生效。")
        }
        .alert("需要授权", isPresented: $showPermissionAlert) {
            Button("打开系统设置") {
                PermissionService.openAccessibilitySettings()
            }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("请在「系统设置 > 隐私与安全性 > 辅助功能」中允许此应用。")
        }
        .alert("开启强制英文标点", isPresented: $showForcePunctuationConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确认开启") {
                isConfirmingForcePunctuation = true
                forceEnglishPunctuationEnabled = true
                Defaults[.forceEnglishPunctuationEnabled] = true
                hasAccessibilityPermission = PermissionService.checkAccessibility()
                if !hasAccessibilityPermission {
                    showPermissionAlert = true
                }
                viewModel.updatePunctuationServiceState()
            }
        } message: {
            Text("启用后将在指定应用中强制使用英文标点符号。确认开启？")
        }
        .confirmationDialog(
            "导入配置将覆盖当前所有设置，确定继续？",
            isPresented: $showImportConfirmation,
            titleVisibility: .visible
        ) {
            Button("确认导入", role: .destructive) {
                importConfiguration()
            }
        } message: {
            Text("此操作不可撤销")
        }
        .alert("导入失败", isPresented: $showImportError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("配置文件格式无效，请检查文件内容。")
        }
    }

    // MARK: - Import/Export

    private func exportConfiguration() {
        guard let data = ConfigurationExportService.export() else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "autokeyswitch-config.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url)
    }

    private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url) else {
            showImportError = true
            return
        }
        do {
            try ConfigurationExportService.import(from: data)
            forceEnglishPunctuationEnabled = Defaults[.forceEnglishPunctuationEnabled]
            viewModel.updatePunctuationServiceState()
        } catch {
            showImportError = true
        }
    }
}

// MARK: - Section Card Components

private struct PreferenceSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.sectionHeader)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.background.opacity(0.5))

            VStack(spacing: DesignTokens.Spacing.md) {
                content
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(DesignTokens.Colors.divider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
}

private struct PreferenceToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.cardTitle)
                Text(description)
                    .font(DesignTokens.Typography.cardSubtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .focusable(false)
        }
    }
}
