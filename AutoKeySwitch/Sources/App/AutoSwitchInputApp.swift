import AppKit
import SwiftUI
import Combine
import Defaults

@main
struct AutoSwitchInputApp: App {
	@StateObject private var inputMethodManager = InputMethodManager.shared
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		MenuBarExtra {
			MenuBarView()
				.environmentObject(inputMethodManager)
				.task {
					await inputMethodManager.refreshAllData()
				}
		} label: {
			Image(systemName: "keyboard.badge.ellipsis")
		}
		.menuBarExtraStyle(.menu)
	}
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
	var mainWindow: NSWindow?
	var hudPanel: InputMethodHUDPanel?

	func applicationDidFinishLaunching(_ notification: Notification) {
		// 初始化 HUD
		hudPanel = InputMethodHUDPanel()

		// 监听打开主窗口通知
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleShowMainWindow),
			name: NSNotification.Name("ShowMainWindow"),
			object: nil
		)

		// 监听输入法切换通知
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleInputMethodSwitch),
			name: Notification.Name("inputMethodDidSwitch"),
			object: nil
		)

		// 监听菜单栏可见性变化
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleMenuBarVisibilityChanged),
			name: Notification.Name("menuBarVisibilityChanged"),
			object: nil
		)

		// 初始化时更新 Dock 可见性
		AppVisibilityService.updateDockVisibility()
	}

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		// Dock 栏点击时打开主窗口
		showMainWindow()
		return true
	}

	@objc func handleInputMethodSwitch(_ notification: Notification) {
		guard Defaults[.showHUDOnSwitch],
		      let name = notification.userInfo?["inputMethodName"] as? String else { return }
		hudPanel?.show(inputMethodName: name)
	}

	@objc func handleShowMainWindow() {
		Task { @MainActor in
			showMainWindow()
		}
	}

	@objc func handleMenuBarVisibilityChanged() {
		// 菜单栏可见性变化会自动处理
		// 注意: MenuBarExtra 的显示/隐藏需要重启应用才能生效
	}

	func showMainWindow() {
		if mainWindow == nil {
			let contentView = MainView()
				.environmentObject(InputMethodManager.shared)

			let window = NSWindow(
				contentRect: NSRect(x: 0, y: 0, width: 780, height: 520),
				styleMask: [.titled, .closable, .fullSizeContentView],
				backing: .buffered,
				defer: false
			)

			window.title = "AutoKeySwitch"
			window.titleVisibility = .hidden
			window.titlebarAppearsTransparent = true
			window.contentView = NSHostingView(rootView: contentView)
			window.center()
			window.isReleasedWhenClosed = false
			window.delegate = self

			// Set max window size
			window.maxSize = NSSize(width: 900, height: 680)

			// Disable zoom and minimize buttons
			window.standardWindowButton(.zoomButton)?.isEnabled = false
			window.standardWindowButton(.miniaturizeButton)?.isEnabled = false

			self.mainWindow = window
		}

		mainWindow?.makeKeyAndOrderFront(nil)
		NSApplication.shared.activate(ignoringOtherApps: true)
	}
}

// Handle window closing
extension AppDelegate: NSWindowDelegate {
	nonisolated func windowWillClose(_ notification: Notification) {
		// 窗口关闭时不做任何处理，保持 mainWindow 引用以便重新打开
	}
}