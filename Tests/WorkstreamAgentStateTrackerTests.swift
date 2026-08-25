// ABOUTME: Tests for the per-workstream agent roster and row-level state machine.
// ABOUTME: Covers run lifecycle, activity text, permission handling, and stall sweeping.

@testable import FactoryFloor
import XCTest

@MainActor
final class WorkstreamAgentStateTrackerTests: XCTestCase {
    private let wsID = UUID()
    private let projectDir = "/tmp/factoryfloor-test-worktree"

    private var tracker: WorkstreamAgentStateTracker { WorkstreamAgentStateTracker.shared }

    override func setUp() {
        super.setUp()
        tracker.resetForTesting()
    }

    override func tearDown() {
        tracker.resetForTesting()
        super.tearDown()
    }

    /// Routes an event through the tracker, installing the lookup mapping on first use.
    private func handle(_ event: AgentEvent) {
        if tracker.workstreamLookup == nil {
            let expected = WorkstreamAgentStateTracker.normalize(projectDir)
            let mapped = wsID
            tracker.workstreamLookup = { dir in
                WorkstreamAgentStateTracker.normalize(dir) == expected ? mapped : nil
            }
        }
        tracker.handle(projectDir: projectDir, event: event)
    }

    private func backdateMainRun(secondsAgo: TimeInterval) {
        tracker._backdateRun(
            agentId: "main",
            workstreamID: wsID,
            lastEventAt: Date().addingTimeInterval(-secondsAgo)
        )
    }

    // MARK: - Run lifecycle

    func testPromptSubmitCreatesMainRun() {
        handle(.waiting(agentId: "main"))
        let runs = tracker.runs(for: wsID)
        XCTAssertEqual(runs.count, 1)
        XCTAssertTrue(runs[0].isMain)
        XCTAssertEqual(runs[0].name, "Claude")
        XCTAssertEqual(tracker.activeRunCount(for: wsID), 1)
    }

    func testStopRemovesMainRun() {
        handle(.waiting(agentId: "main"))
        handle(.idle(agentId: "main"))
        XCTAssertEqual(tracker.activeRunCount(for: wsID), 0)
    }

    func testSubagentStartStopLifecycle() {
        handle(.created(agentId: "sub-1", name: "Explore", palette: 2))
        var runs = tracker.runs(for: wsID)
        XCTAssertEqual(runs.count, 1)
        XCTAssertFalse(runs[0].isMain)
        XCTAssertEqual(runs[0].name, "Explore")
        XCTAssertEqual(runs[0].palette, 2)

        handle(.removed(agentId: "sub-1"))
        runs = tracker.runs(for: wsID)
        XCTAssertTrue(runs.isEmpty)
    }

    func testDuplicateSubagentStartDoesNotDuplicateRun() {
        handle(.created(agentId: "sub-1", name: "Explore", palette: 1))
        handle(.created(agentId: "sub-1", name: "Explore", palette: 1))
        XCTAssertEqual(tracker.activeRunCount(for: wsID), 1)
    }

    func testMainRunSortsFirstAmongSubagents() {
        handle(.waiting(agentId: "main"))
        handle(.created(agentId: "sub-a", name: "Explore", palette: 1))
        handle(.created(agentId: "sub-b", name: "Plan", palette: 2))
        let runs = tracker.runs(for: wsID)
        XCTAssertEqual(runs.map(\.id), ["main", "sub-a", "sub-b"])
    }

    func testEventsOutsideTrackedWorkstreamsAreIgnored() {
        tracker.workstreamLookup = { _ in nil }
        handle(.waiting(agentId: "main"))
        handle(.created(agentId: "sub-1", name: "Explore", palette: 1))
        XCTAssertEqual(tracker.activeRunCount(for: wsID), 0)
    }

    // MARK: - Activity

