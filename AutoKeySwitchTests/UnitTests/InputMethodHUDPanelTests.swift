import AppKit
import Testing
@testable import AutoKeySwitch

@Suite("InputMethodHUDPanel Tests")
struct InputMethodHUDPanelTests {

    @Test("hudFrame uses content width and centers horizontally")
    func testHudFrameUsesContentWidthAndCentersHorizontally() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = InputMethodHUDPanel.hudFrame(
            in: visibleFrame,
            contentSize: NSSize(width: 160, height: 30)
        )

        #expect(frame.size == NSSize(width: 160, height: 38))
        #expect(abs(frame.midX - visibleFrame.midX) < 0.5)
    }

    @Test("hudFrame clamps capsule width to minimum")
    func testHudFrameClampsWidthToMinimum() {
        let visibleFrame = NSRect(x: 100, y: 50, width: 1000, height: 700)
        let frame = InputMethodHUDPanel.hudFrame(
            in: visibleFrame,
            contentSize: NSSize(width: 72, height: 30)
        )

        #expect(frame.size == NSSize(width: 116, height: 38))
        #expect(abs(frame.midX - visibleFrame.midX) < 0.5)
    }

    @Test("hudFrame clamps capsule width to maximum")
    func testHudFrameClampsWidthToMaximum() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = InputMethodHUDPanel.hudFrame(
            in: visibleFrame,
            contentSize: NSSize(width: 320, height: 30)
        )

        #expect(frame.size == NSSize(width: 220, height: 38))
        #expect(abs(frame.midX - visibleFrame.midX) < 0.5)
    }

    @Test("hudFrame centers in visible frame with non-zero and negative origin")
    func testHudFrameCentersInOffsetVisibleFrame() {
        let visibleFrame = NSRect(x: -1440, y: 40, width: 1200, height: 820)
        let frame = InputMethodHUDPanel.hudFrame(
            in: visibleFrame,
            contentSize: NSSize(width: 160, height: 30)
        )

        #expect(frame.size == NSSize(width: 160, height: 38))
        #expect(abs(frame.midX - visibleFrame.midX) < 0.5)
    }

    @Test("hudFrame rounds fractional fitting size and origin")
    func testHudFrameRoundsFractionalValues() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1439, height: 899)
        let frame = InputMethodHUDPanel.hudFrame(
            in: visibleFrame,
            contentSize: NSSize(width: 159.4, height: 30)
        )

        #expect(frame.size == NSSize(width: 160, height: 38))
        #expect(frame.origin.x.rounded() == frame.origin.x)
        #expect(frame.origin.y.rounded() == frame.origin.y)
        #expect(abs(frame.midX - visibleFrame.midX) <= 0.5)
    }

    @MainActor
    @Test("show reuses the HUD content view across updates")
    func testShowReusesContentViewAcrossUpdates() {
        let panel = InputMethodHUDPanel()

        panel.show(inputMethodName: "ABC")
        let firstContentView = panel.contentView

        panel.show(inputMethodName: "拼音")
        let secondContentView = panel.contentView

        #expect(firstContentView === secondContentView)
        panel.orderOut(nil)
    }
}
