/// Keyboard layout mapping protocol for dependency injection
/// Must be safe to call from nonisolated context (CGEvent callback)
protocol KeyboardLayoutProviding: Sendable {
    func getMappings() -> [UInt16: KeyMapping]
    func getMapping(forKeyCode keyCode: UInt16) -> KeyMapping?
    func rebuildMappings()
}

/// Production implementation wrapping KeyboardLayoutMapper static calls
/// Uses MainActor.assumeIsolated because CGEvent callbacks run on the main run loop
struct SystemKeyboardLayoutProvider: KeyboardLayoutProviding {
    func getMappings() -> [UInt16: KeyMapping] {
        MainActor.assumeIsolated {
            KeyboardLayoutMapper.getMappings()
        }
    }

    func getMapping(forKeyCode keyCode: UInt16) -> KeyMapping? {
        MainActor.assumeIsolated {
            KeyboardLayoutMapper.getMapping(forKeyCode: keyCode)
        }
    }

    func rebuildMappings() {
        MainActor.assumeIsolated {
            KeyboardLayoutMapper.rebuildMappings()
        }
    }
}
