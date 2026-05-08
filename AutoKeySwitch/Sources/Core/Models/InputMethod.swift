import AppKit
import Foundation

/// 输入法数据模型
struct InputMethod: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: NSImage?

    static func == (lhs: InputMethod, rhs: InputMethod) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