    func testToolStartSetsActivityAndToolDoneClearsIt() {
        handle(.waiting(agentId: "main"))
        handle(.toolStart(agentId: "main", tool: "Edit", activity: "Editing Foo.swift"))
        XCTAssertEqual(tracker.runs(for: wsID).first?.activity, "Editing Foo.swift")

        handle(.toolDone(agentId: "main"))
        XCTAssertNil(tracker.runs(for: wsID).first?.activity)
    }

    func testSubagentActivityIsTrackedSeparately() {
        handle(.created(agentId: "sub-1", name: "Explore", palette: 1))
        handle(.toolStart(agentId: "sub-1", tool: "Grep", activity: "Searching"))
        let sub = tracker.runs(for: wsID).first(where: { $0.id == "sub-1" })
        XCTAssertEqual(sub?.activity, "Searching")
    }

    // MARK: - Row-level state

    func testPromptSubmitMarksRowWorking() {
        handle(.waiting(agentId: "main"))
        XCTAssertEqual(tracker.state(for: wsID), .working)
    }

    func testStopOnUnselectedWorkstreamNeedsAttention() {
        handle(.waiting(agentId: "main"))
        handle(.idle(agentId: "main"))
        XCTAssertEqual(tracker.state(for: wsID), .needsAttention(.justFinished))
    }

    func testStopOnSelectedWorkstreamGoesIdle() {
        tracker.currentSelection = wsID
        handle(.waiting(agentId: "main"))
        handle(.idle(agentId: "main"))
        XCTAssertEqual(tracker.state(for: wsID), .idle)
    }

    func testPermissionStatusThenToolActivityResumesWorking() {
        tracker.currentSelection = wsID
        handle(.status(agentId: "main", status: "permissionRequired"))
        XCTAssertEqual(tracker.state(for: wsID), .needsAttention(.permission))

        // Tool activity implies the user answered the prompt.
        handle(.toolStart(agentId: "main", tool: "Bash"))
        XCTAssertEqual(tracker.state(for: wsID), .working)
    }

    func testMarkSeenClearsJustFinishedButKeepsPermission() {
        handle(.idle(agentId: "main"))
        tracker.markSeen(workstreamID: wsID)
        XCTAssertEqual(tracker.state(for: wsID), .idle)

        handle(.status(agentId: "main", status: "permissionRequired"))
        tracker.markSeen(workstreamID: wsID)
        XCTAssertEqual(tracker.state(for: wsID), .needsAttention(.permission))
    }

    // MARK: - Stall detection

    func testStaleRunSweepsToStalled() {
        handle(.waiting(agentId: "main"))
        backdateMainRun(secondsAgo: WorkstreamAgentStateTracker.stallThreshold + 10)

        tracker.sweepForStalls(now: Date())
        XCTAssertEqual(tracker.runs(for: wsID)[0].state, .stalled)
        XCTAssertEqual(tracker.state(for: wsID), .stalled)
    }

    func testFreshRunDoesNotStall() {
        handle(.waiting(agentId: "main"))
        backdateMainRun(secondsAgo: 5)

        tracker.sweepForStalls(now: Date())
        XCTAssertEqual(tracker.runs(for: wsID)[0].state, .working)
        XCTAssertEqual(tracker.state(for: wsID), .working)
    }

    func testStalledSweepSkippedWhileAwaitingPermission() {
        tracker.currentSelection = wsID
        handle(.waiting(agentId: "main"))
        handle(.status(agentId: "main", status: "permissionRequired"))
        backdateMainRun(secondsAgo: WorkstreamAgentStateTracker.stallThreshold + 10)

        tracker.sweepForStalls(now: Date())
        // Waiting on the user is not stalling.
        XCTAssertEqual(tracker.runs(for: wsID)[0].state, .working)
    }

