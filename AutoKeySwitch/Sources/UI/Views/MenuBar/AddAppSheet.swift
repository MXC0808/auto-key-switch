import SwiftUI

/// Add application sheet
struct AddAppSheet: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var searchResults: [AppInfo] {
        let apps = viewModel.installedApps
        let filtered = searchText.isEmpty
            ? apps
            : apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        // Exclude apps already in rules list
        return filtered.filter { !viewModel.isAppInRulesList($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("添加应用")
                            .font(.headline)
                        Text("选择需要单独设置输入法的应用")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("完成") {
                        dismiss()
                    }
                    .controlSize(.small)
                    .keyboardShortcut(.cancelAction)
                    .focusable(false)
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索应用", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, 8)
                .background(DesignTokens.Colors.background.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                        .stroke(DesignTokens.Colors.divider.opacity(0.45), lineWidth: 1)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.xl)
            .padding(.bottom, DesignTokens.Spacing.lg)

            Divider()

            if viewModel.installedApps.isEmpty {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Spacer()
                    ProgressView()
                    Text("正在读取应用列表")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if searchResults.isEmpty {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Spacer()
                    Image(systemName: searchText.isEmpty ? "checkmark.circle" : "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "所有应用已在列表中" : "未找到匹配应用")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults) { app in
                            AddAppRow(app: app, onAdd: addApp)

                            if app.bundleId != searchResults.last?.bundleId {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
        }
        .background(DesignTokens.Colors.windowBackground)
        .frame(width: 500, height: 540)
        .task {
            await viewModel.forceRefreshInstalledApps()
        }
    }

    private func addApp(_ app: AppInfo) {
        viewModel.setInputMethod(for: app, to: "")
    }
}

/// Add app row
struct AddAppRow: View {
    let app: AppInfo
    let onAdd: (AppInfo) -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            app.icon
                .frame(width: DesignTokens.Sizes.iconLarge, height: DesignTokens.Sizes.iconLarge)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(app.name)
                    .font(DesignTokens.Typography.cardTitle)
                    .lineLimit(1)
                Text(app.bundleId)
                    .font(DesignTokens.Typography.cardSubtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { onAdd(app) }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .focusable(false)
            .opacity(isHovered ? 1 : 0.56)
            .help("添加 \(app.name)")
            .frame(width: 22)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                .fill(isHovered ? DesignTokens.Colors.hoverBackground : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                .stroke(
                    isHovered ? DesignTokens.Colors.selectionBorder.opacity(0.45) : Color.clear,
                    lineWidth: 1
                )
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onAdd(app) }
        .onHover { hovering in
            withAnimation(DesignTokens.Animation.fast) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AddAppSheet()
        .environmentObject(InputMethodManager.shared)
}
