/// Permission checking protocol for dependency injection
protocol PermissionProviding: Sendable {
    func checkAccessibility() -> Bool
    func requestAccessibility() -> Bool
}

/// Delegates to PermissionService as the single source of truth
struct SystemPermissionProvider: PermissionProviding {
    func checkAccessibility() -> Bool {
        PermissionService.checkAccessibility()
    }

    func requestAccessibility() -> Bool {
        PermissionService.requestAccessibility()
    }
}
