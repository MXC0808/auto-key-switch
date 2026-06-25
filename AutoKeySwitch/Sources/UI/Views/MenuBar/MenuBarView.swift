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

    private var defaultInputMethodName: String {
        viewModel.getDefaultInputMethodName() ?? "跟随系统"
    }

    var body: some View {
        Toggle(isAutoSwitchEnabled ? "自动切换已启用" : "自动切换已暂停", isOn: autoSwitchBinding)
            .keyboardShortcut("e", modifiers: [.command, .shift])

        Divider()

        if let currentActiveApp {
            Menu("当前应用：\(currentActiveApp.name)") {
                Text("当前规则：\(selectedInputMethodName(for: currentActiveApp))")
                Divider()
                inputMethodActions(for: currentActiveApp)
            }
        } else {
            Text("正在等待前台应用")
        }

        Menu("默认输入法：\(defaultInputMethodName)") {
            defaultInputMethodActions
        }

        Divider()

        Button("打开主窗口") {
            NotificationCenter.default.post(name: .showMainWindow, object: nil)
        }
        .keyboardShortcut("o", modifiers: .command)

        Button("退出") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var autoSwitchBinding: Binding<Bool> {
        Binding(
            get: { isAutoSwitchEnabled },
            set: { newValue in
                isAutoSwitchEnabled = newValue
                Defaults[.isAutoSwitchEnabled] = newValue
            }
        )
    }

    private func selectedInputMethodName(for app: AppInfo) -> String {
        viewModel.getSelectedInputMethodName(for: app) ?? "使用默认"
    }

    private func selectedTitle(_ title: String, isSelected: Bool) -> String {
        isSelected ? "✓ \(title)" : title
    }

    @ViewBuilder
    private func inputMethodActions(for app: AppInfo) -> some View {
        let selectedInputMethod = viewModel.getInputMethod(for: app)

        Button(selectedTitle("使用默认", isSelected: selectedInputMethod == nil)) {
            viewModel.setInputMethod(for: app, to: nil)
        }

        Divider()

        ForEach(viewModel.inputMethods) { inputMethod in
            Button(selectedTitle(inputMethod.name, isSelected: selectedInputMethod == inputMethod.id)) {
                viewModel.setInputMethod(for: app, to: inputMethod.id)
            }
        }
    }

    @ViewBuilder
    private var defaultInputMethodActions: some View {
        Button(selectedTitle("跟随系统", isSelected: viewModel.defaultInputMethod == nil)) {
            viewModel.setDefaultInputMethod(nil)
        }

        Divider()

        ForEach(viewModel.inputMethods) { inputMethod in
            Button(selectedTitle(inputMethod.name, isSelected: viewModel.defaultInputMethod == inputMethod.id)) {
                viewModel.setDefaultInputMethod(inputMethod.id)
            }
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(InputMethodManager.shared)
}
