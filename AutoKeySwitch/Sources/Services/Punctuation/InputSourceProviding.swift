import Carbon

/// Input source detection protocol for dependency injection
/// Must be safe to call from nonisolated context (CGEvent callback)
protocol InputSourceProviding: Sendable {
    /// Returns language codes of the current input source (e.g. ["zh-Hans"], ["en"])
    func currentLanguages() -> [String]?

    /// Checks if current input source is CJKV based on language codes
    func isCJKV() -> Bool
}

/// Production implementation wrapping TISInputSource API
struct SystemInputSourceProvider: InputSourceProviding {
    func currentLanguages() -> [String]? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let langPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else {
            return nil
        }
        return Unmanaged<CFArray>.fromOpaque(langPtr).takeUnretainedValue() as? [String]
    }

    func isCJKV() -> Bool {
        guard let lang = currentLanguages()?.first else { return false }
        return lang.hasPrefix("zh") || lang == "ja" || lang == "ko" || lang == "vi"
    }
}
