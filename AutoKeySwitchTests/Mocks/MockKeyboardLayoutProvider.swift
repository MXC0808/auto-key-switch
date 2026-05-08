import Foundation
@testable import AutoKeySwitch

/// Mock keyboard layout provider for testing
final class MockKeyboardLayoutProvider: KeyboardLayoutProviding {
    var mockMappings: [UInt16: KeyMapping] = [:]
    var rebuildCallCount = 0

    func getMappings() -> [UInt16: KeyMapping] {
        mockMappings
    }

    func getMapping(forKeyCode keyCode: UInt16) -> KeyMapping? {
        mockMappings[keyCode]
    }

    func rebuildMappings() {
        rebuildCallCount += 1
    }

    /// Convenience: populate with standard US layout fallback mappings
    func populateWithFallbackMappings() {
        mockMappings = KeyboardLayoutMapper.fallbackMappings
    }
}
