import SwiftUI
import Defaults

struct MemoryEnabledListView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Binding var selectedApps: Set<String>

    let onRemove: ([AppInfo]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("已启用记忆 (\(viewModel.memoryEnabledAppsInfo.count))")
                    .font(.headline)
                Spacer()

                if !selectedApps.isEmpty {
                    Button(action: {
                        selectedApps.removeAll()
                    }) {
                        Text("取消选择")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(Color(NSColor.controlBackgroundColor))

            if viewModel.memoryEnabledAppsInfo.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "lightbulb")
                            .font(.title2)
                            .foregroundStyle(.yellow)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("还没有启用任何应用的记忆功能")
                                .font(.subheadline)
                            Text("从上方运行中的应用添加")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.08))
                    .cornerRadius(DesignTokens.CornerRadius.lg)
                }
                .padding()
                Spacer()
            } else {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Text("应用")
                        .frame(minWidth: 100 + DesignTokens.Sizes.iconLarge + DesignTokens.Spacing.md, alignment: .leading)
                    Spacer()
                    Text("上次输入法")
                        .frame(alignment: .trailing)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DesignTokens.Spacing.md + DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.xs)

                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(viewModel.memoryEnabledAppsInfo, id: \.bundleId) { app in
                            MemoryAppRowView(
                                app: app,
                                isSelected: selectedApps.contains(app.bundleId),
                                onToggleSelection: {
                                    if selectedApps.contains(app.bundleId) {
                                        selectedApps.remove(app.bundleId)
                                    } else {
                                        selectedApps.insert(app.bundleId)
                                    }
                                },
                                onRemove: {
                                    viewModel.removeAppsFromMemory([app])
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                }
            }
        }
    }
}
