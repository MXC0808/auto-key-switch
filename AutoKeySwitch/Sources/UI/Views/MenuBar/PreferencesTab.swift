import SwiftUI
import Defaults
import UniformTypeIdentifiers

/// Preferences tab
struct PreferencesTab: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Binding var searchText: String
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
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("偏好设置")
                        .font(.headline.weight(.semibold))
                    Text("管理启动方式、界面可见性以及高级输入行为。")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, DesignTokens.Spacing.xs)

                if !searchText.isEmpty {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(.secondary)
                        Text("正在筛选包含“\(searchText)”的设置项")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                }

                PreferenceSectionCard(title: "通用", isVisible: matchesSection("通用", "登录时启动", "切换输入法时显示弹窗提示", "HUD")) {
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
                        isOn: $showHUDOnSwitch,
                        showsDivider: false
                    )
                    .onChange(of: showHUDOnSwitch) { newValue in
                        Defaults[.showHUDOnSwitch] = newValue
                    }
                }

                PreferenceSectionCard(title: "显示", isVisible: matchesSection("显示", "隐藏菜单栏图标", "隐藏 Dock 图标")) {
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
                        isOn: $isDockHidden,
                        showsDivider: false
                    )
                    .onChange(of: isDockHidden) { newValue in
                        AppVisibilityService.isDockHidden = newValue
                    }
                }

                PreferenceSectionCard(title: "高级", isVisible: matchesSection("高级", "强制英文符号", "辅助功能")) {
                    PreferenceActionToggleRow(
                        title: "强制英文符号",
                        description: "中文输入法下自动将标点符号转换为英文",
                        isOn: $forceEnglishPunctuationEnabled,
                        showsDivider: forceEnglishPunctuationEnabled && !hasAccessibilityPermission,
                        accessory: {
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
                        }
                    )
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
                        PreferenceInlineNoteRow {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("需要「辅助功能」权限才能工作")
                                    .foregroundStyle(.secondary)
                                Button("打开系统设置") {
                                    PermissionService.openAccessibilitySettings()
                                }
                                .buttonStyle(.link)
                                .focusable(false)
                            }
                            .font(.caption)
                        }
                    }
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Spacer()
                    Button {
                        exportConfiguration()
                    } label: {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }
                    .controlSize(.small)
                    .focusable(false)

                    Button {
                        showImportConfirmation = true
                    } label: {
                        Label("导入", systemImage: "square.and.arrow.down")
                    }
                    .controlSize(.small)
                    .focusable(false)
                }
            }
            .frame(maxWidth: DesignTokens.Sizes.contentWidth, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
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

    private func matchesSection(_ fragments: String...) -> Bool {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return true }
        return fragments.contains { $0.localizedCaseInsensitiveContains(keyword) }
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
    let isVisible: Bool
    @ViewBuilder let content: Content

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, 7)

                Divider()

                VStack(spacing: 0) {
                    content
                }
            }
            .background(DesignTokens.Colors.background.opacity(0.045))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                    .stroke(DesignTokens.Colors.divider.opacity(0.24), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous))
        }
    }
}

private struct PreferenceToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var showsDivider: Bool = true

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
                .toggleStyle(MinimalSwitchToggleStyle())
                .focusable(false)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Divider()
                    .padding(.leading, DesignTokens.Spacing.md)
            }
        }
    }
}

private struct PreferenceActionToggleRow<Accessory: View>: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    var showsDivider: Bool = true
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(DesignTokens.Typography.cardTitle)
                Text(description)
                    .font(DesignTokens.Typography.cardSubtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            accessory

            Toggle("", isOn: $isOn)
                .toggleStyle(MinimalSwitchToggleStyle())
                .focusable(false)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Divider()
                    .padding(.leading, DesignTokens.Spacing.md)
            }
        }
    }
}

private struct PreferenceInlineNoteRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            content
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 8)
    }
}

#Preview {
    PreferencesTab(searchText: .constant(""))
        .environmentObject(InputMethodManager.shared)
        .frame(width: 600, height: 560)
}
