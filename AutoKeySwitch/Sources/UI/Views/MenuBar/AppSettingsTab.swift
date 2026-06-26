import SwiftUI
import Defaults

/// Application rules settings interface
struct AppSettingsTab: View {
	@EnvironmentObject private var viewModel: InputMethodManager
	@Binding var searchText: String
	@State private var selectedApps: Set<String> = []
	@State private var showAddSheet = false
	@State private var showDeleteConfirmation = false
	@State private var lastSelectedBundleID: String? = nil

	var filteredApps: [AppInfo] {
		let apps = viewModel.appRulesListApps
		if searchText.isEmpty {
			return apps
		}
		return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
	}

	private var visibleSelectedBundleIDs: Set<String> {
		Set(filteredApps.map(\.bundleId)).intersection(selectedApps)
	}

	private var visibleSelectedCount: Int {
		visibleSelectedBundleIDs.count
	}

	var body: some View {
		VStack(spacing: 0) {
			ScrollView {
				VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
					VStack(alignment: .leading, spacing: 1) {
						Text("应用规则")
							.font(.headline.weight(.semibold))
						Text("按应用设置输入法，标点作为辅助选项。")
							.font(.caption2)
							.foregroundStyle(.secondary)
					}
					.padding(.leading, DesignTokens.Spacing.xs)

					InspectorTable(
						summary: "\(filteredApps.count) 个应用",
						actions: {
							EmptyView()
						},
						columns: {
							HStack(spacing: DesignTokens.Spacing.sm) {
								HStack(spacing: DesignTokens.Spacing.sm) {
									Color.clear
										.frame(width: DesignTokens.Sizes.iconLarge, height: 1)
									Text("应用")
										.frame(maxWidth: .infinity, alignment: .leading)
								}
								.frame(maxWidth: .infinity, alignment: .leading)
								Text("输入法")
									.frame(width: DesignTokens.Sizes.inspectorPickerWidth, alignment: .center)
								Text("英文标点")
									.frame(width: DesignTokens.Sizes.inspectorToggleWidth, alignment: .leading)
							}
						},
						rows: {
							ForEach(Array(filteredApps.enumerated()), id: \.element.bundleId) { index, app in
								AppRuleCardView(
									app: app,
									isSelected: selectedApps.contains(app.bundleId),
									onToggleSelection: { toggleSelection(for: app, at: index) },
									onInputChange: { inputMethodId in
										viewModel.setInputMethod(for: app, to: inputMethodId)
									}
								)
							}
						}
					)
				}
				.frame(maxWidth: DesignTokens.Sizes.contentWidth, alignment: .leading)
				.padding(.horizontal, DesignTokens.Spacing.xl)
				.padding(.vertical, DesignTokens.Spacing.lg)
			}

			AppRulesBottomBar(
				appCount: filteredApps.count,
				selectedCount: visibleSelectedCount,
				isDeleteDisabled: visibleSelectedBundleIDs.isEmpty,
				onAdd: { showAddSheet = true },
				onDelete: { showDeleteConfirmation = true }
			)
			.environmentObject(viewModel)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		.sheet(isPresented: $showAddSheet) {
			AddAppSheet()
				.environmentObject(viewModel)
		}
		.confirmationDialog(
			"确定要删除选中的 \(visibleSelectedCount) 个应用规则吗？",
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

		if hasShift,
		   let lastSelectedBundleID,
		   let anchorIndex = filteredApps.firstIndex(where: { $0.bundleId == lastSelectedBundleID }) {
			// Shift + click: 范围选择
			let start = min(anchorIndex, index)
			let end = max(anchorIndex, index)

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
			lastSelectedBundleID = app.bundleId
		} else {
			// Normal click: single select
			if selectedApps.contains(app.bundleId) && selectedApps.count == 1 {
				selectedApps.removeAll()
				lastSelectedBundleID = nil
			} else {
				withAnimation(DesignTokens.Animation.fast) {
					selectedApps = [app.bundleId]
				}
				lastSelectedBundleID = app.bundleId
			}
		}
	}

	private func deleteSelectedApps() {
		let bundleIDsToDelete = visibleSelectedBundleIDs

		for bundleId in bundleIDsToDelete {
			if let app = viewModel.installedApps.first(where: { $0.bundleId == bundleId }) {
				viewModel.setInputMethod(for: app, to: nil)
			}
		}
		selectedApps.subtract(bundleIDsToDelete)
		if let lastSelectedBundleID,
		   bundleIDsToDelete.contains(lastSelectedBundleID) {
			self.lastSelectedBundleID = nil
		}
	}
}

private struct AppRulesBottomBar: View {
	@EnvironmentObject private var viewModel: InputMethodManager

	let appCount: Int
	let selectedCount: Int
	let isDeleteDisabled: Bool
	let onAdd: () -> Void
	let onDelete: () -> Void

	private var selectionSummary: String {
		if selectedCount > 0 {
			return "\(appCount) 个应用  已选 \(selectedCount) 个"
		}
		return "\(appCount) 个应用"
	}

