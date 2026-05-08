import AppKit
import Combine
import Defaults
import os

/// 应用可见性配置服务
/// 管理菜单栏图标和 Dock 栏的显示状态
enum AppVisibilityService {
	private static let logger = Logger(subsystem: "com.autokeyswitch", category: "AppVisibilityService")
    /// 菜单栏图标是否隐藏
    /// 注意: 菜单栏图标的显示/隐藏需要重启应用才能完全生效
    static var isMenuBarHidden: Bool {
        get { Defaults[.menuBarHidden] }
        set {
            Defaults[.menuBarHidden] = newValue
            NotificationCenter.default.post(name: .menuBarVisibilityChanged, object: nil)
        }
    }

    /// Dock 图标是否隐藏
    static var isDockHidden: Bool {
        get { Defaults[.dockHidden] }
        set {
            Defaults[.dockHidden] = newValue
            updateDockVisibility()
        }
    }

    /// 更新 Dock 可见性
    static func updateDockVisibility() {
        DispatchQueue.main.async {
            if Defaults[.dockHidden] {
                NSApplication.shared.setActivationPolicy(.accessory)
            } else {
                NSApplication.shared.setActivationPolicy(.regular)
            }
        }
    }
    
    /// 显示重启提示
    static func showRestartAlert() {
    let alert = NSAlert()
    alert.messageText = "需要重启应用"
    alert.informativeText = "菜单栏图标的显示/隐藏设置需要重启应用才能生效。是否立即重启?"
    alert.addButton(withTitle: "重启")
    alert.addButton(withTitle: "稍后")
    alert.alertStyle = .informational

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
    let appPath = Bundle.main.bundleURL.path
    guard !appPath.isEmpty else {
     logger.error("Failed to get app bundle path for restart")
     return
    }
    do {
     let process = Process()
     process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
      process.arguments = [appPath]
       try process.run()
				NSApplication.shared.terminate(nil)
			} catch {
				logger.error("Failed to restart app: \(error.localizedDescription)")
			}
		}
	}
}

// MARK: - Notification Names

extension Notification.Name {
static let menuBarVisibilityChanged = Notification.Name("menuBarVisibilityChanged")
	static let inputMethodDidSwitch = Notification.Name("inputMethodDidSwitch")
}
