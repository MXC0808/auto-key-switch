import Testing
@testable import AutoKeySwitch

@Suite("PunctuationService Integration Tests")
struct PunctuationServiceIntegrationTests {

    // MARK: - INT-001: Full enable/disable cycle

    @Test("Full enable/disable cycle updates state correctly")
    @MainActor
    func testFullEnableDisableCycle() {
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

        let enabled = service.enable()
        #expect(enabled == true)
        #expect(service.isMonitoring == true)

        service.disable()
        #expect(service.isMonitoring == false)
    }

    // MARK: - INT-002: Enable creates event tap

    @Test("Enable creates event tap when permission granted")
    @MainActor
    func testEnableCreatesEventTap() {
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
        #expect(service.isMonitoring == true)

        service.disable()
    }

    // MARK: - INT-003: Disable invalidates event tap

    @Test("Disable invalidates event tap")
    @MainActor
    func testDisableInvalidatesEventTap() {
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

        service.enable()
        #expect(service.isMonitoring == true)

        service.disable()
        #expect(service.isMonitoring == false)
    }

    // MARK: - INT-004: Double enable is idempotent

    @Test("Double enable is idempotent — only one event tap active")
    @MainActor
    func testDoubleEnableIsIdempotent() {
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

        let first = service.enable()
        let second = service.enable()

        #expect(first == true)
        #expect(second == true)
        #expect(service.isMonitoring == true)

        service.disable()
    }

    // MARK: - INT-005: KeyboardLayoutMapper consistency

    @Test("Dynamic mappings cover same key codes as fallback mappings")
    @MainActor
    func testKeyboardLayoutMapperConsistency() {
        let dynamicMappings = KeyboardLayoutMapper.getMappings()
        let staticMappings = KeyboardLayoutMapper.fallbackMappings

        // Verify same number of mappings
        #expect(dynamicMappings.count == staticMappings.count,
                "Dynamic mapping count \(dynamicMappings.count) should match fallback count \(staticMappings.count)")

        // Verify same key codes are covered
        for keyCode in KeyboardLayoutMapper.punctuationKeyCodes {
            let dynamic = dynamicMappings[keyCode]
            let fallback = staticMappings[keyCode]

            // Both must be present or both absent
            #expect((dynamic != nil) == (fallback != nil),
                    "Key \(keyCode) presence mismatch: dynamic=\(dynamic != nil ? "present" : "nil"), fallback=\(fallback != nil ? "present" : "nil")")

            // Verify both normal and shifted are non-empty when present
            if let dynamic {
                #expect(!dynamic.normal.isEmpty, "Key \(keyCode) dynamic normal should not be empty")
                #expect(!dynamic.shifted.isEmpty, "Key \(keyCode) dynamic shifted should not be empty")
            }
        }
    }
}
