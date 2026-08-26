// ABOUTME: Identifies which coding-agent CLI a workstream runs.
// ABOUTME: Extensible enum so future harnesses (e.g., Codex) are one case away.

import Foundation

enum CodingHarness: String, Codable, CaseIterable, Sendable {
    case claudeCode
    case opencode

    var displayName: String {
        switch self {
        case .claudeCode:
            return NSLocalizedString("Claude Code", comment: "Name of the Claude Code coding agent")
        case .opencode:
            return NSLocalizedString("OpenCode", comment: "Name of the OpenCode coding agent")
        }
    }

    var cliName: String {
        switch self {
        case .claudeCode:
            return "claude"
        case .opencode:
            return "opencode"
        }
    }

    var systemImageName: String {
        switch self {
        case .claudeCode:
            return "sparkle"
        case .opencode:
            return "chevron.left.forwardslash.chevron.right"
        }
    }

    /// Sprite-store key used by `AgentSpriteStore` / `MainAgentPortrait`.
    var portraitName: String {
        switch self {
        case .claudeCode:
            return "Claude"
        case .opencode:
            return "OpenCode"
        }
    }

    var installURL: URL {
        switch self {
        case .claudeCode:
            return URL(string: "https://docs.anthropic.com/en/docs/claude-code/overview")!
        case .opencode:
            return URL(string: "https://opencode.ai")!
        }
    }
}
