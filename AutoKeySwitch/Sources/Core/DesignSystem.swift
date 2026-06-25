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
		static let pill: CGFloat = 20
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
		static let windowBackground = Color(NSColor.windowBackgroundColor)
		static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
		static let sidebarActiveBackground = Color.gray.opacity(0.2)
		static let sidebarPressedBackground = Color.gray.opacity(0.1)
		static let cardHoverBackground = Color.blue.opacity(0.08)
		static let warningBackground = Color.yellow.opacity(0.08)
		static let hudEnglishIndicator = Color(red: 0.42, green: 0.66, blue: 0.86)
		static let hudChineseIndicator = Color.orange
		static let statusRunning = Color.green
		static let destructive = Color(red: 1.0, green: 0.42, blue: 0.42)
	}

	// MARK: - Typography

	/// 字体
	enum Typography {
		static let pageEyebrow: Font = .caption
		static let pageTitle: Font = .title2.weight(.semibold)
		static let pageSubtitle: Font = .subheadline
		static let sidebarGroupTitle: Font = .system(size: 10)
		static let sidebarItem: Font = .system(size: 13)
		static let sidebarVersion: Font = .system(size: 12)
		static let contentHeaderIcon: Font = .system(size: 18, weight: .medium)
		static let contentHeaderTitle: Font = .system(size: 12, weight: .semibold)
		static let contentHeaderSubtitle: Font = .system(size: 11)
		static let cardTitle: Font = .system(size: 13, weight: .medium)
		static let cardSubtitle: Font = .system(size: 10)
		static let badgeText: Font = .system(size: 10)
		static let sectionHeader: Font = .system(size: 12, weight: .medium)
		static let menuItemTitle: Font = .system(size: 13, weight: .medium)
		static let menuItemSubtitle: Font = .system(size: 10)
		static let hudText: Font = .system(size: 15, weight: .medium)
	}

	// MARK: - Sizes

	/// 尺寸
	enum Sizes {
		static let iconSmall: CGFloat = 16
		static let iconMedium: CGFloat = 20
		static let iconLarge: CGFloat = 24
		static let iconXL: CGFloat = 32
		static let contentWidth: CGFloat = 920

		static let pickerWidth: CGFloat = 160
		static let globalPickerWidth: CGFloat = 180
		static let inspectorPickerWidth: CGFloat = 164
		static let inspectorToggleWidth: CGFloat = 132
		static let inspectorStatusWidth: CGFloat = 210
		static let inspectorActionWidth: CGFloat = 60
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
	/// 主内容面板样式
	func panelStyle() -> some View {
		self
			.padding(DesignTokens.Spacing.lg)
			.background(DesignTokens.Colors.background.opacity(0.72))
			.overlay {
				RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl, style: .continuous)
					.stroke(DesignTokens.Colors.divider.opacity(0.7), lineWidth: 1)
			}
			.clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl, style: .continuous))
	}

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

	func inspectorTableChrome() -> some View {
		self
			.background(DesignTokens.Colors.background.opacity(0.045))
			.overlay {
				RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
					.stroke(DesignTokens.Colors.divider.opacity(0.24), lineWidth: 1)
			}
			.clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous))
	}

	func inspectorRowStyle(isSelected: Bool, isHovered: Bool) -> some View {
		self
			.padding(.horizontal, DesignTokens.Spacing.sm)
			.padding(.vertical, 5)
			.background {
				RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
					.fill(isSelected ? DesignTokens.Colors.selectionHighlight : (isHovered ? DesignTokens.Colors.hoverBackground : Color.clear))
			}
			.overlay {
				RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
					.stroke(
						isSelected ? DesignTokens.Colors.selectionBorder :
						(isHovered ? DesignTokens.Colors.divider.opacity(0.18) : Color.clear),
						lineWidth: 1
					)
			}
			.padding(.horizontal, DesignTokens.Spacing.xs)
			.animation(DesignTokens.Animation.fast, value: isSelected)
			.animation(DesignTokens.Animation.fast, value: isHovered)
	}
}

struct InspectorTable<Actions: View, Columns: View, Rows: View>: View {
	let summary: String
	@ViewBuilder let actions: Actions
	@ViewBuilder let columns: Columns
	@ViewBuilder let rows: Rows

	var body: some View {
		VStack(spacing: 0) {
			HStack(spacing: DesignTokens.Spacing.sm) {
				Text(summary)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(1)
				Spacer(minLength: DesignTokens.Spacing.md)
				actions
			}
			.padding(.horizontal, DesignTokens.Spacing.md)
			.padding(.vertical, 8)

			Divider()

			columns
				.font(.caption)
				.foregroundStyle(.secondary)
				.padding(.horizontal, DesignTokens.Spacing.md)
				.padding(.vertical, 5)

			Divider()

			rows
		}
		.inspectorTableChrome()
	}
}

struct MinimalSwitchToggleStyle: ToggleStyle {
	@Environment(\.isEnabled) private var isEnabled
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	func makeBody(configuration: Configuration) -> some View {
		HStack(spacing: DesignTokens.Spacing.sm) {
			configuration.label

			Button {
				withAnimation(reduceMotion ? nil : DesignTokens.Animation.fast) {
					configuration.isOn.toggle()
				}
			} label: {
				ZStack(alignment: configuration.isOn ? .trailing : .leading) {
					Capsule(style: .continuous)
						.fill(trackFill(isOn: configuration.isOn))
						.overlay {
							Capsule(style: .continuous)
								.stroke(trackStroke(isOn: configuration.isOn), lineWidth: 1)
						}

					Circle()
						.fill(Color(nsColor: .controlBackgroundColor))
						.shadow(color: .black.opacity(configuration.isOn ? 0.18 : 0.08), radius: 1.5, x: 0, y: 0.5)
						.padding(2)
				}
				.frame(width: 34, height: 18)
				.opacity(isEnabled ? 1.0 : 0.45)
			}
			.buttonStyle(.plain)
			.focusable(false)
			.disabled(!isEnabled)
			.accessibilityLabel(configuration.isOn ? "开启" : "关闭")
			.accessibilityValue(configuration.isOn ? "已开启" : "已关闭")
		}
	}

	private func trackFill(isOn: Bool) -> Color {
		isOn ? Color.accentColor.opacity(0.88) : Color.secondary.opacity(0.14)
	}

	private func trackStroke(isOn: Bool) -> Color {
		isOn ? Color.accentColor.opacity(0.22) : DesignTokens.Colors.divider.opacity(0.55)
	}
}
