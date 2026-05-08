import SwiftUI

// MARK: - Design Tokens

/// 统一的设计系统常量
enum DesignTokens {
	// MARK: - Spacing

	/// 间距
	enum Spacing {
		static let xxs: CGFloat = 2
		static let xs: CGFloat = 4
		static let sm: CGFloat = 8
		static let md: CGFloat = 12
		static let lg: CGFloat = 16
		static let xl: CGFloat = 20
		static let xxl: CGFloat = 24
	}

	// MARK: - Corner Radius

	/// 圆角
	enum CornerRadius {
		static let sm: CGFloat = 4
		static let md: CGFloat = 6
		static let lg: CGFloat = 8
		static let xl: CGFloat = 12
	}

	// MARK: - Animation

	/// 动画
	enum Animation {
		static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
		static let normal = SwiftUI.Animation.easeInOut(duration: 0.25)
		static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
	}

	// MARK: - Colors

	/// 自定义颜色
	enum Colors {
		static let selectionHighlight = Color.accentColor.opacity(0.12)
		static let selectionBorder = Color.accentColor.opacity(0.3)
		static let hoverBackground = Color.accentColor.opacity(0.05)
		static let divider = Color(NSColor.separatorColor)
		static let background = Color(NSColor.controlBackgroundColor)
		static let sidebarActiveBackground = Color.gray.opacity(0.2)
		static let sidebarPressedBackground = Color.gray.opacity(0.1)
		static let cardHoverBackground = Color.blue.opacity(0.08)
		static let warningBackground = Color.yellow.opacity(0.08)
	}

	// MARK: - Typography

	/// 字体
	enum Typography {
		static let sidebarGroupTitle: Font = .system(size: 10)
		static let sidebarItem: Font = .system(size: 13)
		static let sidebarVersion: Font = .system(size: 12)
		static let contentHeaderIcon: Font = .system(size: 18, weight: .medium)
		static let contentHeaderTitle: Font = .system(size: 12, weight: .semibold)
		static let contentHeaderSubtitle: Font = .system(size: 11)
	}

	// MARK: - Sizes

	/// 尺寸
	enum Sizes {
		static let iconSmall: CGFloat = 16
		static let iconMedium: CGFloat = 20
		static let iconLarge: CGFloat = 24
		static let iconXL: CGFloat = 32

		static let pickerWidth: CGFloat = 160
		static let globalPickerWidth: CGFloat = 180
	}

	// MARK: - Sidebar

	/// 侧边栏
	enum Sidebar {
		static let width: CGFloat = 200
		static let headerHeight: CGFloat = 52
		static let iconSize: CGFloat = 15
		static let cornerRadius: CGFloat = 6
		static let topPadding: CGFloat = 40
	}
}

// MARK: - View Extensions

extension View {
	/// 统一的卡片样式
	func cardStyle() -> some View {
		self
			.padding(DesignTokens.Spacing.md)
			.background(DesignTokens.Colors.background)
			.cornerRadius(DesignTokens.CornerRadius.lg)
	}

	/// 统一的列表行样式
	func listRowStyle(isSelected: Bool = false, isHighlighted: Bool = false) -> some View {
		self
			.padding(.vertical, DesignTokens.Spacing.sm)
			.padding(.horizontal, DesignTokens.Spacing.md)
			.background {
				RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
					.fill(backgroundColor(isSelected: isSelected, isHighlighted: isHighlighted))
			}
			.animation(DesignTokens.Animation.fast, value: isSelected)
			.animation(DesignTokens.Animation.fast, value: isHighlighted)
	}

	private func backgroundColor(isSelected: Bool, isHighlighted: Bool) -> Color {
		if isHighlighted {
			return DesignTokens.Colors.hoverBackground
		} else if isSelected {
			return DesignTokens.Colors.selectionHighlight
		} else {
			return .clear
		}
	}

	/// 悬停高亮效果
	func hoverHighlight(isHovered: Bool) -> some View {
		self
			.background {
				RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
					.fill(isHovered ? DesignTokens.Colors.hoverBackground : .clear)
			}
			.animation(DesignTokens.Animation.fast, value: isHovered)
	}
}
