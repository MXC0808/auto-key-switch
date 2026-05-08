import SwiftUI
import Defaults

/// Application rules settings interface
struct AppSettingsTab: View {
	@EnvironmentObject private var viewModel: InputMethodManager
	@State private var selectedApps: Set<String> = []
	@State private var searchText = ""
	@State private var showAddSheet = false
	@State private var showDeleteConfirmation = false
	@State private var lastSelectedIndex: Int? = nil

	var filteredApps: [AppInfo] {
		let apps = viewModel.appRulesListApps
		if searchText.isEmpty {
			return apps
		}
		return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
	}

	var body: some View {
		VStack(spacing: 0) {
			// Search bar
			HStack(spacing: DesignTokens.Spacing.sm) {
				Image(systemName: "magnifyingglass")
					.foregroundStyle(.secondary)
				TextField("搜索应用", text: $searchText)
					.textFieldStyle(.plain)
			}
			.padding(DesignTokens.Spacing.md)
			.background(DesignTokens.Colors.background)


			// Column headers
			HStack(spacing: DesignTokens.Spacing.md) {
				Text("应用")
					.frame(minWidth: 100 + DesignTokens.Sizes.iconLarge + DesignTokens.Spacing.md, alignment: .leading)
				Spacer()
				Text("英文标点")
					.frame(alignment: .center)
				Text("输入法")
					.frame(width: DesignTokens.Sizes.pickerWidth, alignment: .leading)
			}
			.font(.caption)
			.foregroundStyle(.secondary)
			.padding(.horizontal, DesignTokens.Spacing.md + DesignTokens.Spacing.lg)
			.padding(.vertical, DesignTokens.Spacing.xs)

			// Apps list
			ScrollView {
				LazyVStack(spacing: DesignTokens.Spacing.xs) {
					ForEach(Array(filteredApps.enumerated()), id: \.element.bundleId) { index, app in
						AppRuleRowV2(
							app: app,
							isSelected: selectedApps.contains(app.bundleId),
							onToggleSelection: { toggleSelection(for: app, at: index) },
							onInputChange: { inputMethodId in
								viewModel.setInputMethod(for: app, to: inputMethodId)
							}
						)
					}
				}
				.padding(.horizontal)
				.padding(.vertical, DesignTokens.Spacing.sm)
			}

			Divider()

			// Bottom toolbar
			HStack(spacing: DesignTokens.Spacing.md) {
				// 添加按钮
				Button(action: { showAddSheet = true }) {
					Image(systemName: "plus.circle.fill")
						.font(.title2)
				}
				.help("添加应用")
				.accessibilityLabel("添加应用")
		.focusable(false)

				// 删除按钮
				Button(action: { showDeleteConfirmation = true }) {
					Image(systemName: "trash")
						.font(.title2)
				}
				.disabled(selectedApps.isEmpty)
				.buttonStyle(.bordered)
				.help(selectedApps.isEmpty ? "选择应用后删除" : "删除选中 \(selectedApps.count) 个")
				.accessibilityLabel("删除选中应用")
		.focusable(false)

				// 选中数量
				if !selectedApps.isEmpty {
					Text("(\(selectedApps.count))")
						.font(.caption)
						.foregroundStyle(.secondary)
				}

				Spacer()

				// 全局默认输入法
				HStack(spacing: DesignTokens.Spacing.xs) {
					Text("全局默认：")
						.font(.subheadline)
					Picker(
						"",
						selection: Binding(
							get: { viewModel.defaultInputMethod ?? "" },
							set: { newValue in
								viewModel.setDefaultInputMethod(newValue.isEmpty ? nil : newValue)
							}
						)
					) {
						Text("---").tag("")
						ForEach(viewModel.inputMethods) { method in
							HStack(spacing: DesignTokens.Spacing.xs) {
								if let icon = method.icon {
									Image(nsImage: icon)
										.resizable()
										.frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
								} else {
									Image(systemName: "keyboard")
										.frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
								}
								Text(method.name)
							}.tag(method.id)
						}
					}
					.pickerStyle(.menu)
					.frame(width: DesignTokens.Sizes.globalPickerWidth)
			.focusable(false)
				}
			}
			.padding()
			.background(DesignTokens.Colors.background)
		}
		.sheet(isPresented: $showAddSheet) {
			AddAppSheet()
				.environmentObject(viewModel)
		}
		.confirmationDialog(
			"确定要删除选中的 \(selectedApps.count) 个应用规则吗？",
			isPresented: $showDeleteConfirmation,
			titleVisibility: .visible
		) {
			Button("确认删除", role: .destructive) {
				deleteSelectedApps()
			}
		} message: {
			Text("此操作不可撤销")
		}
	}

	// MARK: - Actions

