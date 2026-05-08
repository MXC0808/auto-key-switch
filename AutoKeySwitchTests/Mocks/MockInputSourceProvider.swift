import Foundation
@testable import AutoKeySwitch

/// Mock input source provider for testing
final class MockInputSourceProvider: InputSourceProviding {
    var mockLanguages: [String]? = ["zh-Hans"]

    func currentLanguages() -> [String]? {
        mockLanguages
    }

    func isCJKV() -> Bool {
        guard let lang = mockLanguages?.first else { return false }
        return lang.hasPrefix("zh") || lang == "ja" || lang == "ko" || lang == "vi"
    }
}
