import Foundation

/// Pure-function input method resolution logic.
/// Extracted from InputMethodManager for testability.
enum InputMethodResolver {
    /// Resolve the target input method for a given app based on the 4-level priority chain:
    /// 1. Memory state (last used input method for this app)
    /// 2. Manual configuration (per-app bundleId mapping)
    /// 3. Name matching rules (case-insensitive pattern match on app name)
    /// 4. Global default input method
    static func resolve(
        bundleId: String,
        memoryEnabledApps: Set<String>,
        lastInputMethodStates: [String: String],
        appInputMethodSettings: [String: String?],
        installedApps: [AppInfo],
        nameMatchingRules: [String: String],
        defaultInputMethod: String?
    ) -> String? {
        // Priority 1: Memory state (only when memory is enabled)
        if memoryEnabledApps.contains(bundleId),
           let lastState = lastInputMethodStates[bundleId] {
            return lastState
        }

        // Priority 2: Manual configuration (bundleId exact match)
        if let manualConfig = appInputMethodSettings[bundleId] {
            return manualConfig
        }

        // Priority 3: Name fuzzy matching
        if let appName = installedApps.first(where: { $0.bundleId == bundleId })?.name {
            for (pattern, inputMethodId) in nameMatchingRules {
                if appName.localizedCaseInsensitiveContains(pattern) {
                    return inputMethodId
                }
            }
        }

        // Priority 4: Global default
        return defaultInputMethod
    }
}
