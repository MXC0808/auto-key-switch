@preconcurrency import Defaults
import Foundation

/// Defaults extension - centralizes all application setting keys
extension Defaults.Keys {
    private static let appGroupSuite: UserDefaults = {
        UserDefaults(suiteName: "group.top.ygsgdbd.TypeSwitch") ?? .standard
    }()

    /// Per-app input method settings storage
    /// Format: `[String: String?]` where String is bundleId, String? is input method ID (nil = unconfigured)
    nonisolated static let appInputMethodSettings = Key<[String: String?]>("appInputMethodSettings", default: [:], suite: appGroupSuite)

    /// Global default input method
    nonisolated static let defaultInputMethod = Key<String?>("defaultInputMethod", default: nil, suite: appGroupSuite)

    /// Apps with input method memory feature enabled
    /// Format: `Set<String>` where String is bundleId
    nonisolated static let memoryEnabledApps = Key<Set<String>>("memoryEnabledApps", default: [], suite: appGroupSuite)

    /// Whether menu bar icon is hidden
    nonisolated static let menuBarHidden = Key<Bool>("menuBarHidden", default: false)

    /// Whether Dock icon is hidden
    nonisolated static let dockHidden = Key<Bool>("dockHidden", default: false)

    /// Force English punctuation - global toggle
    nonisolated static let forceEnglishPunctuationEnabled = Key<Bool>(
        "forceEnglishPunctuationEnabled",
        default: false,
        suite: appGroupSuite
    )

    /// Force English punctuation - enabled app list (stores bundleIds)
    nonisolated static let forceEnglishPunctuationApps = Key<Set<String>>(
        "forceEnglishPunctuationApps",
        default: [],
        suite: appGroupSuite
    )

    /// App name matching rules (name pattern -> input method ID)
    nonisolated static let appNameMatchingRules = Key<[String: String]>("appNameMatchingRules", default: [:])

    /// Whether to show the HUD popup when switching input methods
    nonisolated static let showHUDOnSwitch = Key<Bool>("showHUDOnSwitch", default: true)
}