	var body: some View {
		HStack(spacing: DesignTokens.Spacing.lg) {
			Text(selectionSummary)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)

			Spacer(minLength: DesignTokens.Spacing.lg)

			HStack(spacing: 10) {
				Text("默认输入法")
					.font(.caption)
					.foregroundStyle(.secondary)

				CompactGlobalDefaultPicker()
					.environmentObject(viewModel)
			}

			Spacer(minLength: DesignTokens.Spacing.lg)

			HStack(spacing: DesignTokens.Spacing.md) {
				Button {
					onAdd()
				} label: {
					Image(systemName: "plus")
						.font(.system(size: 15, weight: .medium))
				}
				.buttonStyle(.plain)
				.foregroundStyle(.secondary)
				.focusable(false)
				.help("添加应用规则")
				.accessibilityLabel("添加应用规则")

				Button(role: .destructive) {
					onDelete()
				} label: {
					Image(systemName: "trash")
						.font(.system(size: 15, weight: .medium))
				}
				.buttonStyle(.plain)
				.disabled(isDeleteDisabled)
				.foregroundStyle(isDeleteDisabled ? .tertiary : .secondary)
				.focusable(false)
				.help(isDeleteDisabled ? "删除应用规则" : "删除选中的应用规则")
				.accessibilityLabel("删除选中的应用规则")
			}
		}
		.frame(maxWidth: .infinity, alignment: .center)
		.frame(maxWidth: DesignTokens.Sizes.contentWidth)
		.padding(.horizontal, 28)
		.padding(.vertical, 12)
		.fixedBottomBarStyle()
	}
}

private struct CompactGlobalDefaultPicker: View {
	@EnvironmentObject private var viewModel: InputMethodManager

	private var currentMethodName: String {
		guard let id = viewModel.defaultInputMethod,
			  let method = viewModel.inputMethods.first(where: { $0.id == id }) else {
			return "跟随系统"
		}
		return method.name
	}

	var body: some View {
		Menu {
			Button {
				viewModel.setDefaultInputMethod(nil)
			} label: {
				Label("跟随系统", systemImage: viewModel.defaultInputMethod == nil ? "checkmark" : "")
			}

			Divider()

			ForEach(viewModel.inputMethods) { method in
				Button {
					viewModel.setDefaultInputMethod(method.id)
				} label: {
					HStack(spacing: DesignTokens.Spacing.xs) {
						if method.id == viewModel.defaultInputMethod {
							Image(systemName: "checkmark")
								.frame(width: 10)
						} else {
							Color.clear
								.frame(width: 10, height: 10)
						}

						if let icon = method.icon {
							Image(nsImage: icon)
								.resizable()
								.frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
						} else {
							Image(systemName: "keyboard")
								.frame(width: DesignTokens.Sizes.iconSmall, height: DesignTokens.Sizes.iconSmall)
						}

						Text(method.name)
					}
				}
			}
		} label: {
			HStack(spacing: 6) {
				Text(currentMethodName)
					.font(.subheadline.weight(.medium))
					.foregroundStyle(.primary)
					.lineLimit(1)
					.layoutPriority(1)

				Image(systemName: "chevron.down")
					.font(.system(size: 10, weight: .semibold))
					.foregroundStyle(.secondary)
			}
			.padding(.horizontal, 10)
			.padding(.vertical, 5)
		}
		.fixedSize()
		.background {
			RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
				.fill(Color.secondary.opacity(0.045))
		}
		.overlay {
			RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
				.stroke(Color(NSColor.separatorColor).opacity(0.22), lineWidth: 1)
		}
		.focusable(false)
		.help("设置默认输入法")
		.accessibilityLabel("默认输入法：\(currentMethodName)")
	}
}

// MARK: - App Rule Card View

struct AppRuleCardView: View {
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

	private var ruleDetail: String {
		guard !currentSelection.isEmpty else { return "继承默认输入法" }
		return viewModel.inputMethods.first(where: { $0.id == currentSelection })?.name ?? "已指定输入法"
	}

	private var punctuationTint: Color {
		let isGlobalEnabled = Defaults[.forceEnglishPunctuationEnabled]
		guard isGlobalEnabled else { return .secondary.opacity(0.45) }
		return forceEnglishPunctuation ? .accentColor : .secondary
	}

	private var punctuationStatusText: String {
		guard Defaults[.forceEnglishPunctuationEnabled] else { return "未启用" }
		return forceEnglishPunctuation ? "强制英文" : "跟随输入法"
	}

	private var punctuationHelpText: String {
		Defaults[.forceEnglishPunctuationEnabled]
			? "中文输入法下将标点转换为英文"
			: "请先在偏好设置 > 高级 中开启强制英文符号"
	}

	var body: some View {
		HStack(spacing: DesignTokens.Spacing.sm) {
			app.icon
				.frame(width: DesignTokens.Sizes.iconLarge, height: DesignTokens.Sizes.iconLarge)

			VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
				Text(app.name)
					.font(DesignTokens.Typography.cardTitle)
					.lineLimit(1)
					.truncationMode(.middle)
				Text(ruleDetail)
					.font(DesignTokens.Typography.cardSubtitle)
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}
			.frame(maxWidth: .infinity, alignment: .leading)

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
			.controlSize(.small)
			.frame(width: DesignTokens.Sizes.inspectorPickerWidth)
			.focusable(false)

			let isGlobalEnabled = Defaults[.forceEnglishPunctuationEnabled]

			HStack(spacing: DesignTokens.Spacing.sm) {
				Text(punctuationStatusText)
					.font(.caption2)
					.foregroundStyle(punctuationTint)
					.lineLimit(1)
					.frame(maxWidth: .infinity, alignment: .leading)

				Toggle("", isOn: $forceEnglishPunctuation)
					.help(punctuationHelpText)
					.toggleStyle(MinimalSwitchToggleStyle())
					.labelsHidden()
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
						if app.bundleId == viewModel.currentActiveAppBundleId {
							viewModel.updatePunctuationServiceState()
						}
					}
					.onAppear {
						forceEnglishPunctuation = Defaults[.forceEnglishPunctuationApps].contains(app.bundleId)
					}
			}
			.frame(width: DesignTokens.Sizes.inspectorToggleWidth, alignment: .leading)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.inspectorRowStyle(isSelected: isSelected, isHovered: isHovered)
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
	AppSettingsTab(searchText: .constant(""))
		.environmentObject(InputMethodManager.shared)
		.frame(width: 550, height: 500)
}
