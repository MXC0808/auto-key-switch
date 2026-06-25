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
    @State private var selectedApps: Set<String> = []
    @State private var showClearConfirmation = false
    @State private var showLimitAlert = false

    private var searchText: String { "" }

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

    var body: some View {
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
                    summary: "\(unifiedApps.count) 个运行中应用" + (selectedApps.isEmpty ? "" : " · 已选 \(selectedApps.count) 个"),
                    actions: {
                        if !viewModel.memoryEnabledAppsInfo.isEmpty {
                            Button(role: .destructive, action: { showClearConfirmation = true }) {
                                Image(systemName: "trash.slash")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            .focusable(false)
                            .help("清空全部记忆配置")
                            .accessibilityLabel("清空全部记忆配置")
                        }

                        if selectedApps.count > 0 {
                            Button(role: .destructive, action: deleteSelectedApps) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            .focusable(false)
                            .help("移除选中的记忆配置")
                            .accessibilityLabel("移除选中的记忆配置")
                        }
                    },
                    columns: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Text("应用")
                            Spacer()
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
                )
            }
            .frame(maxWidth: DesignTokens.Sizes.contentWidth, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.lg)
        }
        .alert("已达最大数量限制（20 个）", isPresented: $showLimitAlert) {
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
        let toRemove = viewModel.runningApps.filter { selectedApps.contains($0.bundleId) }
        viewModel.removeAppsFromMemory(toRemove)
        selectedApps.removeAll()
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
    MemoryConfigView()
        .environmentObject(InputMethodManager.shared)
        .frame(width: 500, height: 500)
}
