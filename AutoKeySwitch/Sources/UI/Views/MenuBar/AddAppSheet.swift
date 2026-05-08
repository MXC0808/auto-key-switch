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
            // Header
            HStack {
                Text("添加应用")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索应用", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(DesignTokens.CornerRadius.md)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // App list
            if viewModel.installedApps.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    ProgressView("加载应用列表...")
                    Spacer()
                }
            } else if searchResults.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text(searchText.isEmpty ? "所有应用已在列表中" : "未找到匹配的应用")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List(searchResults) { app in
                    AddAppRow(app: app, onAdd: addApp)
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 400, height: 500)
        .task {
            await viewModel.forceRefreshInstalledApps()
        }
    }

    private func addApp(_ app: AppInfo) {
        // Set to use default input method (empty string = "Use Default" option)
        // This ensures the app appears in the main list as "configured"
        viewModel.setInputMethod(for: app, to: "")
    }
}

/// Add app row
struct AddAppRow: View {
    let app: AppInfo
    let onAdd: (AppInfo) -> Void

    var body: some View {
        HStack(spacing: 12) {
            app.icon
                .frame(width: 24, height: 24)
            Text(app.name)
                .frame(minWidth: 100, alignment: .leading)
            Spacer()
            Button(action: { onAdd(app) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onAdd(app) }
    }
}

#Preview {
    AddAppSheet()
        .environmentObject(InputMethodManager.shared)
}
