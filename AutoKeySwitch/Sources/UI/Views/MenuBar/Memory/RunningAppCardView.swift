import SwiftUI
import Defaults

struct RunningAppCardView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let app: AppInfo
    let onAdd: (AppInfo) -> Void

    @State private var isHovered = false
    @State private var isAdded = false

    var isAlreadyAdded: Bool {
        viewModel.memoryEnabledApps.contains(app.bundleId)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconXL, height: DesignTokens.Sizes.iconXL)

            Text(app.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 60)

            Button(action: {
                onAdd(app)
                isAdded = true
            }) {
                Image(systemName: isAlreadyAdded || isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isAlreadyAdded || isAdded ? .green : .blue)
            }
            .buttonStyle(.plain)
            .disabled(isAlreadyAdded || isAdded)
            .focusable(false)
        }
        .padding(DesignTokens.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(isHovered ? Color.blue.opacity(0.08) : Color(NSColor.controlBackgroundColor))
        }
        .animation(DesignTokens.Animation.fast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
