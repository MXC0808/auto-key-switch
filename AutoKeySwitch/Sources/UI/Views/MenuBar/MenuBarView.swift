import AppKit
import SwiftUI

/// 菜单栏主视图
struct MenuBarView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var isLaunchAtLoginEnabled = LaunchAtLoginService.isEnabled

    var body: some View {
        Group {
            // 运行中的应用（快捷切换）
            RunningAppsView()

            Divider()

            // 打开主窗口
            Button("打开主窗口...") {
                NotificationCenter.default.post(name: NSNotification.Name("ShowMainWindow"), object: nil)
            }
            .keyboardShortcut("o", modifiers: .command)

            // 登录时启动
            Toggle("登录时启动", isOn: $isLaunchAtLoginEnabled)
            .toggleStyle(.checkbox)
		.focusable(false)
                .onChange(of: isLaunchAtLoginEnabled) { newValue in
                    _ = LaunchAtLoginService.setLaunchAtLogin(newValue)
                }

            Divider()

            // 退出应用
            Button("退出 AutoKeySwitch") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(InputMethodManager.shared)
}
