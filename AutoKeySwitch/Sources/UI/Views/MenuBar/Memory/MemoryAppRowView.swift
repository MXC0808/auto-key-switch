import SwiftUI
import Defaults

struct MemoryAppRowView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let app: AppInfo
    let isRunning: Bool
    let isEnabled: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onAdd: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false
    @State private var isAdded = false

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

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(app.name)
                    .font(DesignTokens.Typography.cardTitle)
                    .lineLimit(1)

                Text(lastMethodName.map { "上次: \($0)" } ?? "暂无记录")
                    .font(DesignTokens.Typography.cardSubtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isRunning {
                MemoryStatusBadge(title: "● 运行中", color: DesignTokens.Colors.statusRunning)
            } else if isEnabled {
                MemoryStatusBadge(title: "未运行", color: .secondary)
            }

            if isEnabled {
                MemoryStatusBadge(title: "已启用", color: .accentColor)
            } else if isRunning && !isAdded {
                Button(action: {
                    onAdd()
                    isAdded = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(DesignTokens.Colors.statusRunning)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel("启用 \(app.name) 的记忆功能")
            } else if isRunning && isAdded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }

            if isHovered && isEnabled {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(DesignTokens.Colors.destructive)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .focusable(false)
                .accessibilityLabel("移除 \(app.name) 的记忆功能")
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .fill(isSelected ? DesignTokens.Colors.selectionHighlight : (isHovered ? DesignTokens.Colors.hoverBackground : DesignTokens.Colors.background))
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                .stroke(isSelected ? DesignTokens.Colors.selectionBorder : DesignTokens.Colors.divider, lineWidth: 1)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
        }
        .opacity(isRunning ? 1.0 : 0.7)
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

private struct MemoryStatusBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.badgeText)
            .foregroundStyle(color)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(color.opacity(0.12))
            .cornerRadius(DesignTokens.CornerRadius.sm)
    }
}
