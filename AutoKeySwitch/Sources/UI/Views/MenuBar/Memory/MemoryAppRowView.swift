import SwiftUI
import Defaults

struct MemoryAppRowView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let app: AppInfo
    let isEnabled: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onAdd: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    var lastMethodName: String? {
        guard let lastId = viewModel.lastInputMethodStates[app.bundleId],
              let method = viewModel.inputMethods.first(where: { $0.id == lastId }) else {
            return nil
        }
        return method.name
    }

    private var detailText: String {
        if let lastMethodName {
            return "上次使用 \(lastMethodName)"
        }
        return isEnabled ? "等待离开应用后记录输入法" : "开启后记录离开时的输入法"
    }

    private var statusText: String {
        if lastMethodName != nil { return "已记录" }
        if isEnabled { return "等待记录" }
        return "未启用"
    }

    private var statusColor: Color {
        if lastMethodName != nil { return DesignTokens.Colors.statusRunning }
        if isEnabled { return Color.secondary }
        return Color.secondary.opacity(0.72)
    }

    private var memoryBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                if newValue {
                    onAdd()
                } else {
                    onRemove()
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconLarge, height: DesignTokens.Sizes.iconLarge)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(app.name)
                    .font(DesignTokens.Typography.cardTitle)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Circle()
                        .fill(statusColor.opacity(isEnabled ? 0.85 : 0.35))
                        .frame(width: 6, height: 6)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

                Text(detailText)
                    .font(DesignTokens.Typography.cardSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: DesignTokens.Sizes.inspectorStatusWidth, alignment: .leading)

            Toggle("", isOn: memoryBinding)
                .toggleStyle(MinimalSwitchToggleStyle())
                .labelsHidden()
                .focusable(false)
                .help(isEnabled ? "关闭 \(app.name) 的记忆功能" : "启用 \(app.name) 的记忆功能")
                .accessibilityLabel(isEnabled ? "关闭 \(app.name) 的记忆功能" : "启用 \(app.name) 的记忆功能")
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(width: DesignTokens.Sizes.inspectorActionWidth, alignment: .center)
        }
        .inspectorRowStyle(isSelected: isSelected, isHovered: isHovered)
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
