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
			Image(systemName: "keyboard")
				.symbolRenderingMode(.monochrome)
				.imageScale(.medium)
		}
		.menuBarExtraStyle(.menu)
		.commands {
			CommandGroup(after: .newItem) {
				Button("打开主窗口") {
					NotificationCenter.default.post(name: .showMainWindow, object: nil)
				}
				.keyboardShortcut("o", modifiers: .command)
			}
		}
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
			name: .showMainWindow,
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

		DispatchQueue.main.async { [weak self] in
			self?.showMainWindow()
		}
	}

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		// Dock 栏点击时打开或唤回主窗口
		showMainWindow()
		return true
	}

	@objc func handleInputMethodSwitch(_ notification: Notification) {
		guard Defaults[.showHUDOnSwitch],
		      let name = notification.userInfo?["inputMethodName"] as? String else { return }
		hudPanel?.show(inputMethodName: name)
	}

	@objc func handleShowMainWindow() {
		showMainWindow()
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
				contentRect: NSRect(x: 0, y: 0, width: 960, height: 620),
				styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
				backing: .buffered,
				defer: false
			)

			window.title = "AutoKeySwitch"
			window.titleVisibility = .visible
			window.titlebarAppearsTransparent = true
			window.toolbarStyle = .unified
			window.collectionBehavior.insert(.fullScreenPrimary)
			window.contentView = NSHostingView(rootView: contentView)
			window.minSize = NSSize(width: 860, height: 560)
			window.center()
			window.isReleasedWhenClosed = false
			window.delegate = self

			self.mainWindow = window
		}

		if mainWindow?.isMiniaturized == true {
			mainWindow?.deminiaturize(nil)
		}

		mainWindow?.makeKeyAndOrderFront(nil)
		NSApplication.shared.activate(ignoringOtherApps: true)
	}
}

extension AppDelegate: NSWindowDelegate {
	nonisolated func windowWillClose(_ notification: Notification) {
		// 窗口关闭时保留引用，Dock、菜单栏和 Cmd+O 可快速唤回同一个窗口。
	}
}
