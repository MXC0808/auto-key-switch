#!/usr/bin/osascript
-- Punctuation Basic Test
-- Verifies that Chinese input method outputs English punctuation
-- Prerequisites: AutoKeySwitch is running, Accessibility permission granted

on run
    set testPassed to true
    set testResults to {}

    -- Activate TextEdit
    tell application "TextEdit"
        activate
        delay 0.5
        -- Create new document
        make new document
        delay 0.3
    end tell

    -- Switch to Chinese input method
    tell application "System Events"
        key code 49 using {control down} -- Ctrl+Space to toggle input method
        delay 0.5
    end tell

    -- Test comma key (keyCode 43)
    tell application "System Events"
        key code 43 -- comma
        delay 0.1
    end tell

    -- Test period key (keyCode 47)
    tell application "System Events"
        key code 47 -- period
        delay 0.1
    end tell

    -- Read TextEdit content
    tell application "TextEdit"
        set docContent to text of document 1
    end tell

    -- Verify: should see English punctuation ",." not Chinese "，。"
    if docContent contains "," then
        set end of testResults to "PASS: Comma outputs English ','"
    else
        set end of testResults to "FAIL: Comma did not output English ','"
        set testPassed to false
    end if

    if docContent contains "." then
        set end of testResults to "PASS: Period outputs English '.'"
    else
        set end of testResults to "FAIL: Period did not output English '.'"
        set testPassed to false
    end if

    -- Close document without saving
    tell application "TextEdit"
        close document 1 saving no
    end tell

    -- Output results
    set AppleScript's text item delimiters to linefeed
    return testResults as text
end run
