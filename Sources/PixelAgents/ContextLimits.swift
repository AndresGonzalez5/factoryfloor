// ABOUTME: Maps harness model identifiers to their context-window token limits.

import Foundation

enum ContextLimits {
    static let defaultLimit = 200_000
    static let extendedLimit = 1_000_000

    /// Claude's extended-context models encode "[1m]" or "-1m" in their ID
    /// (e.g. "claude-sonnet-4-5[1m]"). The match is case-insensitive.
    static func limitTokens(forModel modelID: String?) -> Int {
        guard let modelID else { return defaultLimit }
        let lowered = modelID.lowercased()
        return lowered.contains("[1m]") || lowered.contains("-1m") ? extendedLimit : defaultLimit
    }
}
