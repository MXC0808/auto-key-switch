import SwiftUI
import Defaults

struct MemoryDisplayApp: Identifiable {
    let app: AppInfo
    let isEnabled: Bool

    var id: String { app.bundleId }
}

/// Short-term memory configuration main interface
struct MemoryConfigView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Binding var searchText: String
    @State private var selectedApps: Set<String> = []
    @State private var showClearConfirmation = false
    @State private var showLimitAlert = false

    private var unifiedApps: [MemoryDisplayApp] {
        let runningApps = viewModel.runningApps.map { app in
            MemoryDisplayApp(app: app, isEnabled: viewModel.memoryEnabledApps.contains(app.bundleId))
        }
        let filtered = searchText.isEmpty
            ? runningApps
            : runningApps.filter { $0.app.name.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted {
            $0.app.name.localizedCaseInsensitiveCompare($1.app.name) == .orderedAscending
        }
    }

    private var visibleSelectedBundleIDs: Set<String> {
        Set(unifiedApps.map(\.app.bundleId)).intersection(selectedApps)
    }

    private var visibleSelectedCount: Int {
        visibleSelectedBundleIDs.count
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("应用记忆")
                            .font(.headline.weight(.semibold))
                        Text("让应用在切回前台时恢复上次输入法。")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, DesignTokens.Spacing.xs)

                    InspectorTable(
                        summary: "运行中应用",
                        actions: {
                            EmptyView()
                        },
                        columns: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                HStack(spacing: DesignTokens.Spacing.sm) {
                                    Color.clear
                                        .frame(width: DesignTokens.Sizes.iconLarge, height: 1)
                                    Text("应用")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("记忆状态")
                                    .frame(width: DesignTokens.Sizes.inspectorStatusWidth, alignment: .leading)
                                Text("启用")
                                    .frame(width: DesignTokens.Sizes.inspectorActionWidth, alignment: .center)
                            }
                        },
                        rows: {
                            if unifiedApps.isEmpty {
                                MemoryEmptyStateView(isSearching: !searchText.isEmpty)
                            } else {
                                ForEach(unifiedApps) { displayApp in
                                    VStack(spacing: 0) {
                                        MemoryAppRowView(
                                            app: displayApp.app,
                                            isEnabled: displayApp.isEnabled,
                                            isSelected: selectedApps.contains(displayApp.app.bundleId),
                                            onToggleSelection: {
                                                toggleSelection(for: displayApp.app)
                                            },
                                            onAdd: {
                                                addApp(displayApp.app)
                                            },
                                            onRemove: {
                                                viewModel.removeAppsFromMemory([displayApp.app])
                                                selectedApps.remove(displayApp.app.bundleId)
                                            }
                                        )

                                        if displayApp.id != unifiedApps.last?.id {
                                            Divider()
                                                .padding(.leading, 58)
                                        }
                                    }
                                }
                            }
                        }
                    )
                }
                .frame(maxWidth: DesignTokens.Sizes.contentWidth, alignment: .leading)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.top, 14)
                .padding(.bottom, 14)
            }

            MemoryBottomBar(
                appCount: unifiedApps.count,
                selectedCount: visibleSelectedCount,
                isClearDisabled: viewModel.memoryEnabledApps.isEmpty,
                isDeleteDisabled: visibleSelectedBundleIDs.isEmpty,
                onClear: { showClearConfirmation = true },
                onDelete: deleteSelectedApps
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .alert("已达最大数量限制（\(Constants.maxMemoryEnabledApps) 个）", isPresented: $showLimitAlert) {
            Button("确定", role: .cancel) {}
        }
        .confirmationDialog(
            "确定要清空所有记忆配置吗？",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("确认清空", role: .destructive) {
                viewModel.clearAllMemory()
                selectedApps.removeAll()
            }
        } message: {
            Text("此操作不可撤销")
        }
    }

    // MARK: - Actions

    private func addApp(_ app: AppInfo) {
        let success = viewModel.addAppToMemory(app)
        if !success {
            showLimitAlert = true
        }
    }

    private func toggleSelection(for app: AppInfo) {
        guard viewModel.memoryEnabledApps.contains(app.bundleId) else { return }
        if selectedApps.contains(app.bundleId) {
            selectedApps.remove(app.bundleId)
        } else {
            selectedApps.insert(app.bundleId)
        }
    }

    private func deleteSelectedApps() {
        let bundleIDsToRemove = visibleSelectedBundleIDs
        let toRemove = unifiedApps
            .map(\.app)
            .filter { bundleIDsToRemove.contains($0.bundleId) }
        viewModel.removeAppsFromMemory(toRemove)
        selectedApps.subtract(bundleIDsToRemove)
    }
}

private struct MemoryBottomBar: View {
    let appCount: Int
    let selectedCount: Int
    let isClearDisabled: Bool
    let isDeleteDisabled: Bool
    let onClear: () -> Void
    let onDelete: () -> Void

    private var selectionSummary: String {
        if selectedCount > 0 {
            return "\(appCount) 个应用  已选 \(selectedCount) 个"
        }
        return "\(appCount) 个应用"
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Text(selectionSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: DesignTokens.Spacing.lg)

            HStack(spacing: DesignTokens.Spacing.md) {
                Button(role: .destructive) {
                    onClear()
                } label: {
                    Image(systemName: "trash.slash")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.plain)
                .disabled(isClearDisabled)
                .foregroundStyle(isClearDisabled ? .tertiary : .secondary)
                .focusable(false)
                .help("清空全部记忆配置")
                .accessibilityLabel("清空全部记忆配置")

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.plain)
                .disabled(isDeleteDisabled)
                .foregroundStyle(isDeleteDisabled ? .tertiary : .secondary)
                .focusable(false)
                .help(isDeleteDisabled ? "移除记忆配置" : "移除选中的记忆配置")
                .accessibilityLabel("移除选中的记忆配置")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(maxWidth: DesignTokens.Sizes.contentWidth)
        .padding(.horizontal, 28)
        .padding(.vertical, 12)
        .fixedBottomBarStyle()
    }
}

private struct MemoryEmptyStateView: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: isSearching ? "magnifyingglass" : "app.dashed")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(isSearching ? "未找到运行中的匹配应用" : "暂无运行中的应用")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(isSearching ? "调整搜索关键词后再试。" : "打开应用后会出现在这里。")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

#Preview {
    MemoryConfigView(searchText: .constant(""))
        .environmentObject(InputMethodManager.shared)
        .frame(width: 500, height: 500)
}
