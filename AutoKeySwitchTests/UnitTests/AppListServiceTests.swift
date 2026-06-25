import Testing
import Foundation
@testable import AutoKeySwitch

@Suite("AppListService Tests")
struct AppListServiceTests {

    @Test("fetchRunningApps returns non-empty list on macOS")
    func testFetchRunningApps() async {
        let runningApps = await AppListService.fetchRunningApps()
        #expect(!runningApps.isEmpty)
    }

    @Test("fetchRunningApps excludes current app")
    func testExcludesCurrentApp() async {
        let runningApps = await AppListService.fetchRunningApps()
        let currentBundleId = Bundle.main.bundleIdentifier
        let containsCurrentApp = runningApps.contains { $0.bundleId == currentBundleId }
        #expect(!containsCurrentApp)
    }

    @Test("fetchInstalledApps returns non-empty list")
    func testFetchInstalledApps() async {
        let installedApps = await AppListService.fetchInstalledApps()
        #expect(!installedApps.isEmpty)
    }

    @Test("fetchInstalledApps excludes current app")
    func testFetchInstalledAppsExcludesCurrentApp() async {
        let installedApps = await AppListService.fetchInstalledApps()
        let currentBundleId = Bundle.main.bundleIdentifier
        let containsCurrentApp = installedApps.contains { $0.bundleId == currentBundleId }
        #expect(!containsCurrentApp)
    }

    @Test("fetchInstalledApps returns sorted list")
    func testFetchInstalledAppsSorted() async {
        let installedApps = await AppListService.fetchInstalledApps()
        for i in 0..<(installedApps.count - 1) {
            let result = installedApps[i].name.localizedStandardCompare(installedApps[i + 1].name)
            #expect(result == .orderedAscending || result == .orderedSame)
        }
    }

    @Test("fetchRunningApps returns apps with valid bundle identifiers")
    func testFetchRunningAppsValidBundleIds() async {
        let runningApps = await AppListService.fetchRunningApps()
        for app in runningApps {
            #expect(!app.bundleId.isEmpty)
        }
    }

    @Test("fetchRunningApps returns apps with valid names")
    func testFetchRunningAppsValidNames() async {
        let runningApps = await AppListService.fetchRunningApps()
        for app in runningApps {
            #expect(!app.name.isEmpty)
        }
    }
}
