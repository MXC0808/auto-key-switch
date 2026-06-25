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

			VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
				VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
					Text("AutoKeySwitch")
						.font(.headline.weight(.semibold))
					Text("输入法自动切换与状态记忆")
						.font(.caption2)
						.foregroundStyle(.secondary)
				}
				.padding(.horizontal, DesignTokens.Spacing.xl)
				.padding(.top, DesignTokens.Spacing.md)

				Divider()
					.padding(.horizontal, DesignTokens.Spacing.lg)

				ForEach(NavigationVM.grouped, id: \.id) { group in
					VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
						if !group.title.isEmpty {
							HStack {
								Text(group.title)
									.font(DesignTokens.Typography.sidebarGroupTitle)
									.foregroundStyle(.secondary)
								Spacer()
							}
							.padding(.leading, DesignTokens.Spacing.xl)
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
					.font(DesignTokens.Typography.sidebarVersion)
					.foregroundStyle(.tertiary)
					.padding(.horizontal, DesignTokens.Spacing.lg)
					.padding(.bottom, DesignTokens.Spacing.sm)
			}
			.padding(.vertical, DesignTokens.Spacing.md)
		}
		.frame(width: DesignTokens.Sidebar.width)
	}
}

/// Sidebar navigation item row with icon + text + selection highlight
struct NavItemRow: View {
	let item: NavigationVM.NavItem
	let isActive: Bool
	let action: () -> Void

	@State private var isHovered = false

	var body: some View {
		HStack(spacing: DesignTokens.Spacing.sm) {
			Image(systemName: item.icon)
				.font(.system(size: DesignTokens.Sidebar.iconSize, weight: .medium))
				.frame(width: DesignTokens.Sidebar.iconSize, height: DesignTokens.Sidebar.iconSize)
				.foregroundStyle(isActive ? Color.accentColor : Color.secondary)

			Text(item.displayName)
				.font(DesignTokens.Typography.sidebarItem)
				.lineLimit(1)

			Spacer()
		}
		.padding(.leading, DesignTokens.Spacing.md)
		.padding(.trailing, DesignTokens.Spacing.md)
		.padding(.vertical, 8)
		.frame(maxWidth: .infinity)
		.background {
			RoundedRectangle(cornerRadius: DesignTokens.Sidebar.cornerRadius, style: .continuous)
				.fill(
					isActive ? DesignTokens.Colors.selectionHighlight :
					isHovered ? DesignTokens.Colors.hoverBackground :
					Color.clear
				)
		}
		.overlay(alignment: .leading) {
			RoundedRectangle(cornerRadius: 1.5, style: .continuous)
				.fill(Color.accentColor)
				.frame(width: 3, height: 16)
				.opacity(isActive ? 1 : 0)
				.padding(.leading, 6)
		}
		.animation(DesignTokens.Animation.fast, value: isActive)
		.animation(DesignTokens.Animation.fast, value: isHovered)
		.foregroundStyle(Color.primary)
		.clipShape(RoundedRectangle(cornerRadius: DesignTokens.Sidebar.cornerRadius))
		.contentShape(Rectangle())
		.padding(.horizontal, DesignTokens.Spacing.sm)
		.onTapGesture { action() }
		.onHover { hovering in
			withAnimation(DesignTokens.Animation.fast) {
				isHovered = hovering
			}
		}
	}
}
