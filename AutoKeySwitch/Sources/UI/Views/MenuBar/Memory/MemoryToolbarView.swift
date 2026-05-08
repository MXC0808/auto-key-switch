import SwiftUI
import Defaults

struct MemoryToolbarView: View {
    @EnvironmentObject private var viewModel: InputMethodManager
    let selectedCount: Int
    let onClearAll: () -> Void
    let onDeleteSelected: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button(action: onClearAll) {
                Image(systemName: "trash.slash")
                    .font(.title2)
            }
            .disabled(viewModel.memoryEnabledAppsInfo.isEmpty)
            .help("清空所有记忆配置")

            Spacer()

            if !viewModel.memoryEnabledAppsInfo.isEmpty {
                Text("共 \(viewModel.memoryEnabledAppsInfo.count) 个")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if selectedCount > 0 {
                Button(action: onDeleteSelected) {
                    Image(systemName: "trash")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .help("删除选中 \(selectedCount) 个")
                .focusable(false)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
