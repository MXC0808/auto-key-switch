import SwiftUI

/// Content area header showing current page icon, app name, and page name
struct ContentHeaderView: View {
	let item: NavigationVM.NavItem

	var body: some View {
		HStack {
			Image(systemName: item.icon)
				.font(DesignTokens.Typography.contentHeaderIcon)
				.opacity(0.8)
				.frame(width: 20, height: 20)
				.accessibilityLabel("当前页面: \(item.displayName)")

			VStack(alignment: .leading, spacing: 0) {
				Text("AutoKeySwitch")
					.font(DesignTokens.Typography.contentHeaderTitle)
					.opacity(0.8)

				Text(item.displayName)
					.font(DesignTokens.Typography.contentHeaderSubtitle)
					.opacity(0.6)
			}

			Spacer()
		}
		.frame(height: DesignTokens.Sidebar.headerHeight)
		.padding(.horizontal)
		.border(width: 1, edges: [.bottom], color: Color(NSColor.separatorColor))
	}
}