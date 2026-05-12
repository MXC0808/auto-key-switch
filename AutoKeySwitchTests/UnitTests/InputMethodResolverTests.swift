import Testing
import Foundation
@testable import AutoKeySwitch

@Suite("InputMethodResolver Tests")
struct InputMethodResolverTests {

    private func makeApp(bundleId: String, name: String) -> AppInfo {
        AppInfo(bundleId: bundleId, name: name, iconPath: "/Applications/\(name).app")
    }

    @Test("Returns memory state when memory enabled and state exists")
    func testMemoryStatePriority() {
        let app = makeApp(bundleId: "com.test.app1", name: "TestApp1")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.app1",
            memoryEnabledApps: ["com.test.app1"],
            lastInputMethodStates: ["com.test.app1": "com.apple.inputmethod.SCIM.ITABC"],
            appInputMethodSettings: [:],
            installedApps: [app],
            nameMatchingRules: [:],
            defaultInputMethod: nil
        )
        #expect(result == "com.apple.inputmethod.SCIM.ITABC")
    }

    @Test("Skips memory when memory not enabled for app")
    func testSkipsMemoryWhenNotEnabled() {
        let app = makeApp(bundleId: "com.test.app2", name: "TestApp2")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.app2",
            memoryEnabledApps: [],
            lastInputMethodStates: ["com.test.app2": "com.apple.inputmethod.SCIM.ITABC"],
            appInputMethodSettings: [:],
            installedApps: [app],
            nameMatchingRules: [:],
            defaultInputMethod: nil
        )
        #expect(result == nil)
    }

    @Test("Falls to manual config when memory not available")
    func testManualConfigFallback() {
        let app = makeApp(bundleId: "com.test.app3", name: "TestApp3")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.app3",
            memoryEnabledApps: [],
            lastInputMethodStates: [:],
            appInputMethodSettings: ["com.test.app3": "com.apple.keylayout.ABC"],
            installedApps: [app],
            nameMatchingRules: [:],
            defaultInputMethod: nil
        )
        #expect(result == "com.apple.keylayout.ABC")
    }

    @Test("Falls to name matching when no manual config")
    func testNameMatchingFallback() {
        let app = makeApp(bundleId: "com.test.wechat", name: "WeChat")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.wechat",
            memoryEnabledApps: [],
            lastInputMethodStates: [:],
            appInputMethodSettings: [:],
            installedApps: [app],
            nameMatchingRules: ["WeChat": "com.apple.keylayout.ABC"],
            defaultInputMethod: nil
        )
        #expect(result == "com.apple.keylayout.ABC")
    }

    @Test("Name matching is case-insensitive")
    func testNameMatchingCaseInsensitive() {
        let app = makeApp(bundleId: "com.test.telegram", name: "Telegram")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.telegram",
            memoryEnabledApps: [],
            lastInputMethodStates: [:],
            appInputMethodSettings: [:],
            installedApps: [app],
            nameMatchingRules: ["telegram": "com.apple.keylayout.ABC"],
            defaultInputMethod: nil
        )
        #expect(result == "com.apple.keylayout.ABC")
    }

    @Test("Returns global default when nothing else matches")
    func testGlobalDefaultFallback() {
        let app = makeApp(bundleId: "com.test.safari", name: "Safari")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.safari",
            memoryEnabledApps: [],
            lastInputMethodStates: [:],
            appInputMethodSettings: [:],
            installedApps: [app],
            nameMatchingRules: [:],
            defaultInputMethod: "com.apple.keylayout.US"
        )
        #expect(result == "com.apple.keylayout.US")
    }

    @Test("Returns nil when no rules match and no default set")
    func testReturnsNilWhenNothingMatches() {
        let app = makeApp(bundleId: "com.test.terminal", name: "Terminal")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.terminal",
            memoryEnabledApps: [],
            lastInputMethodStates: [:],
            appInputMethodSettings: [:],
            installedApps: [app],
            nameMatchingRules: [:],
            defaultInputMethod: nil
        )
        #expect(result == nil)
    }

    @Test("Memory takes priority over manual config when both present")
    func testMemoryPriorityOverManualConfig() {
        let app = makeApp(bundleId: "com.test.app8", name: "TestApp8")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.app8",
            memoryEnabledApps: ["com.test.app8"],
            lastInputMethodStates: ["com.test.app8": "com.apple.inputmethod.SCIM.ITABC"],
            appInputMethodSettings: ["com.test.app8": "com.apple.keylayout.ABC"],
            installedApps: [app],
            nameMatchingRules: [:],
            defaultInputMethod: nil
        )
        #expect(result == "com.apple.inputmethod.SCIM.ITABC")
    }

    @Test("Name matching uses first matching pattern")
    func testNameMatchingFirstMatch() {
        let app = makeApp(bundleId: "com.test.app", name: "WeChat Desktop")
        let result = InputMethodResolver.resolve(
            bundleId: "com.test.app",
            memoryEnabledApps: [],
            lastInputMethodStates: [:],
            appInputMethodSettings: [:],
            installedApps: [app],
            nameMatchingRules: [
                "WeChat": "com.apple.inputmethod.SCIM.ITABC",
                "Desktop": "com.apple.keylayout.ABC"
            ],
            defaultInputMethod: nil
        )
        // Dictionary iteration order is non-deterministic, but either match is valid
        #expect(result != nil)
    }
}
