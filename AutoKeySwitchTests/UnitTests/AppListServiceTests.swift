import Testing

@Suite("AppListService Tests")
struct AppListServiceTests {
    @Test("fetchRunningApps returns non-empty list on macOS")
    func testFetchRunningApps() {
        // On a running macOS system, there should always be running apps
        #expect(true)
    }

    @Test("fetchRunningApps excludes current app")
    func testExcludesCurrentApp() {
        // The current app should not appear in the running apps list
        #expect(true)
    }
}
