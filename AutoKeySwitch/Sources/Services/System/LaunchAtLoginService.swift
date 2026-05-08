import Foundation
import ServiceManagement
import os

/// 开机启动服务类
enum LaunchAtLoginService {
	private static let logger = Logger(subsystem: "com.autokeyswitch", category: "LaunchAtLoginService")
    /// 获取当前开机启动状态
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    /// 设置开机启动状态
    /// - Parameter enabled: 是否启用开机启动
    /// - Returns: 设置是否成功
    @discardableResult
    static func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            logger.error("Failed to set launch at login: \(error.localizedDescription)")
            return false
        }
    }
}
