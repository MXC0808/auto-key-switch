import Testing
@testable import AutoKeySwitch

@Suite("KeyboardLayoutMapper Tests")
struct KeyboardLayoutMapperTests {

    // MARK: - ULM-001: Fallback mappings completeness

    @Test("Fallback mappings contain all 18 punctuation keys")
    func testFallbackMappingsComplete() {
        let mappings = KeyboardLayoutMapper.fallbackMappings
        #expect(mappings.count == 18)

        for keyCode in KeyboardLayoutMapper.punctuationKeyCodes {
            #expect(mappings[keyCode] != nil, "Key code \(keyCode) should have a fallback mapping")
            #expect(!mappings[keyCode]!.normal.isEmpty, "Key code \(keyCode) normal should not be empty")
            #expect(!mappings[keyCode]!.shifted.isEmpty, "Key code \(keyCode) shifted should not be empty")
        }
    }

    // MARK: - ULM-002: Fallback mappings correctness

    @Test("Comma key maps correctly", arguments: [UInt16]([43]))
    func testSpecificMappings(keyCode: UInt16) {
        let mappings = KeyboardLayoutMapper.fallbackMappings
        #expect(mappings[keyCode] != nil)
    }

    @Test("Comma key mapping")
    func testCommaMapping() {
        let mapping = KeyboardLayoutMapper.fallbackMappings[43]
        #expect(mapping?.normal == ",")
        #expect(mapping?.shifted == "<")
    }

    @Test("Period key mapping")
    func testPeriodMapping() {
        let mapping = KeyboardLayoutMapper.fallbackMappings[47]
        #expect(mapping?.normal == ".")
        #expect(mapping?.shifted == ">")
    }

    @Test("Semicolon key mapping")
    func testSemicolonMapping() {
        let mapping = KeyboardLayoutMapper.fallbackMappings[41]
        #expect(mapping?.normal == ";")
        #expect(mapping?.shifted == ":")
    }

    @Test("Quote key mapping")
    func testQuoteMapping() {
        let mapping = KeyboardLayoutMapper.fallbackMappings[39]
        #expect(mapping?.normal == "'")
        #expect(mapping?.shifted == "\"")
    }

    @Test("Bracket key mappings")
    func testBracketMappings() {
        #expect(KeyboardLayoutMapper.fallbackMappings[33]?.normal == "[")
        #expect(KeyboardLayoutMapper.fallbackMappings[33]?.shifted == "{")
        #expect(KeyboardLayoutMapper.fallbackMappings[30]?.normal == "]")
        #expect(KeyboardLayoutMapper.fallbackMappings[30]?.shifted == "}")
    }

    @Test("Backslash key mapping")
    func testBackslashMapping() {
        let mapping = KeyboardLayoutMapper.fallbackMappings[42]
        #expect(mapping?.normal == "\\")
        #expect(mapping?.shifted == "|")
    }

    @Test("Backtick key mapping")
    func testBacktickMapping() {
        let mapping = KeyboardLayoutMapper.fallbackMappings[50]
        #expect(mapping?.normal == "`")
        #expect(mapping?.shifted == "~")
    }

    // MARK: - ULM-003: Shifted values for number keys are symbols

    @Test("Number key shifted values are symbols, not digits")
    func testShiftedValuesAreSymbols() {
        let numberKeyCodes: [UInt16] = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
        let expectedShifted = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]

        for (index, keyCode) in numberKeyCodes.enumerated() {
            let mapping = KeyboardLayoutMapper.fallbackMappings[keyCode]
            #expect(mapping != nil, "Key code \(keyCode) should have a mapping")
            #expect(mapping?.shifted == expectedShifted[index],
                    "Key code \(keyCode) shifted should be '\(expectedShifted[index])', got '\(mapping?.shifted ?? "nil")'")
        }
    }

    // MARK: - ULM-004: Dynamic getMappings returns all punctuation keys

    @Test("getMappings returns all punctuation key mappings")
    @MainActor
    func testAllPunctuationKeysMapped() {
        let mappings = KeyboardLayoutMapper.getMappings()
        for keyCode in KeyboardLayoutMapper.punctuationKeyCodes {
            #expect(mappings[keyCode] != nil, "Key code \(keyCode) should have a mapping via getMappings()")
        }
    }

    // MARK: - ULM-005: Non-punctuation key returns nil

    @Test("Non-punctuation key returns nil")
    @MainActor
    func testNonPunctuationKeyReturnsNil() {
        // Key code 0 = 'A' key
        let mapping = KeyboardLayoutMapper.getMapping(forKeyCode: 0)
        #expect(mapping == nil)

        // Key code 6 = 'Z' key
        let mapping2 = KeyboardLayoutMapper.getMapping(forKeyCode: 6)
        #expect(mapping2 == nil)
    }

    // MARK: - ULM-006: Rebuild preserves mapping count

    @Test("Rebuild mappings preserves mapping count")
    @MainActor
    func testRebuildMappingsPreservesCount() {
        let initialMappings = KeyboardLayoutMapper.getMappings()
        let initialCount = initialMappings.count

        KeyboardLayoutMapper.rebuildMappings()

        let rebuiltMappings = KeyboardLayoutMapper.getMappings()
        #expect(rebuiltMappings.count == initialCount)
    }
}
