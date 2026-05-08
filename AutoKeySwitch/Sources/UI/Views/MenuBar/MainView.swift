import SwiftUI

/// Main window view with sidebar navigation
struct MainView: View {
	@EnvironmentObject private var viewModel: InputMethodManager
	@StateObject private var navigationVM = NavigationVM()
	@State private var asyncSelection: NavigationVM.NavItem = .appRules

	var body: some View {
		HStack(spacing: 0) {
			SidebarView()

			VStack(spacing: 0) {
				ContentHeaderView(item: asyncSelection)
				asyncSelection.getView()
				Spacer(minLength: 0)
			}
			.border(width: 1, edges: [.leading], color: Color(NSColor.separatorColor))
		}
		.frame(minWidth: 780, minHeight: 520)
		.environmentObject(navigationVM)
		.onChange(of: navigationVM.selection) { _ in
			withAnimation(DesignTokens.Animation.fast) {
				asyncSelection = navigationVM.selection
			}
		}
		.onAppear {
			asyncSelection = navigationVM.selection
		}
	}
}

extension NavigationVM.NavItem {
	@ViewBuilder
	func getView() -> some View {
		switch self {
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