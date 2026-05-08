import SwiftUI
import VisualEffects

/// Sidebar navigation with grouped items
struct SidebarView: View {
	@EnvironmentObject private var navigationVM: NavigationVM

	var body: some View {
		ZStack {
			VisualEffectBlur(
				material: .sidebar,
				blendingMode: .behindWindow,
				state: .followsWindowActiveState
			)

			VStack(spacing: DesignTokens.Spacing.lg) {
				ForEach(NavigationVM.grouped, id: \.id) { group in
					VStack(spacing: DesignTokens.Spacing.xs) {
						if !group.title.isEmpty {
							HStack {
								Text(group.title)
									.font(DesignTokens.Typography.sidebarGroupTitle)
									.opacity(0.6)
								Spacer()
							}
							.padding(.leading, 20)
							.padding(.bottom, 2)
						}

						ForEach(group.items) { item in
							NavItemRow(
								item: item,
								isActive: navigationVM.selection == item,
								action: { navigationVM.selection = item }
							)
							.keyboardShortcut(item.shortcut, modifiers: .command)
						}
					}
				}

				Spacer()

				Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.4")")
					.opacity(0.5)
					.font(DesignTokens.Typography.sidebarVersion)
			}
			.padding(.top, DesignTokens.Sidebar.topPadding)
			.padding(.vertical)
		}
		.frame(width: DesignTokens.Sidebar.width)
	}
}

/// Sidebar navigation item row with icon + text + selection highlight
struct NavItemRow: View {
	let item: NavigationVM.NavItem
	let isActive: Bool
	let action: () -> Void

	@State private var isPressed = false

	var body: some View {
		HStack {
			Image(systemName: item.icon)
				.font(.system(size: DesignTokens.Sidebar.iconSize, weight: .medium))
				.frame(width: DesignTokens.Sidebar.iconSize, height: DesignTokens.Sidebar.iconSize)
				.opacity(0.9)

			Text(item.displayName)
				.lineLimit(1)

			Spacer()
		}
		.padding(.leading, DesignTokens.Spacing.md)
		.padding(.trailing, DesignTokens.Spacing.xs)
		.padding(.vertical, DesignTokens.Spacing.sm)
		.frame(maxWidth: .infinity)
		.background(
			isPressed ? DesignTokens.Colors.sidebarPressedBackground :
			isActive ? DesignTokens.Colors.sidebarActiveBackground :
			Color.clear
		)
		.animation(DesignTokens.Animation.fast, value: isActive)
		.foregroundColor(Color.primary)
		.clipShape(RoundedRectangle(cornerRadius: DesignTokens.Sidebar.cornerRadius))
		.contentShape(Rectangle())
		.padding(.horizontal, DesignTokens.Spacing.md)
		.onTapGesture { action() }
	}
}
