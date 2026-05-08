@preconcurrency import Defaults
import Foundation

/// Defaults 扩展,统一管理所有应用设置 Keys
extension Defaults.Keys {
    /// 应用输入法设置存储 Key
    /// 存储格式: `[String: String?]`,其中 String 是应用的 bundleId,String? 是输入法 ID (nil 表示不配置)
    nonisolated static let appInputMethodSettings = Key<[String: String?]>("appInputMethodSettings", default: [:], suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!)

    /// Global default input method
    nonisolated static let defaultInputMethod = Key<String?>("defaultInputMethod", default: nil, suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!)

    /// Apps with input method memory feature enabled
    /// 存储格式: `Set<String>`,其中 String 是应用的 bundleId
    nonisolated static let memoryEnabledApps = Key<Set<String>>("memoryEnabledApps", default: [], suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!)

    /// 菜单栏图标是否隐藏
    nonisolated static let menuBarHidden = Key<Bool>("menuBarHidden", default: false)

    /// Dock 图标是否隐藏
    nonisolated static let dockHidden = Key<Bool>("dockHidden", default: false)

    /// 强制英文符号功能 - 全局总开关
    nonisolated static let forceEnglishPunctuationEnabled = Key<Bool>(
        "forceEnglishPunctuationEnabled",
        default: false,
        suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!
    )

    /// 强制英文符号功能 - 启用的应用列表（存储 bundleId）
    nonisolated static let forceEnglishPunctuationApps = Key<Set<String>>(
    "forceEnglishPunctuationApps",
    default: [],
    suite: .init(suiteName: "group.top.ygsgdbd.TypeSwitch")!
    )


	/// App name matching rules (name pattern -> input method ID)
	nonisolated static let appNameMatchingRules = Key<[String: String]>("appNameMatchingRules", default: [:])

	/// Whether to show the HUD popup when switching input methods
	nonisolated static let showHUDOnSwitch = Key<Bool>("showHUDOnSwitch", default: true)
}
