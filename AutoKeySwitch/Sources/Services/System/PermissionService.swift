import AppKit

/// 权限检查服务
enum PermissionService {

    // MARK: - Accessibility Permission

    /// 检查辅助功能权限
    static func checkAccessibility() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 请求辅助功能权限（带系统弹窗）
    @discardableResult
    static func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    /// 打开辅助功能设置页面
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
