import Testing
import Carbon
@testable import AutoKeySwitch

@Suite("PunctuationService Logic Tests")
struct PunctuationServiceLogicTests {

    // MARK: - PSL-001: Enable fails when permission denied

    @Test("Enable fails when accessibility permission denied")
    @MainActor
    func testEnableFailsWhenPermissionDenied() {
        let mockPermission = MockPermissionProvider()
        mockPermission.accessibilityGranted = false
        let mockInput = MockInputSourceProvider()
        let mockLayout = MockKeyboardLayoutProvider()

        let service = PunctuationService(
            permissionProvider: mockPermission,
            inputSourceProvider: mockInput,
            keyboardLayoutProvider: mockLayout
        )

        let result = service.enable()
        #expect(result == false)
    }

    // MARK: - PSL-002: Enable succeeds when permission granted
    // Note: Requires actual Accessibility permission to create CGEvent tap

    @Test("Enable succeeds when permission granted and event tap created")
    @MainActor
    func testEnableSucceedsWhenPermissionGranted() {
        guard PermissionService.checkAccessibility() else {
            print("Skipping: Accessibility permission not granted")
            return
        }

        let mockPermission = MockPermissionProvider()
        mockPermission.accessibilityGranted = true
        let mockInput = MockInputSourceProvider()
        let mockLayout = MockKeyboardLayoutProvider()

        let service = PunctuationService(
            permissionProvider: mockPermission,
            inputSourceProvider: mockInput,
            keyboardLayoutProvider: mockLayout
        )

        let result = service.enable()
        #expect(result == true)
        service.disable()
    }

    // MARK: - PSL-003: Disable when not enabled is noop

    @Test("Disable when not enabled does not crash")
    @MainActor
    func testDisableWhenNotEnabledIsNoop() {
        let service = PunctuationService()
        service.disable()  // Should not crash
        #expect(true)
    }

    // MARK: - PSL-004: isCJKV with mock Chinese

    @Test("isCJKV returns true for Chinese input")
    func testIsCJKVWithMockChinese() {
        let mockInput = MockInputSourceProvider()
        mockInput.mockLanguages = ["zh-Hans"]
        #expect(mockInput.isCJKV() == true)
    }

    // MARK: - PSL-005: isCJKV with mock English

    @Test("isCJKV returns false for English input")
    func testIsCJKVWithMockEnglish() {
        let mockInput = MockInputSourceProvider()
        mockInput.mockLanguages = ["en"]
        #expect(mockInput.isCJKV() == false)
    }

    // MARK: - PSL-006: isCJKV with no input source

    @Test("isCJKV returns false when no input source")
    func testIsCJKVWithNoInputSource() {
        let mockInput = MockInputSourceProvider()
        mockInput.mockLanguages = nil
        #expect(mockInput.isCJKV() == false)
    }

    // MARK: - PSL-007~009: CJKV detection parameterized tests

    @Test("CJKV detection works for various languages", arguments: zip(
        InputMethodTestHelpers.cjkvLanguageCodes,
        Array(repeating: true, count: InputMethodTestHelpers.cjkvLanguageCodes.count)
    ))
    func testCJKVDetectionForCJKV(lang: String, expected: Bool) {
        let mockInput = MockInputSourceProvider()
        mockInput.mockLanguages = [lang]
        #expect(mockInput.isCJKV() == expected)
    }

    @Test("CJKV detection works for non-CJKV languages", arguments: zip(
        InputMethodTestHelpers.nonCJKVLanguageCodes,
        Array(repeating: false, count: InputMethodTestHelpers.nonCJKVLanguageCodes.count)
    ))
    func testCJKVDetectionForNonCJKV(lang: String, expected: Bool) {
        let mockInput = MockInputSourceProvider()
        mockInput.mockLanguages = [lang]
        #expect(mockInput.isCJKV() == expected)
    }

    // MARK: - KeyboardLayoutProviding mock behavior

    @Test("Mock keyboard layout provider returns configured mappings")
    func testMockKeyboardLayoutProvider() {
        let mockLayout = MockKeyboardLayoutProvider()
        mockLayout.mockMappings = [43: KeyMapping(normal: ",", shifted: "<")]

        #expect(mockLayout.getMapping(forKeyCode: 43)?.normal == ",")
        #expect(mockLayout.getMapping(forKeyCode: 47) == nil)
        #expect(mockLayout.getMappings().count == 1)
    }

    @Test("Mock keyboard layout provider tracks rebuild calls")
    func testMockKeyboardLayoutProviderRebuildTracking() {
        let mockLayout = MockKeyboardLayoutProvider()
        #expect(mockLayout.rebuildCallCount == 0)
        mockLayout.rebuildMappings()
        #expect(mockLayout.rebuildCallCount == 1)
    }

    @Test("Mock keyboard layout populateWithFallbackMappings works")
    @MainActor
    func testMockPopulateWithFallbackMappings() {
        let mockLayout = MockKeyboardLayoutProvider()
        mockLayout.populateWithFallbackMappings()
        #expect(mockLayout.getMappings().count == 18)
        #expect(mockLayout.getMapping(forKeyCode: 43)?.normal == ",")
    }
}
