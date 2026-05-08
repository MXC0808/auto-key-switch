import Foundation
@testable import AutoKeySwitch

/// Mock permission provider for testing
final class MockPermissionProvider: PermissionProviding {
    var accessibilityGranted = false
    var requestAccessCallCount = 0

    func checkAccessibility() -> Bool {
        accessibilityGranted
    }

    func requestAccessibility() -> Bool {
        requestAccessCallCount += 1
        return accessibilityGranted
    }
}
