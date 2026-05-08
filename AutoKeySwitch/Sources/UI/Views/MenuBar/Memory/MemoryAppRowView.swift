import SwiftUI
import Defaults

struct MemoryAppRowView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let app: AppInfo
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    var lastMethodName: String? {
        guard let lastId = viewModel.lastInputMethodStates[app.bundleId],
              let method = viewModel.inputMethods.first(where: { $0.id == lastId }) else {
            return nil
        }
        return method.name
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconLarge, height: DesignTokens.Sizes.iconLarge)

            Text(app.name)
                .frame(minWidth: 100, alignment: .leading)

            Spacer()

            if let name = lastMethodName {
                Text("上次: \(name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("暂无记录")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .focusable(false)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(isSelected ? DesignTokens.Colors.selectionHighlight : (isHovered ? DesignTokens.Colors.hoverBackground : .clear))
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
        }
        .animation(DesignTokens.Animation.fast, value: isSelected)
        .animation(DesignTokens.Animation.fast, value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleSelection()
        }
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}
