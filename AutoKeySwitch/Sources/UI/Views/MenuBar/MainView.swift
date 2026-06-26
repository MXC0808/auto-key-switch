import SwiftUI

/// Main window with sidebar navigation.
struct MainView: View {
	@EnvironmentObject private var viewModel: InputMethodManager
	@StateObject private var navigationVM = NavigationVM()
	@State private var appRulesSearchText = ""
	@State private var memorySearchText = ""
	@State private var preferencesSearchText = ""

	var body: some View {
		HStack(spacing: 0) {
			SidebarView()

			detailContent
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
				.background {
					DesignTokens.Colors.contentBackground
						.ignoresSafeArea(.container, edges: .top)
				}
		}
		.frame(minWidth: 860, minHeight: 560)
		.environmentObject(navigationVM)
		.overlay(alignment: .topTrailing) {
			ToolbarSearchField(
				prompt: navigationVM.selection.searchPrompt,
				text: activeSearchBinding,
				width: toolbarSearchWidth
			)
			.padding(.top, 14)
			.padding(.trailing, 44)
			.ignoresSafeArea(.container, edges: .top)
		}
	}

	@ViewBuilder
	private var detailContent: some View {
		switch navigationVM.selection {
		case .appRules:
			AppSettingsTab(searchText: $appRulesSearchText)
		case .memory:
			MemoryConfigView(searchText: $memorySearchText)
		case .preferences:
			PreferencesTab(searchText: $preferencesSearchText)
		}
	}

	private var activeSearchBinding: Binding<String> {
		switch navigationVM.selection {
		case .appRules:
			return $appRulesSearchText
		case .memory:
			return $memorySearchText
		case .preferences:
			return $preferencesSearchText
		}
	}

	private var toolbarSearchWidth: CGFloat {
		switch navigationVM.selection {
		case .appRules:
			return 240
		case .memory:
			return 220
		case .preferences:
			return 200
		}
	}
}

private struct ToolbarSearchField: View {
	let prompt: String
	@Binding var text: String
	let width: CGFloat

	var body: some View {
		HStack(spacing: 7) {
			Image(systemName: "magnifyingglass")
				.font(.system(size: 12, weight: .medium))
				.foregroundStyle(.secondary)

			TextField(prompt, text: $text)
				.textFieldStyle(.plain)
				.font(.system(size: 13))
				.lineLimit(1)

			if !text.isEmpty {
				Button {
					text = ""
				} label: {
					Image(systemName: "xmark.circle.fill")
						.font(.system(size: 12, weight: .medium))
						.symbolRenderingMode(.hierarchical)
						.foregroundStyle(.secondary)
				}
				.buttonStyle(.plain)
				.focusable(false)
				.help("清除搜索")
				.accessibilityLabel("清除搜索")
			}
		}
		.frame(width: width, height: 26)
		.padding(.horizontal, 10)
		.background(
			DesignTokens.Colors.contentBackground.opacity(0.74),
			in: RoundedRectangle(cornerRadius: 7, style: .continuous)
		)
		.overlay {
			RoundedRectangle(cornerRadius: 7, style: .continuous)
				.strokeBorder(DesignTokens.Colors.divider.opacity(0.20), lineWidth: 1)
		}
	}
}

#Preview {
	MainView()
		.environmentObject(InputMethodManager.shared)
}
