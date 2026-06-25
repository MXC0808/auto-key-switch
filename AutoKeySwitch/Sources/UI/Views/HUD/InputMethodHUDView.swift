import SwiftUI

struct InputMethodHUDView: View {
    let inputMethodName: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: "keyboard")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("输入法已切换")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(inputMethodName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.clear)
        .accessibilityLabel("当前输入法：\(inputMethodName)")
    }
}

final class InputMethodHUDPanel: NSPanel {
    private var hideWorkItem: DispatchWorkItem?

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
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    func show(inputMethodName: String) {
        hideWorkItem?.cancel()

        // NSVisualEffectView with .active state to ensure blur material renders
        // correctly in a .nonactivatingPanel (inactive windows skip visual effects)
        let visualEffectView = NSVisualEffectView()
        visualEffectView.state = .active
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 14
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1
        visualEffectView.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.12).cgColor

        let hostingView = NSHostingView(rootView: InputMethodHUDView(inputMethodName: inputMethodName))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.setContentHuggingPriority(.required, for: .horizontal)
        hostingView.setContentHuggingPriority(.required, for: .vertical)

        visualEffectView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
        ])

        hostingView.layout()
        let fittingSize = hostingView.fittingSize
        let size = NSSize(width: max(260, min(fittingSize.width, 420)), height: 68)
        visualEffectView.frame = NSRect(origin: .zero, size: size)

        contentView = visualEffectView

        let screen = NSScreen.main
        let screenFrame = screen?.visibleFrame ?? NSRect.zero
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.midY + 84
        setFrameOrigin(NSPoint(x: x, y: y))

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
