#!/usr/bin/osascript
-- Shift+Number Test
-- Verifies that Shift+number keys output English symbols under Chinese input
-- Prerequisites: AutoKeySwitch is running, Accessibility permission granted

on run
    set testPassed to true
    set testResults to {}

    -- Activate TextEdit
    tell application "TextEdit"
        activate
        delay 0.5
        make new document
        delay 0.3
    end tell

    -- Switch to Chinese input method
    tell application "System Events"
        key code 49 using {control down}
        delay 0.5
    end tell

    -- Type Shift+1 through Shift+0
    set shiftNumbers to {"!", "@", "#", "$", "%", "^", "&", "*", "(", ")"}
    set keyCodes to {18, 19, 20, 21, 23, 22, 26, 28, 25, 29}

    repeat with i from 1 to length of keyCodes
        tell application "System Events"
            key code (item i of keyCodes) using {shift down}
            delay 0.1
        end tell
    end repeat

    -- Read TextEdit content
    tell application "TextEdit"
        set docContent to text of document 1
    end tell

    -- Verify each symbol
    repeat with i from 1 to length of shiftNumbers
        set expected to item i of shiftNumbers
        if docContent contains expected then
            set end of testResults to "PASS: Shift+" & i & " outputs '" & expected & "'"
        else
            set end of testResults to "FAIL: Shift+" & i & " did not output '" & expected & "'"
            set testPassed to false
        end if
    end repeat

    -- Close document without saving
    tell application "TextEdit"
        close document 1 saving no
    end tell

    set AppleScript's text item delimiters to linefeed
    return testResults as text
end run
