// ABOUTME: Per-workstream Claude agent roster derived from lifecycle hook events.
// ABOUTME: Tracks main + subagent runs (activity, stalls) and drives the sidebar UI.

import Foundation
import os

private let logger = Logger(subsystem: "factoryfloor", category: "agent-state")

/// Tracks the live agent runs in each workstream.
///
/// State transitions are driven by hook events (`UserPromptSubmit` / `Stop`,
/// `PreToolUse` / `PostToolUse`, `SubagentStart` / `SubagentStop`). A run is
/// created when its agent spawns and removed when its stop hook arrives, so
/// the roster mirrors exactly what Claude Code reports — no artificial timers
/// govern visibility. The only timer is the stall sweep: a run that stops
/// emitting events while supposedly working flips to `.stalled`.
///
/// The high-level `AgentRunState` (driving the sidebar row dot) is kept in
/// sync alongside the roster.
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
        /// No hook events for a while although the turn hasn't ended.
        case stalled
        case needsAttention(NeedsReason)
    }

    /// One live agent (main or subagent) inside a workstream.
    struct AgentRun: Identifiable, Equatable {
        enum RunState: Equatable {
            case working
            case stalled
        }

        /// Claude's agent id ("main" or a subagent id).
        let id: String
        /// Display name ("Claude" or the subagent type).
        let name: String
        let palette: Int
        let isMain: Bool
        /// Per-type occurrence slot: the lowest index not held by a live
        /// same-type run at creation. Drives sprite-set cycling in the roster
        /// (sprite shown is `variantIndex % setCount`).
        let variantIndex: Int
        var state: RunState
        /// What the agent is doing right now, e.g. "Editing Foo.swift".
        var activity: String?
        let startedAt: Date
        var lastEventAt: Date
    }

    static let stallThreshold: TimeInterval = 45
    private static let sweepInterval: TimeInterval = 15

    @Published private(set) var states: [UUID: AgentRunState] = [:]
    @Published private(set) var rosters: [UUID: [AgentRun]] = [:]

    /// Resolves a Claude `project_dir` payload to the matching workstream UUID.
    /// Set by `ContentView` whenever the project list changes.
    var workstreamLookup: ((String) -> UUID?)?

    /// Currently selected workstream — `Stop` while selected goes straight to
    /// `.idle` because the user is already looking at it.
    var currentSelection: UUID?

    private var sweepTimer: Timer?

    private init() {}

    // MARK: - Public API

    func state(for id: UUID) -> AgentRunState {
        states[id] ?? .idle
    }

    /// Live agent runs for a workstream, main agent first.
    func runs(for id: UUID) -> [AgentRun] {
        rosters[id] ?? []
    }

    /// Number of live agent runs (main + subagents).
    func activeRunCount(for id: UUID) -> Int {
        rosters[id]?.count ?? 0
    }

    /// Clears the `.justFinished` blue state. Permission state is preserved
    /// because it still blocks Claude even after the user has looked at the row.
    func markSeen(workstreamID: UUID) {
        if case .needsAttention(.justFinished) = states[workstreamID] {
            states[workstreamID] = .idle
        }
    }

    /// Drops all tracked state for a workstream (called when it is removed).
    func clear(workstreamID: UUID) {
        states.removeValue(forKey: workstreamID)
        rosters.removeValue(forKey: workstreamID)
    }

    /// Clears every tracked state. Used by tests to isolate cases.
    func resetForTesting() {
        states.removeAll()
        rosters.removeAll()
        workstreamLookup = nil
        currentSelection = nil
    }

    /// Backdates a run's last-event timestamp. Used by stall sweep unit tests.
    func _backdateRun(agentId: String, workstreamID: UUID, lastEventAt: Date) {
        guard var list = rosters[workstreamID],
              let idx = list.firstIndex(where: { $0.id == agentId }) else { return }
        list[idx].lastEventAt = lastEventAt
        rosters[workstreamID] = list
    }

    /// Aggressive path normalization: resolves symlinks (e.g. `/private/var` ↔ `/var`)
    /// in addition to the `.standardized` collapse. Hook payloads and stored
    /// `worktreePath`s have come through different code paths and may differ in
    /// symlink form.
    static func normalize(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().standardized.path
    }

    // MARK: - Event Handling

    func handle(projectDir: String, event: AgentEvent) {
        guard let lookup = workstreamLookup, let wsID = lookup(projectDir) else {
            // Common: Claude sessions running outside any tracked workstream.
            logger.debug("No workstream match for projectDir: \(projectDir, privacy: .public)")
            return
        }

        ensureSweepTimer()
        updateRoster(wsID: wsID, event: event)
        if event.agentId == "main" {
            updateMainState(wsID: wsID, event: event)
        }
    }

    private func updateRoster(wsID: UUID, event: AgentEvent) {
        let now = Date()
        var list = rosters[wsID] ?? []

        func upsert(_ agentId: String, name: String? = nil, palette: Int = 0, isMain: Bool = true, variantIndex: Int = 0, mutate: (inout AgentRun) -> Void = { _ in }) {
            if let idx = list.firstIndex(where: { $0.id == agentId }) {
                mutate(&list[idx])
                list[idx].lastEventAt = now
            } else {
                var run = AgentRun(
                    id: agentId,
                    name: name ?? "Claude",
                    palette: palette,
                    isMain: isMain,
                    variantIndex: variantIndex,
                    state: .working,
                    activity: nil,
                    startedAt: now,
                    lastEventAt: now
                )
                mutate(&run)
                list.append(run)
            }
        }

        switch event.type {
        case .agentCreated:
            guard !list.contains(where: { $0.id == event.agentId }) else { return }
            let name = event.name ?? NSLocalizedString("Sub-agent", comment: "Fallback name for an unnamed subagent")
            upsert(event.agentId, name: name, palette: event.palette ?? 1, isMain: false, variantIndex: Self.nextVariantIndex(for: name, in: list))

        case .agentRemoved:
            list.removeAll { $0.id == event.agentId }

        case .agentToolStart:
            upsert(event.agentId, name: event.name) { run in
                run.activity = event.activity ?? run.activity
                if run.state == .stalled { run.state = .working }
            }
            if event.agentId == "main", state(for: wsID) == .stalled {
                states[wsID] = .working
            }

        case .agentToolDone:
            if let idx = list.firstIndex(where: { $0.id == event.agentId }) {
                list[idx].activity = nil
                list[idx].lastEventAt = now
            }

        case .agentWaiting:
            upsert(event.agentId, name: event.name)

        case .agentIdle:
            // Main going idle ends the whole turn; a child idling removes only
            // that child.
            if event.agentId == "main" {
                list.removeAll()
            } else {
                list.removeAll { $0.id == event.agentId }
            }

        case .agentStatus:
            // Permission prompts don't change the roster; the sweep skips
            // workstreams whose main agent is awaiting the user.
            break
        }

        if list.isEmpty {
            rosters.removeValue(forKey: wsID)
        } else {
            // Main agent first so the sidebar reads top-down.
            list.sort { ($0.isMain ? 0 : 1, $0.startedAt) < ($1.isMain ? 0 : 1, $1.startedAt) }
            rosters[wsID] = list
        }
    }

    private func updateMainState(wsID: UUID, event: AgentEvent) {
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

    // MARK: - Variant Assignment

    /// Lowest variant index not held by a live run of the same type. Cycling
    /// happens at render time (`variantIndex % setCount`), so indices beyond
    /// the sprite count wrap back to the first sprite.
    static func nextVariantIndex(for name: String, in runs: [AgentRun]) -> Int {
        let key = AgentSpriteStore.normalizeTypeName(name)
        let used = Set(runs.filter { AgentSpriteStore.normalizeTypeName($0.name) == key }.map(\.variantIndex))
        var index = 0
        while used.contains(index) { index += 1 }
        return index
    }

    // MARK: - Stall Detection

    private func ensureSweepTimer() {
        guard sweepTimer == nil else { return }
        let timer = Timer(timeInterval: Self.sweepInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.sweepForStalls()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        sweepTimer = timer
    }

    /// Marks runs stalled when they haven't emitted an event since `now - stallThreshold`.
    /// Internal (not private) so tests can sweep with backdated timestamps.
    func sweepForStalls(now: Date = Date()) {
        let cutoff = now.addingTimeInterval(-Self.stallThreshold)
        for (wsID, list) in rosters {
            var updated = list
            var changed = false
            let rowState = states[wsID] ?? .idle
            for idx in updated.indices {
                guard updated[idx].state == .working, updated[idx].lastEventAt < cutoff else { continue }
                // Waiting on the user isn't stalling.
                if case .needsAttention(.permission) = rowState { continue }
                updated[idx].state = .stalled
                changed = true
            }
            guard changed else { continue }
            rosters[wsID] = updated
            // Surface a stalled main run at the row level unless something
            // more important already needs attention there.
            if updated.contains(where: { $0.isMain && $0.state == .stalled }),
               case .working = rowState
            {
                states[wsID] = .stalled
            }
        }
    }
}
