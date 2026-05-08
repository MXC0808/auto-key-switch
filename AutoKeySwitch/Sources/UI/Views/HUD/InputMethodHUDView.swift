import SwiftUI

struct InputMethodHUDView: View {
    let inputMethodName: String

    var body: some View {
        Text(inputMethodName)
            .font(.title2)
            .fontWeight(.medium)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
    }
}

final class InputMethodHUDPanel: NSPanel {
    private var hideWorkItem: DispatchWorkItem?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
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

    func show(inputMethodName: String) {
        hideWorkItem?.cancel()

        // NSVisualEffectView with .active state to ensure blur material renders
        // correctly in a .nonactivatingPanel (inactive windows skip visual effects)
        let visualEffectView = NSVisualEffectView()
        visualEffectView.state = .active
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true

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
        let size = hostingView.fittingSize
        visualEffectView.frame = NSRect(origin: .zero, size: size)

        contentView = visualEffectView

        let screen = NSScreen.main
        let screenFrame = screen?.visibleFrame ?? NSRect.zero
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.midY + 100
        setFrameOrigin(NSPoint(x: x, y: y))

        orderFrontRegardless()
        alphaValue = 1.0

        let workItem = DispatchWorkItem { [weak self] in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self?.animator().alphaValue = 0
            } completionHandler: {
                self?.orderOut(nil)
            }
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
}