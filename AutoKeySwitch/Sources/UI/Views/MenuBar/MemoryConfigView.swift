import SwiftUI
import AppKit
import Defaults

struct MemoryDisplayApp: Identifiable {
    let app: AppInfo
    let isRunning: Bool
    let isEnabled: Bool

    var id: String { app.bundleId }
}

/// Short-term memory configuration main interface
struct MemoryConfigView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var selectedApps: Set<String> = []
    @State private var showClearConfirmation = false
    @State private var showLimitAlert = false
    @State private var searchText = ""

    private var unifiedApps: [MemoryDisplayApp] {
        let runningBundleIds = Set(viewModel.runningApps.map(\.bundleId))
        let runningApps = viewModel.runningApps.map { app in
            MemoryDisplayApp(app: app, isRunning: true, isEnabled: viewModel.memoryEnabledApps.contains(app.bundleId))
        }
        let inactiveEnabledApps = viewModel.memoryEnabledAppsInfo
            .filter { !runningBundleIds.contains($0.bundleId) }
            .map { app in
                MemoryDisplayApp(app: app, isRunning: false, isEnabled: true)
            }
        let combined = runningApps + inactiveEnabledApps
        let filtered = searchText.isEmpty
            ? combined
            : combined.filter { $0.app.name.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted { lhs, rhs in
            if lhs.isRunning != rhs.isRunning {
                return lhs.isRunning && !rhs.isRunning
            }
            return lhs.app.name.localizedCaseInsensitiveCompare(rhs.app.name) == .orderedAscending
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索运行中应用", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.background)

            // Info banner
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(.yellow)
                Text("记忆功能会记住应用上次使用的输入法，下次切换到该应用时自动恢复。")
                    .font(DesignTokens.Typography.badgeText)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color.accentColor.opacity(0.06))
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .padding(.horizontal)
            .padding(.top, DesignTokens.Spacing.sm)

            // Unified app list
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(unifiedApps) { displayApp in
                        MemoryAppRowView(
                            app: displayApp.app,
                            isRunning: displayApp.isRunning,
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
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }

            Divider()

            // Bottom toolbar
            MemoryToolbarView(
                selectedCount: selectedApps.count,
                onClearAll: { showClearConfirmation = true },
                onDeleteSelected: deleteSelectedApps
            )
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
        let toRemove = viewModel.memoryEnabledAppsInfo.filter { selectedApps.contains($0.bundleId) }
        viewModel.removeAppsFromMemory(toRemove)
        selectedApps.removeAll()
    }
}

#Preview {
    MemoryConfigView()
        .environmentObject(InputMethodManager.shared)
        .frame(width: 500, height: 500)
}
