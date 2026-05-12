import Testing
import Foundation
import Defaults
@testable import AutoKeySwitch

@Suite("ConfigurationExportService Tests")
struct ConfigurationExportServiceTests {

    private func setupKnownDefaults() -> (
        appSettings: [String: String?],
        defaultIM: String?,
        memoryApps: Set<String>,
        punctuationEnabled: Bool,
        punctuationApps: Set<String>
    ) {
        let appSettings: [String: String?] = ["com.test.app": "com.apple.keylayout.ABC"]
        let defaultIM: String? = "com.apple.keylayout.US"
        let memoryApps: Set<String> = ["com.test.memory"]
        let punctuationEnabled = true
        let punctuationApps: Set<String> = ["com.test.punct"]

        Defaults[.appInputMethodSettings] = appSettings
        Defaults[.defaultInputMethod] = defaultIM
        Defaults[.memoryEnabledApps] = memoryApps
        Defaults[.forceEnglishPunctuationEnabled] = punctuationEnabled
        Defaults[.forceEnglishPunctuationApps] = punctuationApps

        return (appSettings, defaultIM, memoryApps, punctuationEnabled, punctuationApps)
    }

    @Test("export() produces valid JSON data")
    func testExportProducesValidJSON() {
        _ = setupKnownDefaults()

        let data = ConfigurationExportService.export()
        #expect(data != nil)

        let parsed = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        #expect(parsed != nil)
        #expect(parsed?["defaultInputMethod"] as? String == "com.apple.keylayout.US")
        #expect(parsed?["forceEnglishPunctuationEnabled"] as? Bool == true)
    }

    @Test("Round-trip export then import preserves all settings")
    func testRoundTrip() throws {
        let original = setupKnownDefaults()

        guard let data = ConfigurationExportService.export() else {
            Issue.record("export() returned nil")
            return
        }

        // Clear current defaults
        Defaults[.appInputMethodSettings] = [:]
        Defaults[.defaultInputMethod] = nil
        Defaults[.memoryEnabledApps] = []
        Defaults[.forceEnglishPunctuationEnabled] = false
        Defaults[.forceEnglishPunctuationApps] = []

        try ConfigurationExportService.import(from: data)

        #expect(Defaults[.defaultInputMethod] == original.defaultIM)
        #expect(Defaults[.memoryEnabledApps] == original.memoryApps)
        #expect(Defaults[.forceEnglishPunctuationEnabled] == original.punctuationEnabled)
        #expect(Defaults[.forceEnglishPunctuationApps] == original.punctuationApps)
    }

    @Test("import with invalid JSON throws error")
    func testImportInvalidJSON() {
        let invalidData = "not json".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            try ConfigurationExportService.import(from: invalidData)
        }
    }

    @Test("import with empty config succeeds")
    func testImportEmptyConfig() throws {
        let emptyConfig = AppConfiguration(
            appInputMethodSettings: [:],
            defaultInputMethod: nil,
            memoryEnabledApps: [],
            forceEnglishPunctuationEnabled: false,
            forceEnglishPunctuationApps: []
        )
        let data = try JSONEncoder().encode(emptyConfig)

        try ConfigurationExportService.import(from: data)

        #expect(Defaults[.defaultInputMethod] == nil)
        #expect(Defaults[.memoryEnabledApps].isEmpty)
    }

    @Test("import with unknown fields succeeds")
    func testImportWithUnknownFields() throws {
        // Simulate a future export that includes extra fields
        let jsonString = """
        {
            "appInputMethodSettings": {},
            "defaultInputMethod": null,
            "memoryEnabledApps": [],
            "forceEnglishPunctuationEnabled": false,
            "forceEnglishPunctuationApps": [],
            "futureFeature": "should be ignored"
        }
        """
        let data = jsonString.data(using: .utf8)!

        // Codable by default ignores unknown keys, so this should not throw
        try ConfigurationExportService.import(from: data)
        #expect(Defaults[.defaultInputMethod] == nil)
    }
}
