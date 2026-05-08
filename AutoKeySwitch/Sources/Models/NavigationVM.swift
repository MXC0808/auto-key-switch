import SwiftUI

@MainActor
class NavigationVM: ObservableObject {
	/// Sidebar navigation item
	enum NavItem: String, CaseIterable, Identifiable {
		case appRules
		case memory
		case preferences

		var id: String { rawValue }

		/// SF Symbol name for sidebar icon
		var icon: String {
			switch self {
			case .appRules:
				return "app.badge.checkmark"
			case .memory:
				if #available(macOS 14.0, *) {
					return "brain.head.profile"
				} else {
					return "brain"
				}
			case .preferences:
				return "gearshape"
			}
		}

		/// Chinese display name shown in sidebar and content header
		var displayName: String {
			switch self {
			case .appRules: return "应用规则"
			case .memory: return "应用记忆"
			case .preferences: return "偏好设置"
			}
		}

		/// Keyboard shortcut for navigation
		var shortcut: KeyEquivalent {
			switch self {
			case .appRules: return "1"
			case .memory: return "2"
			case .preferences: return "3"
			}
		}
	}

	/// Sidebar group with header title
	struct NavGroup {
		let id: String
		let title: String
		let items: [NavItem]
	}

	/// All groups in sidebar display order
	static var grouped: [NavGroup] {
		[
			NavGroup(id: "rules", title: "规则", items: [.appRules, .memory]),
			NavGroup(id: "settings", title: "设置", items: [.preferences]),
		]
	}

	@Published var selection: NavItem = .appRules
}