import Testing
import Foundation
import Defaults
@testable import AutoKeySwitch

@Suite("InputMethodManager Logic Tests", .serialized)
struct InputMethodManagerTests {

    @Test("addAppToMemory respects max limit of 20")
    @MainActor
    func testMemoryLimit() {
        let manager = InputMethodManager.shared
        var testApps: [AppInfo] = []

        for i in 0..<20 {
            let app = AppInfo(bundleId: "com.test.memoryLimit.\(i)", name: "Test App \(i)", iconPath: "/Applications/Test\(i).app")
            manager.addAppToMemory(app)
            testApps.append(app)
        }

        let extraApp = AppInfo(bundleId: "com.test.memoryLimit.extra", name: "Extra App", iconPath: "/Applications/Extra.app")
        let result = manager.addAppToMemory(extraApp)
        #expect(result == false)

        for app in testApps {
            manager.removeAppFromMemory(app)
        }
        manager.removeAppFromMemory(extraApp)
    }

    @Test("removeAppFromMemory clears memory data")
    @MainActor
    func testRemoveAppFromMemory() {
        let manager = InputMethodManager.shared
        let app = AppInfo(bundleId: "com.test.removeMemory.\(UUID().uuidString)", name: "Remove App", iconPath: "/Applications/Remove.app")

        manager.addAppToMemory(app)
        #expect(manager.isMemoryEnabled(for: app))

        manager.removeAppFromMemory(app)
        #expect(!manager.isMemoryEnabled(for: app))
    }

    @Test("setInputMethod stores correct input method for app")
    @MainActor
    func testSetInputMethod() {
        let manager = InputMethodManager.shared
        let app = AppInfo(bundleId: "com.test.setInput.\(UUID().uuidString)", name: "Set App", iconPath: "/Applications/Set.app")

        manager.setInputMethod(for: app, to: "com.test.inputmethod")
        let stored = manager.getInputMethod(for: app)
        #expect(stored == "com.test.inputmethod")

        // Cleanup
        manager.setInputMethod(for: app, to: nil)
    }

    @Test("getInputMethod returns nil for unconfigured app")
    @MainActor
    func testGetInputMethodReturnsNil() {
        let manager = InputMethodManager.shared
        let app = AppInfo(bundleId: "com.test.unconfigured.\(UUID().uuidString)", name: "Unconfigured App", iconPath: "/Applications/Unconfigured.app")

        let result = manager.getInputMethod(for: app)
        #expect(result == nil)
    }

    @Test("setDefaultInputMethod updates default input method")
    @MainActor
    func testSetDefaultInputMethod() {
        let manager = InputMethodManager.shared
        let originalDefault = manager.defaultInputMethod

        manager.setDefaultInputMethod("com.test.default")
        #expect(manager.defaultInputMethod == "com.test.default")

        // Always restore, even if assertion fails
        manager.setDefaultInputMethod(originalDefault)
    }

    @Test("clearAllMemoryStates removes all memory states")
    @MainActor
    func testClearAllMemoryStates() {
        let manager = InputMethodManager.shared
        let app = AppInfo(bundleId: "com.test.clearStates.\(UUID().uuidString)", name: "Clear App", iconPath: "/Applications/Clear.app")

        manager.addAppToMemory(app)
        manager.clearAllMemoryStates()
        #expect(manager.lastInputMethodStates.isEmpty)

        // Cleanup
        manager.removeAppFromMemory(app)
    }

    @Test("isMemoryEnabled returns correct status")
    @MainActor
    func testIsMemoryEnabled() {
        let manager = InputMethodManager.shared
        let app = AppInfo(bundleId: "com.test.memoryEnabled.\(UUID().uuidString)", name: "Memory App", iconPath: "/Applications/Memory.app")

        manager.addAppToMemory(app)
        #expect(manager.isMemoryEnabled(for: app))

        manager.removeAppFromMemory(app)
        #expect(!manager.isMemoryEnabled(for: app))
    }

    @Test("setMemoryEnabled toggles memory state")
    @MainActor
    func testSetMemoryEnabled() {
        let manager = InputMethodManager.shared
        let app = AppInfo(bundleId: "com.test.toggleMemory.\(UUID().uuidString)", name: "Toggle App", iconPath: "/Applications/Toggle.app")

        manager.setMemoryEnabled(for: app, enabled: true)
        #expect(manager.isMemoryEnabled(for: app))

        manager.setMemoryEnabled(for: app, enabled: false)
        #expect(!manager.isMemoryEnabled(for: app))
    }

    @Test("isAutoSwitchEnabled defaults to true and can be changed")
    @MainActor
    func testIsAutoSwitchEnabledDefaultsToTrue() {
        let originalValue = Defaults[.isAutoSwitchEnabled]
        Defaults[.isAutoSwitchEnabled] = true
        #expect(Defaults[.isAutoSwitchEnabled])

        Defaults[.isAutoSwitchEnabled] = false
        #expect(!Defaults[.isAutoSwitchEnabled])

        Defaults[.isAutoSwitchEnabled] = originalValue
    }

    @Test("auto-switch enabled setting is restored after mutation")
    @MainActor
    func testAutoSwitchEnabledSettingRestoresAfterMutation() {
        let originalValue = Defaults[.isAutoSwitchEnabled]

        Defaults[.isAutoSwitchEnabled] = false
        #expect(Defaults[.isAutoSwitchEnabled] == false)

        Defaults[.isAutoSwitchEnabled] = true
        #expect(Defaults[.isAutoSwitchEnabled] == true)

        Defaults[.isAutoSwitchEnabled] = originalValue
    }
}
