import AppKit
import Carbon
import Combine
import Foundation
import SwiftUI
import Defaults
import os

// MARK: - Constants
enum Constants {
    /// 最多允许启用记忆功能的应用数量
    static let maxMemoryEnabledApps = 20
}

@MainActor
final class InputMethodManager: ObservableObject {
static let shared = InputMethodManager()
	private static let logger = Logger(subsystem: "com.autokeyswitch", category: "InputMethodManager")
    
    @Published var inputMethods: [InputMethod] = []
    @Published var installedApps: [AppInfo] = []
    @Published var runningApps: [AppInfo] = []
    @Published var defaultInputMethod: String? = Defaults[.defaultInputMethod]

    // 是否已加载过已安装应用列表
    private var hasLoadedInstalledApps = false

    // MARK: - Punctuation Service

    /// 标点符号拦截服务
    private var punctuationService: PunctuationService?

    /// 强制英文符号服务是否成功启用（用于 UI 显示权限状态）
    @Published private(set) var punctuationServiceEnabled = false

	/// Last input method switch error (nil if last switch succeeded)
	@Published var lastSwitchError: String?

	// MARK: - Memory Feature Properties

    /// 记忆功能开关（按应用）- 持久化
    /// 开关状态需要持久化，否则用户每次启动都要重新配置
    @Published private(set) var memoryEnabledApps: Set<String> = Defaults[.memoryEnabledApps]

    /// 上次输入法状态（内存存储）- 本次会话有效
    /// Key: 应用 bundleId
    /// Value: 输入法 ID
    @Published private(set) var lastInputMethodStates: [String: String] = [:]

    /// 当前活跃应用的 bundleId（用于追踪「正在离开的应用」）
    /// 在 handleAppActivation 开始时代表「正在离开的应用」
    /// 在 handleAppActivation 结束时更新为「新激活的应用」
    private(set) var currentActiveAppBundleId: String?

    /// 已启用记忆的应用信息（用于 UI 展示）
    var memoryEnabledAppsInfo: [AppInfo] {
        installedApps.filter { memoryEnabledApps.contains($0.bundleId) }
    }

    // UI 状态
    @Published private(set) var settingsVersion: UUID = UUID()  // 跟踪设置变化以触发 UI 更新
    
    
    // 存储订阅
    private var cancellables: Set<AnyCancellable> = []
    
    private init() {
        // 初始化标点符号服务
        punctuationService = PunctuationService()

        Task {
            // 只加载必要的数据：输入法列表和运行中的应用
            await refreshInputMethods()
            await refreshRunningApps()
            // 初始化当前活跃应用，确保首次切换时能正确记录
            currentActiveAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            // 初始化时检查当前应用是否需要启用强制英文符号
            if let bundleId = currentActiveAppBundleId {
                updatePunctuationService(for: bundleId)
            }
        }
        setupSubscriptions()
    }
    
