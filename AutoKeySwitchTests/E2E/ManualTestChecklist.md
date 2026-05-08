# Manual Test Checklist — Force English Punctuation

## Prerequisites
- [ ] AutoKeySwitch app is running
- [ ] Accessibility permission granted (System Settings > Privacy & Security > Accessibility)
- [ ] "Force English Punctuation" toggle is ON
- [ ] Chinese input method available (e.g., ABC - Pinyin)

---

## TC-001: Basic Punctuation Conversion

**Scenario**: Type punctuation keys under Chinese input method

| Key | Expected Output |
|-----|----------------|
| `,` (comma) | `,` |
| `.` (period) | `.` |
| `;` (semicolon) | `;` |
| `'` (quote) | `'` |
| `[` (left bracket) | `[` |
| `]` (right bracket) | `]` |
| `\` (backslash) | `\` |
| `` ` `` (backtick) | `` ` `` |

**Steps**:
1. Switch to Chinese input method
2. Open TextEdit or any text editor
3. Type each punctuation key
4. Verify each outputs English punctuation

**Result**: [ ] Pass [ ] Fail

---

## TC-002: Shift+Number Symbol Output

**Scenario**: Type Shift+number keys under Chinese input method

| Key | Expected Output |
|-----|----------------|
| Shift+1 | `!` |
| Shift+2 | `@` |
| Shift+3 | `#` |
| Shift+4 | `$` |
| Shift+5 | `%` |
| Shift+6 | `^` |
| Shift+7 | `&` |
| Shift+8 | `*` |
| Shift+9 | `(` |
| Shift+0 | `)` |

**Steps**:
1. Switch to Chinese input method
2. Open text editor
3. Hold Shift and press each number key
4. Verify each outputs English symbol

**Result**: [ ] Pass [ ] Fail

---

## TC-003: Bracket and Shift+Bracket Output

| Key | Expected Output |
|-----|----------------|
| `[` | `[` |
| `]` | `]` |
| Shift+`[` | `{` |
| Shift+`]` | `}` |

**Steps**:
1. Switch to Chinese input method
2. Type `[` and `]` keys
3. Hold Shift and type `[` and `]`
4. Verify outputs

**Result**: [ ] Pass [ ] Fail

---

## TC-004: App Switching联动

**Scenario**: Feature activates/deactivates when switching between configured/unconfigured apps

**Steps**:
1. Enable "Force English Punctuation" for TextEdit in app rules
2. Disable for Safari (or leave unconfigured)
3. Switch to TextEdit with Chinese input → type comma → should output `,`
4. Switch to Safari with Chinese input → type comma → should output Chinese `，`
5. Switch back to TextEdit → type comma → should output `,`

**Result**: [ ] Pass [ ] Fail

---

## TC-005: Global Toggle联动

**Scenario**: Global on/off toggle affects punctuation replacement

**Steps**:
1. Turn ON "Force English Punctuation" global toggle
2. Switch to Chinese input → type comma → should output `,`
3. Turn OFF "Force English Punctuation" global toggle
4. Type comma → should output Chinese `，`
5. Verify app rule checkboxes are grayed out when toggle is OFF

**Result**: [ ] Pass [ ] Fail

---

## TC-006: Edge Cases

| Case | Expected Behavior |
|------|-------------------|
| No Accessibility permission | App shows permission request prompt |
| Multiple modifier keys (Ctrl+Shift+comma) | No interference with replacement logic |
| Rapid consecutive key presses | All punctuation correctly replaced |
| Chinese input composing state | Punctuation replacement does not interfere with composition |

**Result**: [ ] Pass [ ] Fail

---

## TC-007: Different Input Methods

| Input Method | Expected Behavior |
|-------------|-------------------|
| System Pinyin (ABC - Pinyin) | Punctuation replaced |
| Sogou Pinyin | Punctuation replaced |
| Japanese input (Romaji) | Punctuation replaced |
| Korean input | Punctuation replaced |
| English input (ABC) | No replacement (already English) |

**Steps**:
1. Switch to each input method
2. Type comma and period
3. Verify CJKV input methods get English punctuation
4. Verify English input is unaffected

**Result**: [ ] Pass [ ] Fail

---

## TC-008: Backtick and Backslash Variants

| Key | Expected Output |
|-----|----------------|
| `` ` `` (backtick) | `` ` `` |
| `\` (backslash) | `\` |
| Shift+`` ` `` | `~` |
| Shift+`\` | `\|` |

**Result**: [ ] Pass [ ] Fail

---

## Test Summary

| TC | Description | Result |
|----|-------------|--------|
| TC-001 | Basic punctuation conversion | |
| TC-002 | Shift+number symbols | |
| TC-003 | Bracket variants | |
| TC-004 | App switching联动 | |
| TC-005 | Global toggle联动 | |
| TC-006 | Edge cases | |
| TC-007 | Different input methods | |
| TC-008 | Backtick and backslash | |

**Tester**: ________________  **Date**: ________________

**Overall**: [ ] All Pass [ ] Has Failures
