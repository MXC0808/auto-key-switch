import AppKit
import Carbon
import Combine
import IOKit
import os

/// 标点符号拦截服务
/// 在中文输入法下拦截标点键，输出英文标点
@MainActor
class PunctuationService: ObservableObject {
    private static let logger = Logger(subsystem: "com.autokeyswitch", category: "PunctuationService")

    /// 使用 nonisolated 存储以支持从 CGEvent 回调中访问
    private nonisolated(unsafe) var isEnabled = false
    private var eventTap: CFMachPort?
	private var runLoopSource: CFRunLoopSource?

    /// 注入的依赖 — nonisolated(unsafe) 以支持 CGEvent 回调访问
    private nonisolated(unsafe) let permissionProvider: PermissionProviding
    private nonisolated(unsafe) let inputSourceProvider: InputSourceProviding
    private nonisolated(unsafe) let keyboardLayoutProvider: KeyboardLayoutProviding

    /// Whether the event tap is currently active
    var isMonitoring: Bool {
        guard let eventTap = eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    // MARK: - Init

    init(
        permissionProvider: PermissionProviding = SystemPermissionProvider(),
        inputSourceProvider: InputSourceProviding = SystemInputSourceProvider(),
        keyboardLayoutProvider: KeyboardLayoutProviding = SystemKeyboardLayoutProvider()
    ) {
        self.permissionProvider = permissionProvider
        self.inputSourceProvider = inputSourceProvider
        self.keyboardLayoutProvider = keyboardLayoutProvider
    }

    // MARK: - Public API

    /// 启用服务
    /// - Returns: 是否成功启用
    @discardableResult
    func enable() -> Bool {
        guard !isEnabled else { return true }

        // 使用注入的权限检查
        guard permissionProvider.checkAccessibility() else {
            Self.logger.error("Accessibility permission not granted")
            return false
        }

        let success = startMonitoring()
        if success {
            isEnabled = true
            Self.logger.info("Punctuation service enabled")
        } else {
            Self.logger.error("Failed to start punctuation service - Accessibility permission required")
        }
        return success
    }

    /// 禁用服务
    func disable() {
        guard isEnabled else { return }

        stopMonitoring()
        isEnabled = false
        Self.logger.info("Punctuation service disabled")
    }

    /// 检查是否为 CJKV 输入法（nonisolated 以支持从 CGEvent 回调中调用）
    nonisolated func isCJKVInputMethod() -> Bool {
        return inputSourceProvider.isCJKV()
    }

    deinit {
    if let eventTap = eventTap {
    CGEvent.tapEnable(tap: eventTap, enable: false)
    CFMachPortInvalidate(eventTap)
    }
     if let runLoopSource = runLoopSource {
			CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
		}
	}

    // MARK: - Internal Helpers (testable)

    /// Handle key event from CGEvent tap callback
    internal func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        guard isEnabled, type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        // 检查是否为 CJKV 输入法
        guard isCJKVInputMethod() else {
            Self.logger.debug("Not CJKV input method, skipping punctuation replacement")
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        Self.logger.debug("Key down event: keyCode=\(keyCode)")

        // 检查是否有映射
        guard let mapping = keyboardLayoutProvider.getMapping(forKeyCode: UInt16(keyCode)) else {
            return Unmanaged.passUnretained(event)
        }

        // 根据是否有 Shift 决定输出
        let replacement = event.flags.contains(.maskShift) ? mapping.shifted : mapping.normal

        // 创建替换事件
        if let newEvent = createReplacementEvent(originalEvent: event, replacement: replacement) {
            Self.logger.info("Replacing key \(keyCode) with '\(replacement)'")
            return Unmanaged.passRetained(newEvent)
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Private Helpers

    @discardableResult
    private func startMonitoring() -> Bool {
        stopMonitoring()

        Self.logger.debug("Starting event tap creation")

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
        guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
        }
        let service = Unmanaged<PunctuationService>.fromOpaque(refcon).takeUnretainedValue()
        return service.handleKeyEvent(proxy: proxy, type: type, event: event)
        }

        // Try different event tap configurations for better compatibility
        let configurations: [(options: CGEventTapOptions, place: CGEventTapPlacement, description: String)] = [
            (.defaultTap, .headInsertEventTap, "Default + Head insertion"),
            (.defaultTap, .tailAppendEventTap, "Default + Tail insertion")
        ]

        for (index, config) in configurations.enumerated() {
            Self.logger.debug("Attempting event tap creation - \(config.description)")

            eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: config.place,
                options: config.options,
                eventsOfInterest: CGEventMask(eventMask),
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )

            if let eventTap = eventTap {
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
				CGEvent.tapEnable(tap: eventTap, enable: true)
                Self.logger.info("Event tap created successfully using \(config.description)")
                return true
            } else {
                Self.logger.debug("Failed: \(config.description) - trying next configuration")
            }
        }

        // 详细诊断：检查权限状态
        let accessType = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
        Self.logger.error("All event tap configurations failed. IOHIDCheckAccess result: \(accessType.rawValue)")
        return false
    }

    private func stopMonitoring() {
    if let eventTap = eventTap {
    CGEvent.tapEnable(tap: eventTap, enable: false)
    CFMachPortInvalidate(eventTap)
    self.eventTap = nil
    }
    if let runLoopSource = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
			self.runLoopSource = nil
		}
		Self.logger.debug("Event tap disabled and invalidated")
	}

    private func createReplacementEvent(originalEvent: CGEvent, replacement: String) -> CGEvent? {
        let originalKeyCode = CGKeyCode(originalEvent.getIntegerValueField(.keyboardEventKeycode))

        guard let source = CGEventSource(stateID: .privateState),
              let newEvent = CGEvent(keyboardEventSource: source, virtualKey: originalKeyCode, keyDown: true) else {
            return nil
        }

        let unicodeString = Array(replacement.utf16)
        newEvent.keyboardSetUnicodeString(stringLength: unicodeString.count, unicodeString: unicodeString)

        newEvent.timestamp = originalEvent.timestamp
        newEvent.flags = []

        return newEvent
    }
}