	private func toggleSelection(for app: AppInfo, at index: Int) {
		let hasCommand = NSEvent.modifierFlags.contains(.command)
		let hasShift = NSEvent.modifierFlags.contains(.shift)

		if hasShift && lastSelectedIndex != nil {
			// Shift + click: 范围选择
			let start = min(lastSelectedIndex!, index)
			let end = max(lastSelectedIndex!, index)

			withAnimation(DesignTokens.Animation.normal) {
				for i in start...end {
					selectedApps.insert(filteredApps[i].bundleId)
				}
			}
		} else if hasCommand {
			// Command + click: 单选 toggle
			if selectedApps.contains(app.bundleId) {
				selectedApps.remove(app.bundleId)
			} else {
				selectedApps.insert(app.bundleId)
			}
			lastSelectedIndex = index
		} else {
			// Normal click: single select
			if selectedApps.contains(app.bundleId) && selectedApps.count == 1 {
				selectedApps.removeAll()
				lastSelectedIndex = nil
			} else {
				withAnimation(DesignTokens.Animation.fast) {
					selectedApps = [app.bundleId]
				}
				lastSelectedIndex = index
			}
		}
	}

	private func deleteSelectedApps() {
		for bundleId in selectedApps {
			if let app = viewModel.installedApps.first(where: { $0.bundleId == bundleId }) {
				viewModel.setInputMethod(for: app, to: nil)
			}
		}
		selectedApps.removeAll()
		lastSelectedIndex = nil
	}
}

// MARK: - App Rule Row V2

struct AppRuleRowV2: View {
	@EnvironmentObject private var viewModel: InputMethodManager
	let app: AppInfo
	let isSelected: Bool
	let onToggleSelection: () -> Void
	let onInputChange: (String?) -> Void

	@State private var isHovered = false
	@State private var forceEnglishPunctuation: Bool = false

	var currentSelection: String {
		viewModel.getInputMethod(for: app) ?? ""
	}

	var body: some View {
		HStack(spacing: DesignTokens.Spacing.md) {
			// Application icon
			app.icon
				.frame(width: DesignTokens.Sizes.iconLarge, height: DesignTokens.Sizes.iconLarge)

			// Application name
			Text(app.name)
				.frame(minWidth: 100, alignment: .leading)

			Spacer()

			// 强制英文符号开关
			let isGlobalEnabled = Defaults[.forceEnglishPunctuationEnabled]

			Toggle("", isOn: $forceEnglishPunctuation)
			.help(isGlobalEnabled ? "强制英文符号" : "请先在通用设置中开启总开关")
			.toggleStyle(.switch)
			.disabled(!isGlobalEnabled)
			.opacity(isGlobalEnabled ? 1.0 : 0.4)
					.focusable(false)
				.onChange(of: forceEnglishPunctuation) { newValue in
					var apps = Defaults[.forceEnglishPunctuationApps]
					if newValue {
						apps.insert(app.bundleId)
					} else {
						apps.remove(app.bundleId)
					}
					Defaults[.forceEnglishPunctuationApps] = apps
					// 如果是当前活跃应用，立即更新服务状态
					if app.bundleId == viewModel.currentActiveAppBundleId {
						viewModel.updatePunctuationServiceState()
					}
				}
				.onAppear {
					forceEnglishPunctuation = Defaults[.forceEnglishPunctuationApps].contains(app.bundleId)
				}

			// Input method selector
			Picker("", selection: Binding(
				get: { currentSelection },
				set: { newValue in
					onInputChange(newValue.isEmpty ? nil : newValue)
				}
			)) {
				HStack(spacing: DesignTokens.Spacing.xs) {
					Image(systemName: "circle.dashed")
					Text("使用默认")
				}.tag("")

				ForEach(viewModel.inputMethods) { method in
					HStack(spacing: DesignTokens.Spacing.xs) {
						if let icon = method.icon {
							Image(nsImage: icon)
								.resizable()
								.frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
						} else {
							Image(systemName: "keyboard")
								.frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
						}
						Text(method.name)
					}.tag(method.id)
				}
			}
			.pickerStyle(.menu)
			.frame(width: DesignTokens.Sizes.pickerWidth)
			  .focusable(false)
			}
	.padding(.vertical, DesignTokens.Spacing.sm)
		.padding(.horizontal, DesignTokens.Spacing.md)
		.background {
			RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
				.fill(isSelected ? DesignTokens.Colors.selectionHighlight : (isHovered ? DesignTokens.Colors.hoverBackground : .clear))
		}
		.overlay(alignment: .leading) {
			RoundedRectangle(cornerRadius: 1.5)
				.fill(Color.accentColor)
				.frame(width: 3)
				.opacity(isSelected ? 1 : 0)
		}
		.animation(DesignTokens.Animation.fast, value: isSelected)
		.animation(DesignTokens.Animation.fast, value: isHovered)
		.contentShape(Rectangle())
		.onTapGesture {
			onToggleSelection()
		}
		.onHover { hovering in
			withAnimation(DesignTokens.Animation.fast) {
				isHovered = hovering
			}
		}
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isButton)
	}
}

#Preview {
	AppSettingsTab()
		.environmentObject(InputMethodManager.shared)
		.frame(width: 550, height: 500)
}