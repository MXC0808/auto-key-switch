import SwiftUI

struct InputMethodHUDView: View {
    let inputMethodName: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconBackgroundColor)
                    .frame(width: 20, height: 20)
                Image(systemName: "keyboard")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(iconForegroundColor)
            }

            Text(inputMethodName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 168, alignment: .leading)
        }
        .padding(.horizontal, 13)
        .frame(height: 38)
        .background(Color.clear)
        .accessibilityLabel("当前输入法：\(inputMethodName)")
    }

    private var iconBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    private var iconForegroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.76)
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.94) : Color.black.opacity(0.86)
    }
}

final class InputMethodHUDPanel: NSPanel {
    private var hideWorkItem: DispatchWorkItem?

    static func hudFrame(in visibleFrame: NSRect, contentSize: NSSize) -> NSRect {
        let width = max(116, min(ceil(contentSize.width), 220))
        let size = NSSize(width: width, height: 38)
        let origin = NSPoint(
            x: round(visibleFrame.midX - size.width / 2),
            y: round(visibleFrame.midY + 84)
        )

        return NSRect(origin: origin, size: size)
    }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 78),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    private func targetScreen() -> NSScreen? {
        NSApp.keyWindow?.screen ?? screen ?? NSScreen.screens.first ?? NSScreen.main
    }

    func show(inputMethodName: String) {
        hideWorkItem?.cancel()

        let visualEffectView = NSVisualEffectView()
        visualEffectView.state = .active
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1
        visualEffectView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.07).cgColor

        let hostingView = NSHostingView(rootView: InputMethodHUDView(inputMethodName: inputMethodName))
        hostingView.layout()
        let fittingSize = hostingView.fittingSize
        let screenFrame = targetScreen()?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? NSRect.zero
        let frame = Self.hudFrame(in: screenFrame, contentSize: fittingSize)

        visualEffectView.frame = NSRect(origin: .zero, size: frame.size)
        hostingView.frame = visualEffectView.bounds
        hostingView.autoresizingMask = [.width, .height]
        visualEffectView.addSubview(hostingView)

        contentView = visualEffectView

        setFrame(frame, display: true)
        #if DEBUG
        let centerDelta = abs(self.frame.midX - frame.midX)
        if centerDelta > 1 || self.frame.size != frame.size {
            print("HUD panel frame mismatch: actual=\(self.frame), expected=\(frame)")
        }
        #endif

        orderFrontRegardless()
        alphaValue = 1.0

        let workItem = DispatchWorkItem { [weak self] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self?.animator().alphaValue = 0
            } completionHandler: {
                Task { @MainActor [weak self] in
                    self?.orderOut(nil)
                }
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
}
