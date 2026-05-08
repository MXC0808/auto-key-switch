import AppKit
import Defaults
import Foundation
import os

struct AppConfiguration: Codable {
    var appInputMethodSettings: [String: String?]
    var defaultInputMethod: String?
    var memoryEnabledApps: Set<String>
    var forceEnglishPunctuationEnabled: Bool
    var forceEnglishPunctuationApps: Set<String>
}

enum ConfigurationExportService {
    private static let logger = Logger(subsystem: "com.autokeyswitch", category: "ConfigurationExportService")

    static func export() -> Data? {
        let config = AppConfiguration(
            appInputMethodSettings: Defaults[.appInputMethodSettings],
            defaultInputMethod: Defaults[.defaultInputMethod],
            memoryEnabledApps: Defaults[.memoryEnabledApps],
            forceEnglishPunctuationEnabled: Defaults[.forceEnglishPunctuationEnabled],
            forceEnglishPunctuationApps: Defaults[.forceEnglishPunctuationApps]
        )
        do {
            let data = try JSONEncoder().encode(config)
            logger.info("Configuration exported successfully")
            return data
        } catch {
            logger.error("Failed to export configuration: \(error.localizedDescription)")
            return nil
        }
    }

    static func `import`(from data: Data) throws {
        let config = try JSONDecoder().decode(AppConfiguration.self, from: data)
        Defaults[.appInputMethodSettings] = config.appInputMethodSettings
        Defaults[.defaultInputMethod] = config.defaultInputMethod
        Defaults[.memoryEnabledApps] = config.memoryEnabledApps
        Defaults[.forceEnglishPunctuationEnabled] = config.forceEnglishPunctuationEnabled
        Defaults[.forceEnglishPunctuationApps] = config.forceEnglishPunctuationApps
        logger.info("Configuration imported successfully")
    }
}
