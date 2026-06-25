import SwiftUI

/// Main window with sidebar navigation.
struct MainView: View {
	@EnvironmentObject private var viewModel: InputMethodManager
	@StateObject private var navigationVM = NavigationVM()

	var body: some View {
		HStack(spacing: 0) {
			SidebarView()

			detailContent
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
				.background(DesignTokens.Colors.windowBackground)
		}
		.frame(minWidth: 860, minHeight: 560)
		.environmentObject(navigationVM)
	}

	@ViewBuilder
	private var detailContent: some View {
		switch navigationVM.selection {
		case .appRules:
			AppSettingsTab()
		case .memory:
			MemoryConfigView()
		case .preferences:
			PreferencesTab()
		}
	}
}

#Preview {
	MainView()
		.environmentObject(InputMethodManager.shared)
}
