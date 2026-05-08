import Foundation
@testable import AutoKeySwitch

/// Test helpers for input method related tests
enum InputMethodTestHelpers {
    /// CJKV language codes for parameterized testing
    static let cjkvLanguageCodes = ["zh-Hans", "zh-Hant", "zh", "ja", "ko", "vi"]

    /// Non-CJKV language codes for parameterized testing
    static let nonCJKVLanguageCodes = ["en", "en-US", "fr", "de", "es"]
}
