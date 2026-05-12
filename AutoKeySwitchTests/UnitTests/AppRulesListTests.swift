import Testing
import Foundation
import Defaults
@testable import AutoKeySwitch

@Suite("AppRulesList Tests")
struct AppRulesListTests {

    private func makeApp(bundleId: String, name: String) -> AppInfo {
        AppInfo(bundleId: bundleId, name: name, iconPath: "/Applications/\(name).app")
    }

    @MainActor
    private func setupManager(
        installedApps: [AppInfo],
        runningApps: [AppInfo],
        settings: [String: String?]
    ) -> InputMethodManager {
        let manager = InputMethodManager.shared
        manager.installedApps = installedApps
        manager.runningApps = runningApps
        Defaults[.appInputMethodSettings] = settings
        return manager
    }

    @Test("Returns configured apps")
    @MainActor
    func testReturnsConfiguredApps() {
        let app = makeApp(bundleId: "com.test.configured", name: "ConfiguredApp")
        let manager = setupManager(
            installedApps: [app],
            runningApps: [],
            settings: ["com.test.configured": "com.apple.keylayout.ABC"]
        )
        let result = manager.appRulesListApps
        #expect(result.contains(where: { $0.bundleId == "com.test.configured" }))
    }

    @Test("Returns running unconfigured apps")
    @MainActor
    func testReturnsRunningUnconfigured() {
        let app = makeApp(bundleId: "com.test.running", name: "RunningApp")
        let manager = setupManager(
            installedApps: [],
            runningApps: [app],
            settings: [:]
        )
        let result = manager.appRulesListApps
        #expect(result.contains(where: { $0.bundleId == "com.test.running" }))
    }

    @Test("Deduplicates apps in both installed and running")
    @MainActor
    func testDeduplication() {
        let app = makeApp(bundleId: "com.test.both", name: "BothApp")
        let manager = setupManager(
            installedApps: [app],
            runningApps: [app],
            settings: ["com.test.both": "com.apple.keylayout.ABC"]
        )
        let result = manager.appRulesListApps
        let count = result.filter { $0.bundleId == "com.test.both" }.count
        #expect(count == 1)
    }

    @Test("Sorts configured apps before unconfigured")
    @MainActor
    func testConfiguredFirst() {
        let configured = makeApp(bundleId: "com.test.cfg", name: "ZConfigured")
        let unconfigured = makeApp(bundleId: "com.test.uncfg", name: "ARunning")
        let manager = setupManager(
            installedApps: [configured],
            runningApps: [unconfigured],
            settings: ["com.test.cfg": "com.apple.keylayout.ABC"]
        )
        let result = manager.appRulesListApps
        guard result.count >= 2 else {
            Issue.record("Expected at least 2 apps")
            return
        }
        #expect(result[0].bundleId == "com.test.cfg")
        #expect(result[1].bundleId == "com.test.uncfg")
    }

    @Test("Sorts alphabetically within each group")
    @MainActor
    func testAlphabeticalSort() {
        let appB = makeApp(bundleId: "com.test.b", name: "BApp")
        let appA = makeApp(bundleId: "com.test.a", name: "AApp")
        let manager = setupManager(
            installedApps: [appB, appA],
            runningApps: [],
            settings: [
                "com.test.b": "com.apple.keylayout.ABC",
                "com.test.a": "com.apple.keylayout.ABC"
            ]
        )
        let result = manager.appRulesListApps
        guard result.count >= 2 else {
            Issue.record("Expected at least 2 apps")
            return
        }
        #expect(result[0].name == "AApp")
        #expect(result[1].name == "BApp")
    }
}
