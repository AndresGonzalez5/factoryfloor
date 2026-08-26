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
        /// Display name ("Claude"/"OpenCode" or the subagent type). Mutable:
        /// later events may refine it once the harness reports the agent type.
        var name: String
        let palette: Int
        let isMain: Bool
        /// Per-type occurrence slot: the lowest index not held by a live
        /// same-type run at creation. Drives sprite-set cycling in the roster
        /// (sprite shown is `variantIndex % setCount`).
        let variantIndex: Int
        var state: RunState
        /// What the agent is doing right now, e.g. "Editing Foo.swift".
        var activity: String?
        /// Model backing the run when the harness reports one.
        var model: String?
        /// Per-run context figures when the harness reports them directly
        /// (e.g. OpenCode child sessions via agent_info).
        var contextUsedTokens: Int?
        var contextLimitTokens: Int?
        /// Short task description the harness attaches to delegated subagents
        /// (OpenCode subtask parts); rendered as a roster subtitle. Kept out of
        /// `name` so sprite selection keeps keying off the agent type.
        var taskDescription: String?
        let startedAt: Date
        var lastEventAt: Date
    }

    /// Context-window consumption of a workstream's main session.
    struct ContextUsage: Equatable {
        let usedTokens: Int
        let limitTokens: Int
        var fraction: Double {
            limitTokens > 0 ? Double(usedTokens) / Double(limitTokens) : 0
        }
    }

    static let stallThreshold: TimeInterval = 45
    private static let sweepInterval: TimeInterval = 15
    private static let contextReadInterval: TimeInterval = 5

    @Published private(set) var states: [UUID: AgentRunState] = [:]
    @Published private(set) var rosters: [UUID: [AgentRun]] = [:]
    /// Workstreams that have seen harness activity during this app launch.
    /// In-memory only by design ("part of my work today").
    @Published private(set) var liveSessionIDs: Set<UUID> = []
    /// Latest known context-window usage for each workstream's MAIN session.
    @Published private(set) var contextUsage: [UUID: ContextUsage] = [:]

    private var lastContextReadAt: [UUID: Date] = [:]

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

    /// True while the workstream has seen harness activity this app launch.
    func hasLiveSession(for id: UUID) -> Bool {
        liveSessionIDs.contains(id)
    }

    /// Context usage of the workstream's main session, regardless of harness:
    /// prefers the transcript-derived figure (Claude Code), falling back to
    /// the per-run totals the harness reported (OpenCode `agent_info`).
    /// Returns nil while no main run is live or nothing has been reported yet.
    func mainContextUsage(for id: UUID) -> ContextUsage? {
        if let rowLevel = contextUsage[id] { return rowLevel }
        guard let main = rosters[id]?.first(where: { $0.isMain }),
              let used = main.contextUsedTokens,
              let limit = main.contextLimitTokens,
              limit > 0 else { return nil }
        return ContextUsage(usedTokens: used, limitTokens: limit)
    }

    /// Drops all tracked state for a workstream (called when it is removed).
    func clear(workstreamID: UUID) {
        states.removeValue(forKey: workstreamID)
        rosters.removeValue(forKey: workstreamID)
        liveSessionIDs.remove(workstreamID)
        contextUsage.removeValue(forKey: workstreamID)
        lastContextReadAt.removeValue(forKey: workstreamID)
    }

    /// Clears every tracked state. Used by tests to isolate cases.
    func resetForTesting() {
        states.removeAll()
        rosters.removeAll()
        liveSessionIDs.removeAll()
        contextUsage.removeAll()
        lastContextReadAt.removeAll()
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
        liveSessionIDs.insert(wsID)
        updateRoster(wsID: wsID, event: event)
        if event.agentId == "main" {
            updateMainState(wsID: wsID, event: event)
            if let transcriptPath = event.transcriptPath {
                refreshContextUsage(wsID: wsID, transcriptPath: transcriptPath, force: event.type == .agentIdle)
            }
        }
    }

    private func updateRoster(wsID: UUID, event: AgentEvent) {
        let now = Date()
        var list = rosters[wsID] ?? []

        func upsert(_ agentId: String, name: String? = nil, palette: Int = 0, isMain: Bool = true, variantIndex: Int = 0, mutate: (inout AgentRun) -> Void = { _ in }) {
            if let idx = list.firstIndex(where: { $0.id == agentId }) {
                mutate(&list[idx])
                // Harnesses may report the display name after a run's first
                // event (e.g. OpenCode child sessions); apply refinements.
                if let name, !name.isEmpty, name != list[idx].name {
                    list[idx].name = name
                }
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
                    model: nil,
                    startedAt: now,
                    lastEventAt: now
                )
                mutate(&run)
                list.append(run)
            }
        }

        switch event.type {
        case .agentCreated:
            // A duplicate create (OpenCode re-forwards the subtask part to
            // enrich an already-registered child) refines the existing run's
            // attributes instead of recreating it.
            let fallbackName = NSLocalizedString("Sub-agent", comment: "Fallback name for an unnamed subagent")
            let name = event.name ?? fallbackName
            let isNew = !list.contains(where: { $0.id == event.agentId })
            upsert(
                event.agentId,
                name: name,
                palette: event.palette ?? 1,
                isMain: false,
                variantIndex: isNew ? Self.nextVariantIndex(for: name, in: list) : 0
            ) { run in
                if let description = event.taskDescription, !description.isEmpty {
                    run.taskDescription = description
                }
            }

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

        case .agentInfo:
            // Attribute-only refresh: update an existing run's name/model
            // without touching state. Info can also arrive before any tool
            // or prompt event (OpenCode streams message.updated early); in
            // that case create the MAIN run so its context figures land —
            // subagents are still never created from info alone.
            if event.agentId == "main", !list.contains(where: { $0.id == "main" }) {
                upsert("main", name: event.name) { run in
                    run.model = event.model ?? run.model
                    run.contextUsedTokens = event.contextUsedTokens ?? run.contextUsedTokens
                    run.contextLimitTokens = event.contextLimitTokens ?? run.contextLimitTokens
                }
            } else if let idx = list.firstIndex(where: { $0.id == event.agentId }) {
                if let name = event.name, !name.isEmpty, name != list[idx].name {
                    list[idx].name = name
                }
                if let model = event.model {
                    list[idx].model = model
                }
                if let used = event.contextUsedTokens {
                    list[idx].contextUsedTokens = used
                }
                if let limit = event.contextLimitTokens {
                    list[idx].contextLimitTokens = limit
                }
                list[idx].lastEventAt = now
            }

        case .agentIdle:
            // Main going idle ends the whole turn; a child idling removes
            // only that child. Snapshot the main run's last known context
            // figures first — OpenCode reports them per-run only, and the
            // roster is about to clear, but the row keeps showing usage
            // until the next turn.
            if event.agentId == "main" {
                if let main = list.first(where: \.isMain),
                   let used = main.contextUsedTokens,
                   let limit = main.contextLimitTokens,
                   limit > 0 {
                    contextUsage[wsID] = ContextUsage(usedTokens: used, limitTokens: limit)
                }
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

    /// Reads context usage from the transcript tail. Throttled to one read per
    /// `contextReadInterval` — except at turn end (idle), where the final
    /// totals must land even if a read just happened. A failed read keeps any
    /// previous value.
    private func refreshContextUsage(wsID: UUID, transcriptPath: String, force: Bool) {
        let now = Date()
        if !force, let last = lastContextReadAt[wsID], now.timeIntervalSince(last) < Self.contextReadInterval {
            return
        }
        lastContextReadAt[wsID] = now
        guard let parsed = TranscriptContextReader.usage(transcriptPath: transcriptPath) else { return }
        contextUsage[wsID] = ContextUsage(usedTokens: parsed.usedTokens, limitTokens: parsed.limitTokens)
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

        case .agentCreated, .agentRemoved, .agentInfo:
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
            // Surface a stalled main run at row level unless something more
            // important already needs attention there. A fresh sibling run
            // (a live subagent) means the workstream is still actively
            // working through it — keep the row Working.
            let hasFreshActivity = updated.contains { run in
                run.state == .working && run.lastEventAt >= cutoff
            }
            if updated.contains(where: { $0.isMain && $0.state == .stalled }),
               !hasFreshActivity,
               case .working = rowState
            {
                states[wsID] = .stalled
            }
        }
    }
}
