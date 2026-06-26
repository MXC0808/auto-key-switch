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
				.background(DesignTokens.Colors.windowBackground)
		}
		.frame(minWidth: 860, minHeight: 560)
		.environmentObject(navigationVM)
		.toolbar {
			ToolbarItemGroup(placement: .primaryAction) {
				HStack(spacing: 10) {
					Image(systemName: "magnifyingglass")
						.foregroundStyle(.secondary)
						.font(.system(size: 18, weight: .regular))
					TextField(navigationVM.selection.searchPrompt, text: activeSearchBinding)
						.textFieldStyle(.plain)
						.frame(width: toolbarSearchWidth)
				}
				.padding(.horizontal, 18)
				.padding(.vertical, 10)
				.background(Color.white.opacity(0.72), in: Capsule())
				.overlay {
					Capsule()
						.strokeBorder(Color.secondary.opacity(0.10), lineWidth: 1)
				}
				.shadow(color: .black.opacity(0.035), radius: 12, x: 0, y: 3)
			}
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
			return 420
		case .memory:
			return 360
		case .preferences:
			return 300
		}
	}

}

#Preview {
	MainView()
		.environmentObject(InputMethodManager.shared)
}