    func testToolStartUnstallsRunAndRow() {
        handle(.waiting(agentId: "main"))
        backdateMainRun(secondsAgo: WorkstreamAgentStateTracker.stallThreshold + 10)
        tracker.sweepForStalls(now: Date())
        XCTAssertEqual(tracker.state(for: wsID), .stalled)

        handle(.toolStart(agentId: "main", tool: "Read", activity: "Reading Bar.swift"))
        XCTAssertEqual(tracker.runs(for: wsID)[0].state, .working)
        XCTAssertEqual(tracker.state(for: wsID), .working)
    }

    /// A stale main run waiting on a live subagent is delegation, not a
    /// stall — the row keeps its Working state until the whole workstream
    /// goes quiet.
    func testFreshSubagentKeepsRowWorkingWhenMainGoesQuiet() {
        handle(.waiting(agentId: "main"))
        handle(.created(agentId: "ses_build", name: "build", palette: 1))
        backdateMainRun(secondsAgo: WorkstreamAgentStateTracker.stallThreshold + 10)

        tracker.sweepForStalls(now: Date())
        XCTAssertEqual(tracker.runs(for: wsID).first { $0.isMain }?.state, .stalled)
        XCTAssertEqual(tracker.state(for: wsID), .working)

        // Once the subagent goes quiet too, the row stalls.
        tracker._backdateRun(
            agentId: "ses_build",
            workstreamID: wsID,
            lastEventAt: Date().addingTimeInterval(-(WorkstreamAgentStateTracker.stallThreshold + 10))
        )
        tracker.sweepForStalls(now: Date())
        XCTAssertEqual(tracker.state(for: wsID), .stalled)
    }

    /// The main run's final context figures must outlive the roster clear
    /// at turn end so the row's context bar persists at Done/Idle.
    func testContextUsageSurvivesMainIdle() {
        handle(AgentEvent.info(
            agentId: "main",
            name: "OpenCode",
            model: "claude-sonnet-4-5",
            contextUsedTokens: 42_000
        ))
        XCTAssertNotNil(tracker.mainContextUsage(for: wsID))

        handle(.idle(agentId: "main"))
        XCTAssertTrue(tracker.runs(for: wsID).isEmpty)

        let usage = tracker.mainContextUsage(for: wsID)
        XCTAssertNotNil(usage)
        XCTAssertEqual(usage?.usedTokens, 42_000)
        XCTAssertEqual(usage?.limitTokens, 200_000)
    }

    // MARK: - Variant assignment

    func testVariantIndicesAssignedPerType() {
        handle(.created(agentId: "e1", name: "Explore", palette: 1))
        handle(.created(agentId: "e2", name: "Explore", palette: 2))
        handle(.created(agentId: "g1", name: "general-purpose", palette: 3))
        let runs = tracker.runs(for: wsID)
        XCTAssertEqual(runs.first(where: { $0.id == "e1" })?.variantIndex, 0)
        XCTAssertEqual(runs.first(where: { $0.id == "e2" })?.variantIndex, 1)
        // Independent sequence per type.
        XCTAssertEqual(runs.first(where: { $0.id == "g1" })?.variantIndex, 0)
    }

    func testFreedVariantIndexIsReused() {
        handle(.created(agentId: "e1", name: "Explore", palette: 1))
        handle(.created(agentId: "e2", name: "Explore", palette: 1))
        handle(.created(agentId: "e3", name: "Explore", palette: 1))
        handle(.removed(agentId: "e2"))
        handle(.created(agentId: "e4", name: "Explore", palette: 1))
        XCTAssertEqual(tracker.runs(for: wsID).first(where: { $0.id == "e4" })?.variantIndex, 1)
    }

    func testVariantIndicesKeepCountingWhenOverCapacity() {
        for i in 1...5 {
            handle(.created(agentId: "e\(i)", name: "Explore", palette: 1))
        }
        let variants = tracker.runs(for: wsID).map(\.variantIndex).sorted()
        // Raw indices keep counting; cycling to sprite 1 happens at render time.
        XCTAssertEqual(variants, [0, 1, 2, 3, 4])
    }

