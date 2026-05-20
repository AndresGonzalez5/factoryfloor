// ABOUTME: Per-workstream Claude agent state derived from lifecycle hook events.
// ABOUTME: Drives the sidebar indicator (working / needs-you / idle).

import Foundation
import os

private let logger = Logger(subsystem: "factoryfloor", category: "agent-state")

/// Tracks the high-level state of the main Claude agent in each workstream.
///
/// State transitions are driven by `UserPromptSubmit` / `Stop` hook events
/// (and `Notification` events for permission prompts). Tool boundaries
/// (`PreToolUse` / `PostToolUse`) intentionally do NOT cause transitions —
/// "working" stays solid through thinking-between-tools.
@MainActor
final class WorkstreamAgentStateTracker: ObservableObject {
    static let shared = WorkstreamAgentStateTracker()

    enum NeedsReason: Equatable {
        case justFinished
        case permission
    }

    enum AgentRunState: Equatable {
        case idle
        case working
        case needsAttention(NeedsReason)
    }

    @Published private(set) var states: [UUID: AgentRunState] = [:]

    /// Resolves a Claude `project_dir` payload to the matching workstream UUID.
    /// Set by `ContentView` whenever the project list changes.
    var workstreamLookup: ((String) -> UUID?)?

    /// Currently selected workstream — `Stop` while selected goes straight to
    /// `.idle` because the user is already looking at it.
    var currentSelection: UUID?

    private init() {}

    func state(for id: UUID) -> AgentRunState {
        states[id] ?? .idle
    }

    /// Clears the `.justFinished` blue state. Permission state is preserved
    /// because it still blocks Claude even after the user has looked at the row.
    func markSeen(workstreamID: UUID) {
        if case .needsAttention(.justFinished) = states[workstreamID] {
            states[workstreamID] = .idle
        }
    }

    /// Aggressive path normalization: resolves symlinks (e.g. `/private/var` ↔ `/var`)
    /// in addition to the `.standardized` collapse. Hook payloads and stored
    /// `worktreePath`s have come through different code paths and may differ in
    /// symlink form.
    static func normalize(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().standardized.path
    }

    func handle(projectDir: String, event: AgentEvent) {
        // Subagent activity does not change the main agent's run state.
        guard event.agentId == "main" else { return }

        guard let lookup = workstreamLookup, let wsID = lookup(projectDir) else {
            // Common: Claude sessions running outside any tracked workstream.
            logger.debug("No workstream match for projectDir: \(projectDir, privacy: .public)")
            return
        }

        switch event.type {
        case .agentWaiting:
            states[wsID] = .working

        case .agentIdle:
            if currentSelection == wsID {
                states[wsID] = .idle
            } else {
                states[wsID] = .needsAttention(.justFinished)
            }

        case .agentStatus:
            if event.status == "permissionRequired" {
                states[wsID] = .needsAttention(.permission)
            }

        case .agentToolStart, .agentToolDone:
            // Tool activity while we were awaiting permission means the user
            // already answered the prompt (there's no explicit "granted" hook).
            // Otherwise no state change — prevents flicker between tools.
            if case .needsAttention(.permission) = states[wsID] {
                states[wsID] = .working
            }

        case .agentCreated, .agentRemoved:
            break
        }
    }
}