    deinit {
        // cancellables 会在对象销毁时自动清理
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // 监听输入法变化
        DistributedNotificationCenter.default()
            .publisher(for: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String))
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshInputMethods()
                }
            }
            .store(in: &cancellables)

            // 监听键盘布局变化
	DistributedNotificationCenter.default()
		.publisher(for: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String))
		.receive(on: DispatchQueue.main)
		.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
		.sink { [weak self] _ in
			KeyboardLayoutMapper.onKeyboardLayoutChanged()
			Task { @MainActor in
				await self?.refreshInputMethods()
			}
		}
		.store(in: &cancellables)

	// 监听应用启动通知
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshRunningApps()
                }
            }
            .store(in: &cancellables)
        
        // 监听应用退出通知
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshRunningApps()
                }
            }
            .store(in: &cancellables)
        
        // 监听应用激活通知
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleAppActivation(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func refreshAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshInputMethods() }
            group.addTask { await self.refreshInstalledApps() }
            group.addTask { await self.refreshRunningApps() }
        }
    }
    
    func refreshInputMethods() async {
        do {
            let methods = try InputMethodService.fetchInputMethods()
            self.inputMethods = methods
        } catch {
        Self.logger.error("Failed to fetch input methods: \(error.localizedDescription)")
        }
    }
    
    /// 刷新已安装的应用（仅在需要时调用）
    func refreshInstalledApps() async {
        // 避免重复加载
        guard !hasLoadedInstalledApps else { return }
        installedApps = await AppListService.fetchInstalledApps()
        hasLoadedInstalledApps = true
    }

    /// 强制刷新已安装应用列表
    func forceRefreshInstalledApps() async {
        installedApps = await AppListService.fetchInstalledApps()
        hasLoadedInstalledApps = true
    }
    
    /// 刷新运行中的应用
    func refreshRunningApps() async {
        runningApps = await AppListService.fetchRunningApps()
    }
    
    // MARK: - Private Methods

    /// 记录正在离开的应用的输入法状态
    private func recordPreviousAppState() async {
        // currentActiveAppBundleId 在此时代表「正在离开的应用」
        guard let leavingAppId = currentActiveAppBundleId,
              memoryEnabledApps.contains(leavingAppId) else {
            return
        }

        // 记录当前输入法状态到正在离开的应用
        if let currentInputMethod = try? InputMethodService.getCurrentInputMethodId() {
            lastInputMethodStates[leavingAppId] = currentInputMethod
        }
    }

    /// 确定目标输入法（优先级：上次状态 > 手动配置 > 全局默认）
    /// - Parameter bundleId: 应用 bundleId
    /// - Returns: 目标输入法 ID
    private func determineTargetInputMethod(for bundleId: String) -> String? {
    // 优先级 1：上次状态（仅当启用记忆时）
    if memoryEnabledApps.contains(bundleId),
    let lastState = lastInputMethodStates[bundleId] {
    return lastState
    }

    // 优先级 2：手动配置（bundleId 精确匹配）
    if let manualConfig = Defaults[.appInputMethodSettings][bundleId] {
    return manualConfig
    }

    // 优先级 3：名称模糊匹配
    if let appName = installedApps.first(where: { $0.bundleId == bundleId })?.name {
      let nameRules = Defaults[.appNameMatchingRules]
			for (pattern, inputMethodId) in nameRules {
				if appName.localizedCaseInsensitiveContains(pattern) {
					return inputMethodId
				}
			}
		}

		// 优先级 4：全局默认
		return defaultInputMethod
	}

    /// 处理应用激活事件
    private func handleAppActivation(_ notification: Notification) async {
        // 1. 先记录正在离开的应用的状态
        await recordPreviousAppState()

        // 2. 获取当前激活的应用
        guard let userInfo = notification.userInfo,
              let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = app.bundleIdentifier else {
            return
        }

        // 3. 更新当前活跃应用追踪（为下次切换准备）
        currentActiveAppBundleId = bundleId

        // 4. 检查应用是否在已安装列表中（用于手动配置）
        guard installedApps.contains(where: { $0.bundleId == bundleId }) else {
            // 不在已安装应用列表中，仅更新标点符号服务并返回
            updatePunctuationService(for: bundleId)
            return
        }

        // 5. 确定目标输入法（优先级：上次状态 > 手动配置 > 全局默认）
        let targetInputMethodId = determineTargetInputMethod(for: bundleId)

        // 6. 执行切换
        if let targetId = targetInputMethodId {
            do {
                try InputMethodService.switchToInputMethod(targetId)
                lastSwitchError = nil
				let name = inputMethods.first(where: { $0.id == targetId })?.name ?? targetId
				NotificationCenter.default.post(name: .inputMethodDidSwitch, object: nil, userInfo: ["inputMethodName": name])
            } catch {
            lastSwitchError = error.localizedDescription
            }
        }

        // 7. 检查是否需要启用强制英文符号
        updatePunctuationService(for: bundleId)
    }

        /// 更新标点符号服务状态
        private func updatePunctuationService(for bundleId: String) {
        guard Defaults[.forceEnglishPunctuationEnabled],
        Defaults[.forceEnglishPunctuationApps].contains(bundleId) else {
        punctuationService?.disable()
        punctuationServiceEnabled = false
            return
        }
            punctuationServiceEnabled = punctuationService?.enable() ?? false
            }

            /// 公开方法：立即更新标点符号服务状态（用于 UI 勾选时调用）
    func updatePunctuationServiceState() {
    guard let bundleId = currentActiveAppBundleId else { return }
    updatePunctuationService(for: bundleId)
    }

	/// Toggle between the first two available input methods
	func toggleCurrentInputMethod() {
		guard inputMethods.count >= 2 else { return }
		guard let currentId = try? InputMethodService.getCurrentInputMethodId() else { return }
		let currentIndex = inputMethods.firstIndex(where: { $0.id == currentId }) ?? 0
		let nextIndex = (currentIndex + 1) % inputMethods.count
		let targetMethod = inputMethods[nextIndex]
		do {
			try InputMethodService.switchToInputMethod(targetMethod.id)
			lastSwitchError = nil
		} catch {
			lastSwitchError = error.localizedDescription
		}
	}

    /// 设置应用的输入法
    func setInputMethod(for app: AppInfo, to inputMethodId: String?) {
        var settings = Defaults[.appInputMethodSettings]
        
        if let inputMethodId = inputMethodId {
            // 设置输入法
            settings[app.bundleId] = inputMethodId
        } else {
            // 移除输入法设置
            settings.removeValue(forKey: app.bundleId)
        }
        
        Defaults[.appInputMethodSettings] = settings
        settingsVersion = UUID()
    }
    
    /// 获取应用的输入法ID
    func getInputMethod(for app: AppInfo) -> String? {
        return Defaults[.appInputMethodSettings][app.bundleId] ?? nil
    }
    
    // MARK: - UI Helper Methods
    
    /// 获取已配置输入法的应用列表
    var configuredApps: [AppInfo] {
        let settings = Defaults[.appInputMethodSettings]
        return installedApps.filter { app in
            settings[app.bundleId] != nil
        }
    }
    
    /// 获取应用选中的输入法名称
    func getSelectedInputMethodName(for app: AppInfo) -> String? {
    // 依赖于 settingsVersion 以确保设置变化时 UI 更新
    _ = settingsVersion

    guard let inputMethodId = getInputMethod(for: app), !inputMethodId.isEmpty else {
    return nil
    }

    return inputMethods.first(where: { $0.id == inputMethodId })?.name
    }

    /// 获取应用规则列表显示的应用（已配置 + 运行中未配置）
	var appRulesListApps: [AppInfo] {
		// 已配置的应用
		let configuredApps = installedApps.filter { app in
			getInputMethod(for: app) != nil
		}
		// 运行中未配置的应用
		let runningUnconfigured = runningApps.filter { app in
			getInputMethod(for: app) == nil
		}
		// 合并去重
		var seen = Set<String>()
		let allApps = (configuredApps + runningUnconfigured).filter { app in
			if seen.contains(app.bundleId) {
				return false
			}
			seen.insert(app.bundleId)
			return true
		}
		// 排序：已配置在前，运行中未配置在后
		return allApps.sorted { app1, app2 in
			let app1Configured = getInputMethod(for: app1) != nil
			let app2Configured = getInputMethod(for: app2) != nil
			if app1Configured != app2Configured {
				return app1Configured
			}
			return app1.name.localizedCompare(app2.name) == .orderedAscending
		}
	}

	/// 检查应用是否在规则列表中
	func isAppInRulesList(_ app: AppInfo) -> Bool {
		return getInputMethod(for: app) != nil || runningApps.contains(where: { $0.bundleId == app.bundleId })
	}

	// MARK: - Default Input Method

    /// Set global default input method
    func setDefaultInputMethod(_ inputMethodId: String?) {
        Defaults[.defaultInputMethod] = inputMethodId
        defaultInputMethod = inputMethodId
        settingsVersion = UUID()
    }

    /// Get default input method name
    func getDefaultInputMethodName() -> String? {
        guard let inputMethodId = defaultInputMethod else {
            return nil
        }
        return inputMethods.first(where: { $0.id == inputMethodId })?.name
    }

    /// Get unconfigured apps
    var unconfiguredApps: [AppInfo] {
        let settings = Defaults[.appInputMethodSettings]
        return installedApps.filter { app in
            settings[app.bundleId] == nil
        }
    }

    /// Add app to configured list
    func addAppToConfigured(_ app: AppInfo) {
        // Set to use global default input method
        if let defaultId = defaultInputMethod {
            setInputMethod(for: app, to: defaultId)
        }
    }

    /// Remove app from configured list
    func removeAppFromConfigured(_ app: AppInfo) {
        setInputMethod(for: app, to: nil)
    }

    // MARK: - Memory Feature Methods

    /// 添加应用到记忆列表
    /// - Parameter app: 要添加的应用
    /// - Returns: 是否添加成功（可能因已达上限而失败）
    @discardableResult
    func addAppToMemory(_ app: AppInfo) -> Bool {
        guard memoryEnabledApps.count < Constants.maxMemoryEnabledApps else {
            return false
        }
        memoryEnabledApps.insert(app.bundleId)
        Defaults[.memoryEnabledApps] = memoryEnabledApps
        return true
    }

    /// 检查应用是否启用记忆功能
    /// - Parameter app: 应用信息
    /// - Returns: 是否启用记忆
    func isMemoryEnabled(for app: AppInfo) -> Bool {
        return memoryEnabledApps.contains(app.bundleId)
    }

    /// 设置应用记忆开关
    /// - Parameters:
    ///   - app: 应用信息
    ///   - enabled: 是否启用
    func setMemoryEnabled(for app: AppInfo, enabled: Bool) {
        if enabled {
            guard memoryEnabledApps.count < Constants.maxMemoryEnabledApps else {
                // 已达上限，不执行操作
                // UI 层应该显示提示，这里静默返回
                return
            }
            memoryEnabledApps.insert(app.bundleId)
        } else {
            memoryEnabledApps.remove(app.bundleId)
            // 清除该应用的记忆数据
            lastInputMethodStates.removeValue(forKey: app.bundleId)
        }
        // 持久化开关状态
        Defaults[.memoryEnabledApps] = memoryEnabledApps
    }

    /// 获取应用的上次输入法 ID
    /// - Parameter app: 应用信息
    /// - Returns: 上次使用的输入法 ID，如果没有则返回 nil
    func getLastInputMethod(for app: AppInfo) -> String? {
        return lastInputMethodStates[app.bundleId]
    }

    /// 清除所有记忆数据（不清除开关状态）
    func clearAllMemoryStates() {
        lastInputMethodStates.removeAll()
    }

    /// 获取已启用记忆功能的应用数量
    /// - Returns: 应用数量
    func getMemoryEnabledCount() -> Int {
        return memoryEnabledApps.count
    }

    /// 从记忆列表移除应用
    /// - Parameter app: 要移除的应用
    func removeAppFromMemory(_ app: AppInfo) {
        memoryEnabledApps.remove(app.bundleId)
        lastInputMethodStates.removeValue(forKey: app.bundleId)
        Defaults[.memoryEnabledApps] = memoryEnabledApps
    }

    /// 批量从记忆列表移除应用
    /// - Parameter apps: 要移除的应用列表
    func removeAppsFromMemory(_ apps: [AppInfo]) {
        for app in apps {
            memoryEnabledApps.remove(app.bundleId)
            lastInputMethodStates.removeValue(forKey: app.bundleId)
        }
        Defaults[.memoryEnabledApps] = memoryEnabledApps
    }

    /// 清空所有记忆配置
    func clearAllMemory() {
        memoryEnabledApps.removeAll()
        lastInputMethodStates.removeAll()
        Defaults[.memoryEnabledApps] = memoryEnabledApps
    }
}