    func testVariantIndexIsStableForRunLifetime() {
        handle(.created(agentId: "e1", name: "Explore", palette: 1))
        handle(.toolStart(agentId: "e1", tool: "Grep", activity: "Searching"))
        XCTAssertEqual(tracker.runs(for: wsID).first?.variantIndex, 0)
    }

    func testMainAgentVariantIsZero() {
        handle(.waiting(agentId: "main"))
        XCTAssertEqual(tracker.runs(for: wsID).first?.variantIndex, 0)
    }

    func testNextVariantIndexMatchesNormalizedTypeNames() {
        var runs = tracker.runs(for: wsID)
        runs = [
            run(name: "Explore", variant: 0),
            run(name: "explore", variant: 2),
        ]
        XCTAssertEqual(WorkstreamAgentStateTracker.nextVariantIndex(for: "Explore", in: runs), 1)
        XCTAssertEqual(WorkstreamAgentStateTracker.nextVariantIndex(for: "general-purpose", in: runs), 0)
    }

    private func run(name: String, variant: Int) -> WorkstreamAgentStateTracker.AgentRun {
        WorkstreamAgentStateTracker.AgentRun(
            id: name + String(variant),
            name: name,
            palette: 1,
            isMain: false,
            variantIndex: variant,
            state: .working,
            activity: nil,
            startedAt: Date(),
            lastEventAt: Date()
        )
    }

    // MARK: - Cleanup

    func testClearRemovesAllStateForWorkstream() {
        handle(.waiting(agentId: "main"))
        handle(.created(agentId: "sub-1", name: "Explore", palette: 1))
        tracker.clear(workstreamID: wsID)
        XCTAssertEqual(tracker.activeRunCount(for: wsID), 0)
        XCTAssertEqual(tracker.state(for: wsID), .idle)
    }

    // MARK: - Activity description mapping

