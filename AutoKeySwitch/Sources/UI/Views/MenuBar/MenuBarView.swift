import AppKit
import SwiftUI
import Defaults

/// 菜单栏主视图
struct MenuBarView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var isAutoSwitchEnabled = Defaults[.isAutoSwitchEnabled]

    private var currentActiveApp: AppInfo? {
        guard let bundleId = viewModel.currentActiveAppBundleId else { return nil }
        return viewModel.runningApps.first { $0.bundleId == bundleId }
    }

    private var otherRunningApps: [AppInfo] {
        guard let currentActiveApp else { return viewModel.runningApps }
        return viewModel.runningApps.filter { $0.bundleId != currentActiveApp.bundleId }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Global toggle header
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "keyboard")
                    .frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
                Text("AutoKeySwitch")
                    .font(DesignTokens.Typography.menuItemTitle)
                Spacer()
                Toggle("", isOn: $isAutoSwitchEnabled)
                    .toggleStyle(.switch)
                    .focusable(false)
                    .onChange(of: isAutoSwitchEnabled) { newValue in
                        Defaults[.isAutoSwitchEnabled] = newValue
                    }
            }
            .padding(DesignTokens.Spacing.md)

            Divider()

            // Current active app
            if let currentActiveApp {
                MenuBarCurrentAppView(app: currentActiveApp)
                    .environmentObject(viewModel)
                    .opacity(isAutoSwitchEnabled ? 1.0 : 0.4)
            }

            // Other running apps
            if !otherRunningApps.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("其他运行中")
                        .font(DesignTokens.Typography.badgeText)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    ForEach(otherRunningApps) { app in
                        AppRowView(app: app)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.sm)
                .opacity(isAutoSwitchEnabled ? 1.0 : 0.4)
            }

            Divider()

            // Quick switch section
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("快速切换")
                    .font(DesignTokens.Typography.badgeText)
                    .foregroundStyle(.secondary)

                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(viewModel.inputMethods) { method in
                        Button(method.name) {
                            viewModel.setDefaultInputMethod(method.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .focusable(false)
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)

            Divider()

            // Actions toolbar
            HStack(spacing: DesignTokens.Spacing.sm) {
                Button("设置") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowMainWindow"), object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                .focusable(false)

                Spacer()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
                .focusable(false)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .frame(width: 260)
    }
}

private struct MenuBarCurrentAppView: View {
    let app: AppInfo
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconMedium, height: DesignTokens.Sizes.iconMedium)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(app.name)
                    .font(DesignTokens.Typography.menuItemTitle)
                Text(viewModel.getSelectedInputMethodName(for: app) ?? "使用默认")
                    .font(DesignTokens.Typography.menuItemSubtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("⌘1")
                .font(DesignTokens.Typography.badgeText)
                .foregroundStyle(.tertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.accentColor.opacity(0.06))
    }
}

#Preview {
    MenuBarView()
        .environmentObject(InputMethodManager.shared)
}
