import SwiftUI
import AppKit
import Defaults

/// Short-term memory configuration main interface
struct MemoryConfigView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @State private var selectedApps: Set<String> = []
    @State private var showClearConfirmation = false
    @State private var showLimitAlert = false
    @State private var scrollTargetId: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            // 运行中应用添加区域
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("正在运行的应用")
                        .font(.headline)
                    Spacer()
                    if !viewModel.runningApps.isEmpty && viewModel.runningApps.count > 3 {
                        Text("右滑查看更多")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.runningApps.isEmpty {
                    HStack {
                        Image(systemName: "app.badge")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("暂无运行中的应用")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(DesignTokens.CornerRadius.lg)
                } else {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: DesignTokens.Spacing.md) {
                                    ForEach(viewModel.runningApps) { app in
                                        RunningAppCardView(app: app, onAdd: addApp)
                                            .id(app.bundleId)
                                    }
                                }
                                .padding(.vertical, DesignTokens.Spacing.xs)
                            }
                            .onChange(of: scrollTargetId) { targetId in
                                if let targetId {
                                    withAnimation(DesignTokens.Animation.normal) {
                                        proxy.scrollTo(targetId, anchor: .leading)
                                    }
                                    scrollTargetId = nil
                                }
                            }
                        }

                        if viewModel.runningApps.count > 3 {
                            Button(action: scrollForward) {
                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .foregroundStyle(.tint)
                                    .frame(width: 32, height: 44)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(DesignTokens.CornerRadius.lg)
                            }
                            .buttonStyle(.plain)
                            .focusable(false)
                        }
                    }
                }
            }
            .padding()

            Divider()

            // 已启用记忆列表
            MemoryEnabledListView(
                selectedApps: $selectedApps,
                onRemove: removeSelectedApps
            )

            // 底部工具栏
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

    private func scrollForward() {
        let apps = viewModel.runningApps
        if apps.count > 3 {
            scrollTargetId = apps[3].bundleId
        }
    }

    private func removeSelectedApps(_ apps: [AppInfo]) {
        let toRemove = apps.filter { selectedApps.contains($0.bundleId) }
        viewModel.removeAppsFromMemory(toRemove)
        selectedApps.removeAll()
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