    func testActivityDescriptionMapping() {
        let filePathInput: [String: Any] = ["file_path": "/repo/Sources/Foo.swift"]
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "Edit", toolInput: filePathInput), String(format: NSLocalizedString("Editing %@", comment: ""), "Foo.swift"))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "Read", toolInput: filePathInput), String(format: NSLocalizedString("Reading %@", comment: ""), "Foo.swift"))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "Grep", toolInput: nil), NSLocalizedString("Searching", comment: ""))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "Bash", toolInput: nil), NSLocalizedString("Running command", comment: ""))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "WebFetch", toolInput: nil), NSLocalizedString("Browsing", comment: ""))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "TodoWrite", toolInput: nil), NSLocalizedString("Planning", comment: ""))
        // Unknown tools surface verbatim so the row always says something specific.
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "SomeCustomTool", toolInput: nil), "SomeCustomTool")
    }

    // MARK: - OpenCode (lowercase tool names, per-harness run names)

    func testActivityDescriptionMatchesLowercaseOpencodeTools() {
        let filePathInput: [String: Any] = ["file_path": "/repo/Sources/Foo.swift"]
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "edit", toolInput: filePathInput), String(format: NSLocalizedString("Editing %@", comment: ""), "Foo.swift"))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "read", toolInput: filePathInput), String(format: NSLocalizedString("Reading %@", comment: ""), "Foo.swift"))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "grep", toolInput: nil), NSLocalizedString("Searching", comment: ""))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "bash", toolInput: nil), NSLocalizedString("Running command", comment: ""))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "todowrite", toolInput: nil), NSLocalizedString("Planning", comment: ""))
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "task", toolInput: nil), NSLocalizedString("Delegating", comment: ""))
    }

    /// Unmapped custom/MCP tools surface verbatim so the row always shows
    /// something specific; an empty name still yields no activity.
    func testActivityDescriptionFallsBackToToolNameVerbatim() {
        XCTAssertEqual(HookEventReceiver.activityDescription(toolName: "mcp_custom_lookup", toolInput: nil), "mcp_custom_lookup")
        XCTAssertNil(HookEventReceiver.activityDescription(toolName: "", toolInput: nil))
    }

    func testOpencodeRunUsesProvidedHarnessName() {
        var event = AgentEvent.waiting(agentId: "main")
        event.name = "OpenCode"
        handle(event)
        XCTAssertEqual(tracker.runs(for: wsID).first?.name, "OpenCode")
    }

    /// OpenCode's message.updated can precede any tool/prompt event; the
    /// info-only event must still create the main run so its context
    /// figures land and the row's context bar can appear.
    func testAgentInfoCreatesMissingMainRunWithContext() {
        handle(AgentEvent.info(
            agentId: "main",
            name: "OpenCode",
            model: "claude-sonnet-4-5",
            contextUsedTokens: 42_000
        ))
        let runs = tracker.runs(for: wsID)
        XCTAssertEqual(runs.count, 1)
        XCTAssertTrue(runs[0].isMain)
        XCTAssertEqual(runs[0].name, "OpenCode")
        XCTAssertEqual(runs[0].model, "claude-sonnet-4-5")
        XCTAssertEqual(runs[0].contextUsedTokens, 42_000)
        XCTAssertEqual(runs[0].contextLimitTokens, 200_000)
        XCTAssertNotNil(tracker.mainContextUsage(for: wsID))
    }

    /// Subagents are never created from attribute-only events — that path
    /// must not produce ghost roster entries.
    func testAgentInfoDoesNotCreateSubagentRuns() {
        handle(AgentEvent.info(
            agentId: "ses_child",
            name: "Explore",
            model: "claude-sonnet-4-5",
            contextUsedTokens: 1_000
        ))
        XCTAssertTrue(tracker.runs(for: wsID).isEmpty)
    }

    func testChildIdleRemovesOnlyThatChild() {
        handle(.waiting(agentId: "main"))
        handle(.created(agentId: "ses_child", name: "Explore", palette: 1))
        handle(.idle(agentId: "ses_child"))
        XCTAssertEqual(tracker.runs(for: wsID).map(\.id), ["main"])
    }

    func testMainIdleClearsRemainingChildren() {
        handle(.waiting(agentId: "main"))
        handle(.created(agentId: "ses_a", name: "Explore", palette: 1))
        handle(.idle(agentId: "main"))
        XCTAssertEqual(tracker.activeRunCount(for: wsID), 0)
    }

    // MARK: - Name and attribute refinement

    func testToolStartCreatesRunWithCarriedName() {
        var event = AgentEvent.toolStart(agentId: "ses_child", tool: "edit")
        event.name = "build"
        handle(event)
        XCTAssertEqual(tracker.runs(for: wsID).first?.name, "build")
    }

    func testSubsequentEventRefinesExistingRunName() {
        var first = AgentEvent.toolStart(agentId: "ses_child", tool: "bash")
        first.name = "OpenCode"
        handle(first)
        XCTAssertEqual(tracker.runs(for: wsID).first?.name, "OpenCode")

        // The plugin reports the real agent type once known.
        var second = AgentEvent.toolStart(agentId: "ses_child", tool: "read")
        second.name = "general"
        handle(second)
        XCTAssertEqual(tracker.runs(for: wsID).first?.name, "general")
    }

    func testAgentInfoStoresModelOnExistingRun() {
        handle(.waiting(agentId: "main"))
        handle(AgentEvent.info(agentId: "main", name: "OpenCode", model: "claude-sonnet-4-5"))
        let run = tracker.runs(for: wsID).first
        XCTAssertEqual(run?.name, "OpenCode")
        XCTAssertEqual(run?.model, "claude-sonnet-4-5")
        XCTAssertEqual(tracker.state(for: wsID), .working)
    }

    /// Attribute-only events may create the MAIN run (so OpenCode's early
    /// message.updated context lands) but never subagent runs.
    func testAgentInfoDoesNotCreateSubagentGhostRuns() {
        handle(AgentEvent.info(agentId: "main", name: "OpenCode", model: "m"))
        handle(AgentEvent.info(agentId: "ses_unknown", name: "build", model: "m"))
        XCTAssertEqual(tracker.runs(for: wsID).map(\.id), ["main"])
        XCTAssertTrue(tracker.runs(for: wsID)[0].isMain)
        XCTAssertEqual(tracker.state(for: wsID), .idle)
    }

    func testAgentInfoDoesNotClearPermissionState() {
        tracker.currentSelection = wsID
        handle(.waiting(agentId: "main"))
        handle(.status(agentId: "main", status: "permissionRequired"))
        handle(AgentEvent.info(agentId: "main", name: "OpenCode", model: "m"))
        XCTAssertEqual(tracker.state(for: wsID), .needsAttention(.permission))
    }

    func testAgentInfoRefreshesLastEventAt() {
        handle(.waiting(agentId: "main"))
        backdateMainRun(secondsAgo: 30)
        handle(AgentEvent.info(agentId: "main", name: "OpenCode", model: "m"))
        // If lastEventAt were not refreshed the next sweep would stall the run.
        let cutoff = Date().addingTimeInterval(-WorkstreamAgentStateTracker.stallThreshold)
        XCTAssertGreaterThan(tracker.runs(for: wsID)[0].lastEventAt, cutoff)
    }

    // MARK: - Live session presence

    func testHasLiveSessionIsFalseByDefault() {
        XCTAssertFalse(tracker.hasLiveSession(for: wsID))
        XCTAssertTrue(tracker.liveSessionIDs.isEmpty)
    }

    func testHandledEventMarksLiveSession() {
        handle(.waiting(agentId: "main"))
        XCTAssertTrue(tracker.hasLiveSession(for: wsID))
        XCTAssertTrue(tracker.liveSessionIDs.contains(wsID))
    }

    func testClearRemovesLiveSessionFlag() {
        handle(.waiting(agentId: "main"))
        tracker.clear(workstreamID: wsID)
        XCTAssertFalse(tracker.hasLiveSession(for: wsID))
    }

    // MARK: - Context-window usage

    private func tempTranscriptURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ff-tracker-tests-\(UUID().uuidString).jsonl")
    }

    private func writeTranscript(url: URL, usedTokens: Int, model: String = "claude-sonnet-4-5") throws {
        let line = "{\"type\":\"assistant\",\"message\":{\"model\":\"\(model)\",\"usage\":{\"input_tokens\":\(usedTokens),\"cache_creation_input_tokens\":0,\"cache_read_input_tokens\":0}}}"
        try line.write(to: url, atomically: true, encoding: .utf8)
    }

    func testTranscriptPathPopulatesContextUsage() throws {
        let url = tempTranscriptURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try writeTranscript(url: url, usedTokens: 1234)

        handle(.waiting(agentId: "main", transcriptPath: url.path))

        let usage = try XCTUnwrap(tracker.contextUsage[wsID])
        XCTAssertEqual(usage.usedTokens, 1234)
        XCTAssertEqual(usage.limitTokens, 200_000)
        XCTAssertEqual(usage.fraction, Double(1234) / 200_000, accuracy: 1e-12)
    }

    func testContextUsageReadIsThrottledWithinFiveSeconds() throws {
        let url = tempTranscriptURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try writeTranscript(url: url, usedTokens: 100)

        handle(.waiting(agentId: "main", transcriptPath: url.path))
        XCTAssertEqual(tracker.contextUsage[wsID]?.usedTokens, 100)

        // Rewrite the transcript; the throttle must skip the re-read.
        try writeTranscript(url: url, usedTokens: 9000)
        handle(.toolStart(agentId: "main", tool: "Bash", transcriptPath: url.path))
        XCTAssertEqual(tracker.contextUsage[wsID]?.usedTokens, 100)
    }

    func testAgentIdleAlwaysRereadsTranscript() throws {
        let url = tempTranscriptURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try writeTranscript(url: url, usedTokens: 100)
        handle(.waiting(agentId: "main", transcriptPath: url.path))

        try writeTranscript(url: url, usedTokens: 9000)
        handle(.idle(agentId: "main", transcriptPath: url.path))
        XCTAssertEqual(tracker.contextUsage[wsID]?.usedTokens, 9000)
    }

    func testFailedReadKeepsPreviousContextUsage() throws {
        let url = tempTranscriptURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try writeTranscript(url: url, usedTokens: 100)
        handle(.waiting(agentId: "main", transcriptPath: url.path))
        XCTAssertEqual(tracker.contextUsage[wsID]?.usedTokens, 100)

        // Remove the file so the forced idle re-read fails; the previous
        // value must stick.
        try FileManager.default.removeItem(at: url)
        handle(.idle(agentId: "main", transcriptPath: url.path))
        XCTAssertEqual(tracker.contextUsage[wsID]?.usedTokens, 100)
    }

    func testClearRemovesLiveSessionAndContextUsage() throws {
        let url = tempTranscriptURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try writeTranscript(url: url, usedTokens: 10)
        handle(.waiting(agentId: "main", transcriptPath: url.path))
        XCTAssertTrue(tracker.hasLiveSession(for: wsID))
        XCTAssertNotNil(tracker.contextUsage[wsID])

        tracker.clear(workstreamID: wsID)
        XCTAssertFalse(tracker.hasLiveSession(for: wsID))
        XCTAssertNil(tracker.contextUsage[wsID])
    }

    func testAgentInfoAppliesContextFieldsToRun() {
        handle(.waiting(agentId: "main"))
        handle(AgentEvent.info(
            agentId: "main",
            name: "OpenCode",
            model: "claude-sonnet-4-5",
            contextUsedTokens: 42_000
        ))
        let run = tracker.runs(for: wsID).first
        XCTAssertEqual(run?.contextUsedTokens, 42_000)
        XCTAssertEqual(run?.contextLimitTokens, 200_000)
    }

    func testMainContextUsageFallsBackToRunReportedTokens() {
        handle(.waiting(agentId: "main"))
        handle(AgentEvent.info(
            agentId: "main",
            name: "OpenCode",
            model: "claude-sonnet-4-5",
            contextUsedTokens: 42_000
        ))

        let usage = tracker.mainContextUsage(for: wsID)
        XCTAssertEqual(usage?.usedTokens, 42_000)
        XCTAssertEqual(usage?.limitTokens, 200_000)
    }

    func testMainContextUsagePrefersTranscriptOverRunTokens() throws {
        let url = tempTranscriptURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try writeTranscript(url: url, usedTokens: 100)
        handle(.waiting(agentId: "main", transcriptPath: url.path))
        handle(AgentEvent.info(
            agentId: "main",
            name: "OpenCode",
            model: "claude-sonnet-4-5",
            contextUsedTokens: 42_000
        ))

        XCTAssertEqual(tracker.mainContextUsage(for: wsID)?.usedTokens, 100)
    }

    /// Usage is nil until the harness has reported figures — but once it
    /// has, the last reading persists past turn end (the row's bar dims
    /// instead of vanishing at Done/Idle).
    func testMainContextUsageNilUntilReportedThenPersists() {
        XCTAssertNil(tracker.mainContextUsage(for: wsID))

        handle(.waiting(agentId: "main"))
        handle(AgentEvent.info(
            agentId: "main",
            name: "OpenCode",
            model: "claude-sonnet-4-5",
            contextUsedTokens: 42_000
        ))
        handle(.idle(agentId: "main"))

        let usage = tracker.mainContextUsage(for: wsID)
        XCTAssertEqual(usage?.usedTokens, 42_000)
    }
}
