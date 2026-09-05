// ABOUTME: Workspace view with dynamic tabs for agent, terminals, and browsers.
// ABOUTME: Info and Agent are always present; terminals and browsers are added on demand.

import os
import SwiftUI
import WebKit

private let logger = Logger(subsystem: "factoryfloor", category: "surface-cache")

extension Notification.Name {
    static let terminalSurfaceClosed = Notification.Name("factoryfloor.terminalSurfaceClosed")
    static let toggleInfo = Notification.Name("factoryfloor.toggleInfo")
    static let toggleTerminal = Notification.Name("factoryfloor.toggleTerminal")
    static let toggleBrowser = Notification.Name("factoryfloor.toggleBrowser")
    static let focusAgent = Notification.Name("factoryfloor.focusAgent")
    static let closeTerminal = Notification.Name("factoryfloor.closeTerminal")
    static let nextTab = Notification.Name("factoryfloor.nextTab")
    static let prevTab = Notification.Name("factoryfloor.prevTab")
    static let terminalTitleChanged = Notification.Name("factoryfloor.terminalTitleChanged")
    static let toggleEditor = Notification.Name("factoryfloor.toggleEditor")
    static let toggleChanges = Notification.Name("factoryfloor.toggleChanges")
    static let saveEditor = Notification.Name("factoryfloor.saveEditor")
    static let saveEditorAs = Notification.Name("factoryfloor.saveEditorAs")
    static let toggleFileFinder = Notification.Name("factoryfloor.toggleFileFinder")
}

enum RestorableWorkspaceTab: String, Codable {
    case info
    case agent
    case environment
    case changes

    init(activeTab: WorkspaceTab) {
        switch activeTab {
        case .agent:
            self = .agent
        case .changes:
            self = .changes
        case .info, .terminal, .browser, .editor:
            self = .info
        }
    }

    func workspaceTab() -> WorkspaceTab {
        switch self {
        case .info, .environment:
            return .info
        case .agent:
            return .agent
        case .changes:
            return .changes
        }
    }
}

enum SetupStateStore {
    private static let userDefaultsKey = "factoryfloor.setupCompleted"

    static func isCompleted(for workstreamID: UUID) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode(Set<String>.self, from: data)
        else { return false }
        return saved.contains(workstreamID.uuidString)
    }

    static func markCompleted(for workstreamID: UUID) {
        var saved: Set<String> = []
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let existing = try? JSONDecoder().decode(Set<String>.self, from: data)
        {
            saved = existing
        }
        saved.insert(workstreamID.uuidString)
        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }

    static func remove(for workstreamID: UUID) {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              var saved = try? JSONDecoder().decode(Set<String>.self, from: data)
        else { return }
        saved.remove(workstreamID.uuidString)
        guard let encoded = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
    }
}

enum WorkspaceStateStore {
    private static let userDefaultsKey = "factoryfloor.workspaceTabs"

    static func load(for workstreamID: UUID) -> RestorableWorkspaceTab? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([String: RestorableWorkspaceTab].self, from: data)
        else { return nil }
        return saved[workstreamID.uuidString]
    }

    static func save(_ tab: RestorableWorkspaceTab, for workstreamID: UUID) {
        var saved: [String: RestorableWorkspaceTab] = [:]
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let existing = try? JSONDecoder().decode([String: RestorableWorkspaceTab].self, from: data)
        {
            saved = existing
        }
        saved[workstreamID.uuidString] = tab
        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}

func reorderedCustomTabs(_ tabs: [WorkspaceTab], dragging draggedTab: WorkspaceTab, to targetTab: WorkspaceTab) -> [WorkspaceTab] {
    guard draggedTab != targetTab,
          draggedTab.isCloseable,
          targetTab.isCloseable,
          let sourceIndex = tabs.firstIndex(of: draggedTab),
          let targetIndex = tabs.firstIndex(of: targetTab)
    else {
        return tabs
    }

    var reordered = tabs
    let movedTab = reordered.remove(at: sourceIndex)
    let insertionIndex = targetIndex > sourceIndex ? targetIndex - 1 : targetIndex
    reordered.insert(movedTab, at: insertionIndex)
    return reordered
}

/// A tab in the workspace. Info and Agent are permanent; terminals and browsers are closeable.
enum WorkspaceTab: Hashable {
    case info
    case agent
    case changes
    case terminal(UUID)
    case browser(UUID)
    case editor(UUID)

    var isCloseable: Bool {
        switch self {
        case .info, .agent, .changes: return false
        case .terminal, .browser, .editor: return true
        }
    }
}

/// Who started the dev server. Browsers used to own the server implicitly:
/// opening one killed an Info-started server and closing the last one
/// stopped it, which caused constant port churn. Now Info-started servers
/// survive browser tabs; only browser-started ones stop with the last tab.
enum RunOwner: String, Equatable {
    case none
    case info
    case browser
}

/// Captured workspace tab state for a workstream, used to survive navigation.
struct WorkspaceTabSnapshot {
    var tabs: [WorkspaceTab]
    var terminalCount: Int
    var browserCount: Int
    var editorCount: Int
    var activeTab: WorkspaceTab
    var browserTitles: [UUID: String]
    var terminalTitles: [UUID: String]
    var editorFilePaths: [UUID: String]
    var runStarted: Bool
    var runStoppedManually: Bool
    /// Restored alongside runStarted so the run surface ID is stable across
    /// workspace switches (previously the generation reset to 0 and the
    /// rebuilt command pointed at a different surface than the live one).
    var runGeneration: Int = 0
    var runOwner: RunOwner = .none

    /// Returns a copy with dead terminal tabs removed.
    /// Browser and editor tabs are kept regardless (they don't use terminal surfaces).
    func reconciled(liveSurfaceIDs: Set<UUID>) -> WorkspaceTabSnapshot {
        let filteredTabs = tabs.filter { tab in
            if case let .terminal(id) = tab {
                return liveSurfaceIDs.contains(id)
            }
            return true
        }
        let resolvedActiveTab = filteredTabs.contains(activeTab) ? activeTab : .agent
        return WorkspaceTabSnapshot(
            tabs: filteredTabs,
            terminalCount: terminalCount,
            browserCount: browserCount,
            editorCount: editorCount,
            activeTab: resolvedActiveTab,
            browserTitles: browserTitles,
            terminalTitles: terminalTitles,
            editorFilePaths: editorFilePaths,
            runStarted: runStarted,
            runStoppedManually: runStoppedManually,
            runGeneration: runGeneration,
            runOwner: runOwner
        )
    }
}

func startupWorkspaceTabState(snapshot: WorkspaceTabSnapshot?, savedTab: RestorableWorkspaceTab?) -> WorkspaceTabSnapshot {
    if let snapshot {
        // Filter out any persisted environment tabs from before the merge.
        let filteredTabs = snapshot.tabs.filter { tab in
            if case .info = tab { return true }
            if case .agent = tab { return true }
            if case .changes = tab { return true }
            if case .terminal = tab { return true }
            if case .browser = tab { return true }
            return false
        }
        var cleaned = snapshot
        cleaned.tabs = filteredTabs
        // Migrate older snapshots that predate the fixed Changes tab: insert it
        // immediately after Agent (or at a sensible fixed index if Agent is
        // absent). Idempotent — never inserts when .changes is already present.
        if !cleaned.tabs.contains(.changes) {
            let insertIndex = cleaned.tabs.firstIndex(of: .agent).map { $0 + 1 }
                ?? min(2, cleaned.tabs.count)
            cleaned.tabs.insert(.changes, at: insertIndex)
        }
        if !cleaned.tabs.contains(cleaned.activeTab) {
            cleaned.activeTab = .info
        }
        return cleaned
    }

    let tabs: [WorkspaceTab] = [.info, .agent, .changes]
    return WorkspaceTabSnapshot(
        tabs: tabs,
        terminalCount: 0,
        browserCount: 0,
        editorCount: 0,
        activeTab: (savedTab ?? .info).workspaceTab(),
        browserTitles: [:],
        terminalTitles: [:],
        editorFilePaths: [:],
        runStarted: false,
        runStoppedManually: false
    )
}

/// Whether selecting a workstream from the sidebar should auto-focus the Coding Agent.
/// Returns true only when there is no tab state to restore — new workstreams open on
/// the Coding Agent, previously-visited ones restore their last-active tab.
func shouldAutoFocusAgent(snapshot: WorkspaceTabSnapshot?, savedTab: RestorableWorkspaceTab?) -> Bool {
    snapshot == nil && savedTab == nil
}

func workspaceEnvironmentVariables(
    workstreamID: UUID,
    projectName: String,
    workstreamName: String,
    projectDirectory: String,
    workingDirectory: String,
    port: Int,
    agentTeams: Bool,
    defaultBranch: String,
    scriptSource: String?,
    harness: CodingHarness = .claudeCode
) -> [String: String] {
    WorkstreamEnvironment.variables(
        workstreamID: workstreamID,
        projectName: projectName,
        workstreamName: workstreamName,
        projectDirectory: projectDirectory,
        workingDirectory: workingDirectory,
        port: port,
        agentTeams: agentTeams,
        defaultBranch: defaultBranch,
        scriptSource: scriptSource,
        harness: harness
    )
}

enum TerminalSessionMode: Equatable {
    case standard
    case tmux
    case waitingForTools

    static func resolve(tmuxModeEnabled: Bool, isDetectingTools: Bool, tmuxInstalled: Bool) -> Self {
        if tmuxModeEnabled {
            if isDetectingTools {
                return .waitingForTools
            }
            if tmuxInstalled {
                return .tmux
            }
        }
        return .standard
    }
}

enum SetupGateState: Equatable {
    case notNeeded
    case awaitingApproval
    case running
    case failed
    case completed

    /// A setup script only runs once per workstream, and only once the user has
    /// approved the commands the repository supplied.
    static func resolve(hasSetupScript: Bool, setupCompleted: Bool, scriptsApproved: Bool) -> SetupGateState {
        guard hasSetupScript, !setupCompleted else { return .notNeeded }
        return scriptsApproved ? .running : .awaitingApproval
    }
}

struct TerminalContainerView: View {
    let workstreamID: UUID
    let workingDirectory: String
    let projectDirectory: String
    let projectName: String
    let workstreamName: String
    let workstreamLabel: String
    let bypassPermissions: Bool
    var harness: CodingHarness = .claudeCode
    let isActive: Bool

    @EnvironmentObject var surfaceCache: TerminalSurfaceCache
    @EnvironmentObject var appEnv: AppEnvironment
    @AppStorage("factoryfloor.defaultBrowser") private var defaultBrowser: String = ""
    @AppStorage("factoryfloor.tmuxMode") private var tmuxMode: Bool = false
    @AppStorage("factoryfloor.agentTeams") private var agentTeams: Bool = false
    @AppStorage("factoryfloor.autoRenameBranch") private var autoRenameBranch: Bool = false
    @AppStorage("factoryfloor.allowOutsideWorktree") private var allowOutsideWorktree: Bool = false
    @AppStorage("factoryfloor.quickActionDebug") private var quickActionDebug: Bool = false
    @AppStorage("factoryfloor.editorTabActive") private var editorTabActive: Bool = false
    @AppStorage("factoryfloor.editorFileDirty") private var editorFileDirty: Bool = false
    @AppStorage("factoryfloor.changesTabActive") private var changesTabActive: Bool = false
    @AppStorage("factoryfloor.changesDirty") private var changesDirty: Bool = false
    @State private var activeTab: WorkspaceTab = .info
    @State private var tabs: [WorkspaceTab] = [.info, .agent]
    @State private var terminalCount = 0
    @State private var browserCount = 0
    @State private var editorCount = 0
    @State private var scriptConfig: ScriptConfig = .empty
    @State private var browserTitles: [UUID: String] = [:]
    @State private var terminalTitles: [UUID: String] = [:]
    @State private var editorFilePaths: [UUID: String] = [:]
    @State private var editorDirtyState: [UUID: Bool] = [:]
    @State private var changesDirtyState: Bool = false
    @State private var editorBridge: MonacoEditorBridge?
    @State private var diffBridge: MonacoDiffBridge?
    @State private var fileTree: [FileNode] = []
    @State private var gitFileStatuses = GitFileStatusProvider()
    @State private var directoryWatcher: DirectoryWatcher?
    @State private var refreshGeneration = 0
    @State private var refreshDebounceTask: Task<Void, Never>?
    @State private var fileFinderRequest = 0
    @State private var cachedAgentCommand: String?
    /// Harness the cached command was built for. Guards against rendering a
    /// stale command right after a harness switch, which would recreate the
    /// agent surface under the previous CLI before the rebuild lands.
    @State private var cachedCommandHarness: CodingHarness?
    @State private var draggedCustomTab: WorkspaceTab?
    @StateObject private var portDetector: PortDetector
    @State private var browserStartPending = false
    @State private var runStoppedManually = false
    @State private var runStarted = false
    @State private var runGeneration = 0
    @State private var runOwner: RunOwner = .none
    /// Last seen dev-server URL per browser tab, recorded when leaving the
    /// tab. BrowserView is destroyed while inactive, so it cannot observe
    /// defaultURL changes via onChange; it reconciles from this on return.
    @State private var browserLastDefaultURLs: [UUID: String] = [:]
    @State private var runCommandString: String?
    @State private var devCommandOverride: String?
    @State private var resolvedDevCommand: DevCommand?
    @State private var workspaceStarted = false
    @State private var defaultBranch = "main"
    @State private var setupGateState: SetupGateState = .notNeeded
    @State private var scriptsApproved = false
    init(
        workstreamID: UUID,
        workingDirectory: String,
        projectDirectory: String,
        projectName: String,
        workstreamName: String,
        workstreamLabel: String? = nil,
        bypassPermissions: Bool,
        harness: CodingHarness = .claudeCode,
        isActive: Bool,
        scriptConfig: ScriptConfig = .empty,
        initialTabState: WorkspaceTabSnapshot = startupWorkspaceTabState(snapshot: nil, savedTab: nil)
    ) {
        self.workstreamID = workstreamID
        self.workingDirectory = workingDirectory
        self.projectDirectory = projectDirectory
        self.projectName = projectName
        self.workstreamName = workstreamName
        self.workstreamLabel = workstreamLabel ?? workstreamName
        self.bypassPermissions = bypassPermissions
        self.harness = harness
        self.isActive = isActive
        _activeTab = State(initialValue: initialTabState.activeTab)
        _tabs = State(initialValue: initialTabState.tabs)
        _terminalCount = State(initialValue: initialTabState.terminalCount)
        _browserCount = State(initialValue: initialTabState.browserCount)
        _scriptConfig = State(initialValue: scriptConfig)
        _editorCount = State(initialValue: initialTabState.editorCount)
        _browserTitles = State(initialValue: initialTabState.browserTitles)
        _terminalTitles = State(initialValue: initialTabState.terminalTitles)
        _editorFilePaths = State(initialValue: initialTabState.editorFilePaths)
        _runStoppedManually = State(initialValue: initialTabState.runStoppedManually)
        _runStarted = State(initialValue: initialTabState.runStarted)
        _runGeneration = State(initialValue: initialTabState.runGeneration)
        _runOwner = State(initialValue: initialTabState.runOwner)
        _portDetector = StateObject(wrappedValue: PortDetector(workstreamID: workstreamID))

        let savedOverride = DevCommandResolver.savedOverride(for: workstreamID)
        _devCommandOverride = State(initialValue: savedOverride)
        _resolvedDevCommand = State(initialValue: DevCommandResolver.resolve(
            scriptConfig: scriptConfig,
            workstreamID: workstreamID,
            workingDirectory: workingDirectory,
            override: savedOverride
        ))
    }

    private var claudeID: UUID {
        workstreamID
    }

    private var setupGateID: UUID {
        derivedUUID(from: workstreamID, salt: "setup-gate")
    }

    private var quickActionRunner: QuickActionRunner {
        surfaceCache.quickActionRunner(for: workstreamID)
    }

    private var isEditorTabActive: Bool {
        if case .editor = activeTab { return true }
        return false
    }

    private var isActiveEditorDirty: Bool {
        if case let .editor(id) = activeTab { return editorDirtyState[id] == true }
        return false
    }

    private var isChangesTabActive: Bool {
        if case .changes = activeTab { return true }
        return false
    }

    /// Push the Save-menu state for both lanes (Editor file, Changes diff) to
    /// the AppStorage flags FF2App reads. Only the front workspace writes them.
    private func syncMenuFlags() {
        guard isActive else { return }
        editorTabActive = isEditorTabActive
        editorFileDirty = isActiveEditorDirty
        changesTabActive = isChangesTabActive
        changesDirty = isChangesTabActive && changesDirtyState
    }

    /// Surface IDs that should be rendering for the active tab.
    private var visibleSurfaceIDs: Set<UUID>? {
        switch activeTab {
        case .agent:
            if setupGateState == .awaitingApproval {
                return []
            }
            if setupGateState == .running || setupGateState == .failed {
                return [setupGateID]
            }
            return [claudeID]
        case let .terminal(id): return [id]
        case .info, .changes, .browser, .editor: return []
        }
    }

    private var sessionMode: TerminalSessionMode {
        TerminalSessionMode.resolve(
            tmuxModeEnabled: tmuxMode,
            isDetectingTools: appEnv.isDetecting,
            tmuxInstalled: appEnv.toolStatus.tmux.isInstalled
        )
    }

    private var useTmux: Bool {
        sessionMode == .tmux
    }

    private var workstreamPort: Int {
        PortAllocator.port(for: workingDirectory)
    }

    private var portSubtitle: String {
        let label = appEnv.taskDescription(for: workingDirectory) ?? projectName
        if let port = portDetector.selectedPort {
            return "\(label) · localhost:\(port) · \u{2318}B for browser"
        }
        return label
    }

    private var browserDefaultURL: String {
        let port = portDetector.selectedPort ?? workstreamPort
        return "http://localhost:\(port)/"
    }

    /// The dev server was intentionally stopped (a run command exists, nothing
    /// is starting, nothing is live). Drives the browser tabs' stopped banner
    /// so a cached page never silently poses as a live server.
    private var isRunServerStopped: Bool {
        resolvedRunCommand != nil && !runStarted && portDetector.status == .none && !browserStartPending
    }

    /// The run session's surface ID. Bumped on stop/restart so a fresh
    /// surface replaces the previous one.
    private var runID: UUID {
        derivedUUID(from: workstreamID, salt: "env-run-\(runGeneration)")
    }

    /// The dev server is coming up but has not exposed a port yet. Covers the
    /// window between a browser-triggered start and the first ff-run state
    /// write, so the browser never navigates to the placeholder port.
    private var isWaitingForServer: Bool {
        portDetector.status == .starting || (portDetector.status == .none && browserStartPending)
    }

    /// The command that starts the dev server: config run script, user
    /// override, or the repo's package.json dev script.
    private var resolvedRunCommand: String? {
        if let run = scriptConfig.run { return run }
        return resolvedDevCommand?.command
    }

    /// Config-provided run scripts are approval-gated; auto-detected or
    /// user-authored dev commands are not.
    private var runCommandIsGated: Bool {
        scriptConfig.run != nil
    }

    /// Env vars for the run/dev-server surface. Adds the var that silences
    /// the Next.js first-run telemetry prompt, which a headless terminal
    /// cannot answer.
    private var runEnvironmentVars: [String: String] {
        var vars = terminalEnvVars
        vars["NEXT_TELEMETRY_DISABLED"] = "1"
        return vars
    }

    private var branchPR: GitHubPR? {
        guard let branch = appEnv.branchName(for: workingDirectory) else { return nil }
        return appEnv.githubPR(for: projectDirectory, branch: branch)
    }

    /// The Factory Floor state directory inside the worktree.
    private var factoryFloorStateDirectory: URL {
        URL(fileURLWithPath: workingDirectory).appendingPathComponent(".factoryfloor-state", isDirectory: true)
    }

    /// Session id recorded by the Factory Floor opencode plugin, if any.
    private var trackedOpencodeSessionID: String? {
        let url = factoryFloorStateDirectory.appendingPathComponent("opencode-session")
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Writes (or clears) the system-prompt instructions the opencode plugin
    /// appends on each user message. Claude receives these via
    /// --append-system-prompt instead.
    private func syncOpencodeInstructions() {
        var parts: [String] = []
        if !allowOutsideWorktree {
            parts.append(SystemPrompts.restrictToWorktreePrompt(worktreePath: workingDirectory))
        }
        if autoRenameBranch {
            parts.append(SystemPrompts.autoRenameBranchPrompt)
        }

        let instructionsURL = factoryFloorStateDirectory.appendingPathComponent("instructions.md")
        do {
            try FileManager.default.createDirectory(at: factoryFloorStateDirectory, withIntermediateDirectories: true)
            try parts.joined(separator: "\n\n").write(to: instructionsURL, atomically: true, encoding: .utf8)
        } catch {
            logger.warning("Failed to write opencode instructions: \(error.localizedDescription)")
        }
    }

    private func buildClaudeCommand() -> String? {
        guard let basePath = appEnv.toolStatus.claude.path else { return nil }
        let sessionID = workstreamID.uuidString.lowercased()

        var systemPromptParts: [String] = []
        if !allowOutsideWorktree {
            systemPromptParts.append(SystemPrompts.restrictToWorktreePrompt(worktreePath: workingDirectory))
        }
        if autoRenameBranch {
            systemPromptParts.append(SystemPrompts.autoRenameBranchPrompt)
        }
        let combinedSystemPrompt = systemPromptParts.isEmpty ? nil : systemPromptParts.joined(separator: "\n\n")

        var resume = CommandBuilder(basePath)
        resume.option("--resume", sessionID)
        if appEnv.toolStatus.claudeSupportsSessionName {
            resume.option("--name", workstreamName)
        }
        if useTmux { resume.flag("--teammate-mode"); resume.arg("tmux") }
        if bypassPermissions { resume.flag("--dangerously-skip-permissions") }
        if let combinedSystemPrompt {
            resume.option("--append-system-prompt", combinedSystemPrompt)
        }

        var fresh = CommandBuilder(basePath)
        fresh.option("--session-id", sessionID)
        if appEnv.toolStatus.claudeSupportsSessionName {
            fresh.option("--name", workstreamName)
        }
        if useTmux { fresh.flag("--teammate-mode"); fresh.arg("tmux") }
        if bypassPermissions { fresh.flag("--dangerously-skip-permissions") }
        if let combinedSystemPrompt {
            fresh.option("--append-system-prompt", combinedSystemPrompt)
        }

        let cmd = CommandBuilder.withFallback(
            resume.command, fresh.command,
            message: "Starting new session..."
        )

        return wrapAgentCommand(cmd, intermediates: [resume.command, fresh.command, cmd], toolPathsClaude: basePath, toolPathsOpencode: nil)
    }

    private func buildOpencodeCommand() -> String? {
        guard let basePath = appEnv.toolStatus.opencode.path else { return nil }
        syncOpencodeInstructions()

        // Resume-first: prefer the session id the plugin recorded for this
        // worktree; fall back to launching fresh (the plugin then records the
        // new id).
        var resume = CommandBuilder(basePath)
        if let tracked = trackedOpencodeSessionID {
            resume.flag("--session")
            resume.arg(tracked)
        }
        if bypassPermissions { resume.flag("--auto") }

        var fresh = CommandBuilder(basePath)
        if bypassPermissions { fresh.flag("--auto") }

        let cmd = CommandBuilder.withFallback(
            resume.command, fresh.command,
            message: "Starting new session..."
        )

        return wrapAgentCommand(cmd, intermediates: [resume.command, fresh.command, cmd], toolPathsClaude: nil, toolPathsOpencode: basePath)
    }

    /// Shared tail of agent command building: optional tmux wrapping + launch log.
    private func wrapAgentCommand(_ cmd: String, intermediates: [String], toolPathsClaude: String?, toolPathsOpencode: String?) -> String {
        let finalCommand: String
        var intermediates = intermediates
        if useTmux, let tmuxPath = appEnv.toolStatus.tmux.path {
            let session = TmuxSession.sessionName(project: projectName, workstream: workstreamName, role: "agent")
            finalCommand = TmuxSession.wrapCommand(tmuxPath: tmuxPath, sessionName: session, command: cmd, environmentVars: envVars, respawnOnExit: true)
            intermediates.append(finalCommand)
        } else {
            finalCommand = cmd
        }

        LaunchLogger.log(LaunchLogEntry(
            workstreamID: workstreamID,
            event: "agent-start",
            finalCommand: finalCommand,
            intermediateCommands: intermediates,
            environmentVariables: envVars,
            workingDirectory: workingDirectory,
            toolPaths: LaunchLogEntry.ToolPaths(
                claude: toolPathsClaude ?? appEnv.toolStatus.claude.path,
                opencode: toolPathsOpencode,
                tmux: appEnv.toolStatus.tmux.path,
                ffRun: RunLauncher.executableURL()?.path
            ),
            settings: LaunchLogEntry.Settings(
                tmuxMode: tmuxMode,
                bypassPermissions: bypassPermissions,
                agentTeams: agentTeams,
                autoRenameBranch: autoRenameBranch,
                allowOutsideWorktree: allowOutsideWorktree
            ),
            shell: CommandBuilder.userShell
        ))

        return finalCommand
    }

    private func buildAgentCommand() -> String? {
        switch harness {
        case .claudeCode: return buildClaudeCommand()
        case .opencode: return buildOpencodeCommand()
        }
    }

    /// The binary path backing this workstream's harness, when installed.
    private var harnessBinaryPath: String? {
        switch harness {
        case .claudeCode: return appEnv.toolStatus.claude.path
        case .opencode: return appEnv.toolStatus.opencode.path
        }
    }

    private func rebuildAgentCommand() {
        cachedAgentCommand = buildAgentCommand()
        cachedCommandHarness = harness
        if let cmd = cachedAgentCommand {
            logger.info("[FF] agent cmd rebuilt for \(self.harness.rawValue, privacy: .public): \(cmd.prefix(80), privacy: .public)")
        }
    }

    private var fixedTabs: [WorkspaceTab] {
        tabs.filter { !$0.isCloseable }
    }

    private var closeableTabs: [WorkspaceTab] {
        tabs.filter(\.isCloseable)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            // Fixed tabs (Info, Agent)
            ForEach(fixedTabs, id: \.self) { tab in
                tabButton(for: tab)
            }

            // Scrollable closeable tabs (terminals, browsers)
            if !closeableTabs.isEmpty {
                ScrollableTabStrip(
                    tabs: closeableTabs,
                    activeTab: activeTab,
                    tabButton: { tab in tabButton(for: tab) }
                )
                .layoutPriority(-1)
            }

            Spacer()

            // Quick actions to add tabs
            HStack(spacing: 2) {
                TabBarActionButton(icon: "terminal", shortcut: "\u{2318}T", tooltip: "New Terminal (\u{2318}T)", action: addTerminal)
                TabBarActionButton(icon: "globe", shortcut: "\u{2318}B", tooltip: "New Browser (\u{2318}B)", action: addBrowser)
                TabBarActionButton(icon: "doc.text", shortcut: "\u{2318}O", tooltip: "New Editor (\u{2318}O)", action: openEditor)
            }
            .fixedSize()

            if let pr = branchPR, let url = URL(string: pr.url) {
                let prColor: Color = pr.state == "MERGED" ? .purple : .green
                Button(action: { NSWorkspace.shared.open(url) }) {
                    HStack(spacing: 4) {
                        Image(systemName: pr.state == "MERGED" ? "arrow.triangle.merge" : "arrow.triangle.pull")
                            .font(.system(size: 11))
                        Text(verbatim: "#\(pr.number)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(prColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .foregroundStyle(prColor)
                }
                .buttonStyle(.borderless)
                .help(pr.title)
                .accessibilityLabel(Text(verbatim: "Pull request #\(pr.number)"))
                .accessibilityHint(pr.title)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private func isEditorDirty(_ tab: WorkspaceTab) -> Bool {
        if case let .editor(id) = tab { return editorDirtyState[id] == true }
        return false
    }

    @ViewBuilder
    private func tabButton(for tab: WorkspaceTab) -> some View {
        let shortcut = tabShortcut(tab) ?? closeableTabShortcut(tab)
        let button = WorkspaceTabButton(
            tab: tab,
            label: tabLabel(tab),
            icon: tabIcon(tab),
            shortcut: shortcut,
            isActive: activeTab == tab,
            isDirty: isEditorDirty(tab),
            onSelect: { activeTab = tab },
            onClose: tab.isCloseable ? { closeTab(tab) } : nil
        )

        if tab.isCloseable {
            button
                .onDrag {
                    draggedCustomTab = tab
                    return NSItemProvider(object: NSString(string: tabDragIdentifier(tab)))
                }
                .onDrop(of: [.text], delegate: WorkspaceTabDropDelegate {
                    moveCustomTab(to: tab)
                })
        } else {
            button
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .info:
            WorkstreamInfoView(
                workstreamID: workstreamID,
                workstreamName: workstreamLabel,
                workingDirectory: workingDirectory,
                projectName: projectName,
                projectDirectory: projectDirectory,
                scriptConfig: scriptConfig,
                useTmux: useTmux,
                environmentVars: runEnvironmentVars,
                runCommand: runCommandString,
                runCommandIsGated: runCommandIsGated,
                devCommand: resolvedDevCommand,
                devCommandOverride: $devCommandOverride,
                runStoppedManually: $runStoppedManually,
                runStarted: $runStarted,
                scriptsApproved: $scriptsApproved,
                runGeneration: $runGeneration,
                runOwner: $runOwner,
                selectedPort: portDetector.selectedPort,
                portStatus: portDetector.status,
                expectedPort: workstreamPort,
                isWaitingForServer: isWaitingForServer,
                sessionMode: sessionMode,
                onStart: { doStartRun() },
                onStop: stopRun,
                onRestart: restartRun
            )
        case .changes:
            if let bridge = diffBridge {
                ChangesView(
                    workstreamID: workstreamID,
                    workingDirectory: workingDirectory,
                    projectDirectory: projectDirectory,
                    bridge: bridge,
                    onOpenInEditor: { [self] path in addEditor(filePath: path) },
                    onDirtyChanged: { [self] dirty in
                        changesDirtyState = dirty
                        syncMenuFlags()
                    },
                    isActive: isActive
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case .agent:
            if setupGateState == .awaitingApproval {
                setupApprovalView
            } else if setupGateState == .running {
                setupGateRunningView
            } else if setupGateState == .failed {
                setupGateFailedView
            } else if sessionMode == .waitingForTools || appEnv.isDetecting {
                terminalLoadingView(message: "Checking terminal tools...")
            } else if harnessBinaryPath == nil {
                VStack(spacing: 16) {
                    Image(systemName: harness.systemImageName)
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text("\(harness.displayName) not found")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Install \(harness.displayName) to use the Coding Agent.")
                        .foregroundStyle(.tertiary)
                    Link("Install \(harness.displayName)", destination: harness.installURL)
                        .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let agentCommand = cachedAgentCommand, cachedCommandHarness == harness {
                SingleTerminalView(
                    surfaceID: claudeID,
                    workingDirectory: workingDirectory,
                    command: agentCommand,
                    isFocused: true,
                    environmentVars: envVars
                )
            } else {
                terminalLoadingView(message: "Preparing Coding Agent...")
            }
        case let .terminal(id):
            SingleTerminalView(
                surfaceID: id,
                workingDirectory: workingDirectory,
                isFocused: true,
                environmentVars: terminalEnvVars
            )
        case let .browser(id):
            BrowserView(
                defaultURL: browserDefaultURL,
                isWaitingForServer: isWaitingForServer,
                tabID: id,
                webView: surfaceCache.webView(for: id),
                previousDefaultURL: browserLastDefaultURLs[id],
                serverStopped: isRunServerStopped,
                onStartServer: { startRunIfNeeded() }
            )
                .id(id)
        case let .editor(id):
            if let bridge = editorBridge {
                EditorView(
                    workingDirectory: workingDirectory,
                    fileTree: fileTree,
                    gitStatus: gitFileStatuses,
                    initialFilePath: editorFilePaths[id],
                    bridge: bridge,
                    modelId: id.uuidString,
                    isDirtyState: Binding(
                        get: { editorDirtyState[id] ?? false },
                        set: { editorDirtyState[id] = $0 }
                    ),
                    onFileChanged: { path in
                        if let path {
                            editorFilePaths[id] = path
                        } else {
                            editorFilePaths.removeValue(forKey: id)
                        }
                        saveTabSnapshot()
                    },
                    onExpandFolder: { path in
                        expandFileTreeFolder(path)
                    },
                    fileFinderRequest: fileFinderRequest
                )
                .id(id)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var mainContent: some View {
        mainLayout
            .onChange(of: tmuxMode) { rebuildAgentCommand() }
            .onChange(of: bypassPermissions) { rebuildAgentCommand() }
            .onChange(of: autoRenameBranch) { rebuildAgentCommand() }
            .onChange(of: allowOutsideWorktree) { rebuildAgentCommand() }
            .onChange(of: workstreamName) { rebuildAgentCommand() }
            .onChange(of: harness) {
                // The sidebar switch already tore the old agent surface down.
                // Rebuild for the new harness and start it immediately —
                // otherwise the next render would lazily recreate the surface.
                rebuildAgentCommand()
                guard setupGateState != .awaitingApproval else { return }
                if setupGateState == .notNeeded {
                    surfaceCache.respawnableIDs.insert(claudeID)
                }
                preloadSurfaces()
            }
            .onChange(of: appEnv.isDetecting) {
                rebuildAgentCommand()
                if isActive { preloadSurfaces() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleInfo)) { _ in
                guard isActive else { return }
                activeTab = .info
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusAgent)) { _ in
                guard isActive else { return }
                activeTab = .agent
            }
            .onReceive(NotificationCenter.default.publisher(for: .rerunScript)) { _ in
                guard isActive else { return }
                guard resolvedRunCommand != nil else { return }
                guard !runCommandIsGated || scriptsApproved else { return }
                if runStarted {
                    restartRun()
                } else {
                    startRunIfNeeded()
                }
                activeTab = .info
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleTerminal)) { _ in
                guard isActive else { return }
                addTerminal()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleBrowser)) { _ in
                guard isActive else { return }
                addBrowser()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleEditor)) { _ in
                guard isActive else { return }
                openEditor()
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleFileFinder)) { _ in
                guard isActive else { return }
                if case .editor = activeTab {
                    fileFinderRequest += 1
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleChanges)) { _ in
                guard isActive else { return }
                addChanges()
            }
            .onReceive(NotificationCenter.default.publisher(for: .closeTerminal)) { _ in
                guard isActive else { return }
                if activeTab.isCloseable { closeTab(activeTab) }
            }
    }

    private var mainLayout: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            tabContent
        }
        .task(id: workstreamID) {
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            let branch = await Task.detached {
                GitOperations.defaultBranch(at: projectDirectory)
            }.value
            guard !Task.isCancelled else { return }
            await MainActor.run {
                startWorkspace(defaultBranch: branch)
            }
        }
        .onAppear {
            syncMenuFlags()
            if tabs.contains(where: { if case .editor = $0 { return true } else { return false } }) {
                startFileTreeWatcherIfNeeded()
            }
        }
        .onDisappear {
            if isActive {
                editorTabActive = false
                editorFileDirty = false
                changesTabActive = false
                changesDirty = false
            }
            guard workspaceStarted else { return }
            surfaceCache.saveTabSnapshot(for: workstreamID, snapshot: currentTabSnapshot())
        }
        .onChange(of: activeTab) { oldTab, _ in
            if case let .browser(id) = oldTab {
                browserLastDefaultURLs[id] = browserDefaultURL
            }
            guard isActive else { return }
            syncMenuFlags()
            surfaceCache.updateOcclusion(visibleSurfaceIDs: visibleSurfaceIDs)
            WorkspaceStateStore.save(RestorableWorkspaceTab(activeTab: activeTab), for: workstreamID)
            appEnv.refreshWorktreeState(for: workingDirectory, projectDirectory: projectDirectory)
        }
        .onReceive(NotificationCenter.default.publisher(for: .terminalActivity)) { notification in
            guard isActive else { return }
            guard let wsID = notification.object as? UUID, wsID == workstreamID else { return }
            appEnv.refreshWorktreeState(for: workingDirectory, projectDirectory: projectDirectory)
        }
    }

    var body: some View {
        mainContent
            .onChange(of: scriptsApproved) { _, approved in
                // Approving from the Info tab releases a waiting setup script.
                if approved { startApprovedSetup() }
            }
            .onChange(of: devCommandOverride) { _, newValue in
                DevCommandResolver.saveOverride(newValue, for: workstreamID)
                resolvedDevCommand = DevCommandResolver.resolve(
                    scriptConfig: scriptConfig,
                    workstreamID: workstreamID,
                    workingDirectory: workingDirectory,
                    override: newValue
                )
            }
            .onChange(of: runStarted) { _, started in
                // A session restored from tmux (or started before TerminalApp
                // was ready) needs its command assembled on the container side
                // so the restored surface reattaches to the existing session.
                if started, runCommandString == nil, let command = resolvedRunCommand {
                    runCommandString = buildRunCommand(script: command, generation: runGeneration)
                    preloadRunSurface()
                }
            }
            .onChange(of: portDetector.status) { _, newStatus in
                // Once the session materializes (ff-run wrote state), the
                // waiting overlay is driven by the status itself.
                if newStatus != .none {
                    browserStartPending = false
                } else {
                    // The flag says running but no session is alive (crashed
                    // or killed outside the app). Give slow boots a grace
                    // window, then fall back to a clean idle state instead of
                    // showing phantom Stop/Rerun controls.
                    clearStaleRunFlagAfterGracePeriod()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .switchByNumber)) { notification in
                guard isActive else { return }
                guard let n = notification.object as? Int, n >= 1 else { return }
                // Cmd+1-9 maps to all tabs in display order
                guard n <= tabs.count else { return }
                activeTab = tabs[n - 1]
            }
            .onReceive(NotificationCenter.default.publisher(for: .nextTab)) { _ in
                guard isActive else { return }
                guard let currentIndex = tabs.firstIndex(of: activeTab) else { return }
                activeTab = tabs[(currentIndex + 1) % tabs.count]
            }
            .onReceive(NotificationCenter.default.publisher(for: .prevTab)) { _ in
                guard isActive else { return }
                guard let currentIndex = tabs.firstIndex(of: activeTab) else { return }
                activeTab = tabs[(currentIndex - 1 + tabs.count) % tabs.count]
            }
            .onReceive(NotificationCenter.default.publisher(for: .terminalChildExited)) { notification in
                guard let surfaceID = notification.object as? UUID, surfaceID == setupGateID,
                      let exitCode = notification.userInfo?["exitCode"] as? Int32
                else { return }
                handleSetupChildExited(exitCode: exitCode)
            }
            .onReceive(NotificationCenter.default.publisher(for: .terminalTabExited)) { notification in
                guard let surfaceID = notification.object as? UUID else { return }
                if surfaceID == setupGateID, setupGateState == .failed {
                    launchAgentAfterSetup()
                    return
                }
                if surfaceID == runID {
                    // The dev-server session died; no port is coming.
                    browserStartPending = false
                }
                if let tab = tabs.first(where: {
                    if case let .terminal(id) = $0 { return id == surfaceID }
                    return false
                }) {
                    closeTab(tab)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .browserTitleChanged)) { notification in
                guard let tabID = notification.object as? UUID else { return }
                browserTitles[tabID] = notification.userInfo?["title"] as? String
            }
            .onReceive(NotificationCenter.default.publisher(for: .terminalTitleChanged)) { notification in
                guard let surfaceID = notification.object as? UUID else { return }
                terminalTitles[surfaceID] = notification.userInfo?["title"] as? String
            }
            .onReceive(NotificationCenter.default.publisher(for: .openExternalBrowser)) { _ in
                guard isActive else { return }
                guard let url = URL(string: browserDefaultURL) else { return }
                if defaultBrowser.isEmpty {
                    NSWorkspace.shared.open(url)
                } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: defaultBrowser) {
                    NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
                } else {
                    NSWorkspace.shared.open(url)
                }
            }
            .toolbar {
                if isActive {
                    ToolbarItemGroup(placement: .primaryAction) {
                        if let githubURL = appEnv.githubURL(for: projectDirectory) {
                            Button {
                                NSWorkspace.shared.open(githubURL)
                            } label: {
                                Label(NSLocalizedString("GitHub", comment: ""), image: "github")
                                    .labelStyle(.iconOnly)
                            }
                            .help("Open on GitHub")
                        }

                        GitHubActionMenu(
                            runner: quickActionRunner,
                            harness: harness,
                            agentPath: harnessBinaryPath,
                            ghPath: appEnv.toolStatus.gh.path,
                            workingDirectory: workingDirectory,
                            branchName: appEnv.branchName(for: workingDirectory),
                            bypassPermissions: bypassPermissions,
                            worktreeState: appEnv.worktreeState(for: workingDirectory),
                            hasGitHubRemote: appEnv.hasGitHubRemote(projectDirectory),
                            branchPR: branchPR
                        )
                    }
                }
            }
            .onChange(of: isActive) { _, active in
                editorTabActive = active && isEditorTabActive
                editorFileDirty = active && isActiveEditorDirty
                changesTabActive = active && isChangesTabActive
                changesDirty = active && isChangesTabActive && changesDirtyState
                if active {
                    surfaceCache.updateOcclusion(visibleSurfaceIDs: visibleSurfaceIDs)
                } else {
                    surfaceCache.saveTabSnapshot(for: workstreamID, snapshot: currentTabSnapshot())
                }
            }
    }

    // MARK: - Tab management

    /// Number of closeable tabs beyond which labels are hidden to save space.
    private static let compactTabThreshold = 3

    private var useCompactTabs: Bool {
        tabs.filter(\.isCloseable).count > Self.compactTabThreshold
    }

    private func tabLabel(_ tab: WorkspaceTab) -> String? {
        switch tab {
        case .info: return NSLocalizedString("Info", comment: "")
        case .agent: return NSLocalizedString("Agent", comment: "")
        case .changes: return NSLocalizedString("Changes", comment: "")
        case .terminal:
            return nil
        case let .browser(id):
            guard !useCompactTabs else { return nil }
            guard let title = browserTitles[id], !title.isEmpty else { return nil }
            return title.count > 20 ? String(title.prefix(20)) + "..." : title
        case let .editor(id):
            guard let path = editorFilePaths[id] else { return nil }
            let name = (path as NSString).lastPathComponent
            return name.count > 20 ? String(name.prefix(20)) + "..." : name
        }
    }

    private func tabIcon(_ tab: WorkspaceTab) -> String {
        switch tab {
        case .info: return "info.circle"
        case .agent: return "sparkle"
        case .changes: return "arrow.triangle.branch"
        case .terminal: return "terminal"
        case .browser: return "globe"
        case .editor: return "doc.text"
        }
    }

    private func closeableTabShortcut(_ tab: WorkspaceTab) -> String? {
        guard tab.isCloseable,
              let idx = tabs.firstIndex(of: tab),
              idx < 9 else { return nil }
        return "\(idx + 1)"
    }

    private func tabShortcut(_ tab: WorkspaceTab) -> String? {
        switch tab {
        case .info: return "1"
        case .agent: return "\u{21A9}"
        case .changes: return "D"
        default: return nil
        }
    }

    private func tabDragIdentifier(_ tab: WorkspaceTab) -> String {
        switch tab {
        case let .terminal(id), let .browser(id), let .editor(id):
            return id.uuidString
        case .info:
            return "info"
        case .agent:
            return "agent"
        case .changes:
            return "changes"
        }
    }

    private func addTerminal() {
        terminalCount += 1
        let id = derivedUUID(from: workstreamID, salt: "terminal-\(terminalCount)")
        let tab = WorkspaceTab.terminal(id)
        tabs.append(tab)
        activeTab = tab
        saveTabSnapshot()
        Telemetry.shared.track("tab_opened", url: "/tab/terminal", title: "Terminal Tab", data: ["kind": "terminal"])
    }

    private func addBrowser() {
        startRunIfNeeded()
        browserCount += 1
        let id = derivedUUID(from: workstreamID, salt: "browser-\(browserCount)")
        let tab = WorkspaceTab.browser(id)
        tabs.append(tab)
        activeTab = tab
        saveTabSnapshot()
        Telemetry.shared.track("tab_opened", url: "/tab/browser", title: "Browser Tab", data: ["kind": "browser"])
    }

    /// Starts the dev server when the browser asks for it. Attaches to a
    /// healthy server instead of restarting it: previously every new browser
    /// tab killed an Info-started server, churning ports (8080 -> 8081).
    private func startRunIfNeeded() {
        guard resolvedRunCommand != nil else { return }
        guard sessionMode != .waitingForTools, !appEnv.isDetecting else { return }
        guard setupGateState != .awaitingApproval else { return }
        if runCommandIsGated, !scriptsApproved { return }
        if runStarted {
            // Our flag says running and the session is alive: attach.
            if portDetector.status != .none { return }
            // Stale flag (process died without us noticing): fall through
            // to a fresh start below.
        } else if portDetector.status != .none {
            // A live session we don't own (restored tmux, external start):
            // adopt it instead of spawning a duplicate server.
            runOwner = .browser
            runStoppedManually = false
            runGeneration += 1
            if let command = resolvedRunCommand {
                runCommandString = buildRunCommand(script: command, generation: runGeneration)
            }
            runStarted = true
            saveTabSnapshot()
            return
        }
        doStartRun(owner: .browser)
    }

    /// Starts the run session unconditionally. Used by the Info pane controls,
    /// which have already validated approval state.
    @MainActor
    private func doStartRun(owner: RunOwner = .info) {
        guard let command = resolvedRunCommand else { return }
        let oldRunID = runID
        killRunProcessesAndStateFile()
        runStoppedManually = false
        runGeneration += 1
        runOwner = owner
        runCommandString = buildRunCommand(script: command, generation: runGeneration)
        runStarted = true
        SurfaceEventLogger.logInfo(workstreamID: workstreamID, "run-start gen=\(runGeneration) owner=\(owner.rawValue) cmd=\(SurfaceEventLogger.preview(command))")
        markBrowserStartPending()
        preloadRunSurface()
        // Destroy the retired surface after this render commits: removing it
        // synchronously lets an in-flight terminal view recreate the retired
        // generation (a zombie server whose state file the next cleanup then
        // refuses to delete). The new generation already has its own surface.
        let cache = surfaceCache
        DispatchQueue.main.async {
            cache.removeSurface(for: oldRunID)
        }
        saveTabSnapshot()
        Telemetry.shared.track(
            "dev_server_start",
            url: "/tab/browser",
            title: "Dev Server",
            data: ["source": (resolvedDevCommand?.source ?? .configScript).rawValue]
        )
    }

    private func stopRun() {
        let oldGeneration = runGeneration
        let oldRunID = runID
        let priorState = RunStateStore.load(for: workstreamID)
        // Flip UI state first so the next render unmounts the run terminal
        // before its surface is destroyed: destroying first lets an in-flight
        // update recreate the retired generation's surface (a zombie server
        // that looks alive in browser tabs while Info shows stopped).
        runStoppedManually = true
        runStarted = false
        runOwner = .none
        browserStartPending = false
        runCommandString = nil
        runGeneration += 1
        killRunProcessesAndStateFile()
        let pidDescription = priorState.map { String($0.pid) } ?? "none"
        let fileGenDescription = priorState?.generation.map { String($0) } ?? "none"
        SurfaceEventLogger.logInfo(workstreamID: workstreamID, "run-stop oldGen=\(oldGeneration) newGen=\(runGeneration) pid=\(pidDescription) fileGen=\(fileGenDescription)")
        let cache = surfaceCache
        DispatchQueue.main.async {
            cache.removeSurface(for: oldRunID)
        }
        saveTabSnapshot()
    }

    private func restartRun() {
        guard resolvedRunCommand != nil else { return }
        let owner: RunOwner = runOwner == .none ? .info : runOwner
        let oldRunID = runID
        killRunProcessesAndStateFile()
        runStoppedManually = false
        markBrowserStartPending()
        runGeneration += 1
        runOwner = owner
        if let command = resolvedRunCommand {
            runCommandString = buildRunCommand(script: command, generation: runGeneration)
        }
        runStarted = true
        SurfaceEventLogger.logInfo(workstreamID: workstreamID, "run-restart gen=\(runGeneration) owner=\(owner.rawValue)")
        preloadRunSurface()
        let cache = surfaceCache
        DispatchQueue.main.async {
            cache.removeSurface(for: oldRunID)
        }
        saveTabSnapshot()
    }

    /// Kill the previous dev-server session's processes and state file without
    /// flipping any UI flags or touching surfaces. Kills the tmux run session
    /// (when in tmux mode), the recorded process tree (so daemonized
    /// grandchildren release the port), and unconditionally removes this
    /// workstream's state file: an explicit stop/start owns the file, unlike
    /// the ff-run monitor's teardown which must only remove its own
    /// generation (see RunStateStore.removeIfGenerationMatches) so a rapid
    /// stop -> start cannot orphan the UI.
    private func killRunProcessesAndStateFile() {
        killRunTmuxSession()
        if let state = RunStateStore.load(for: workstreamID) {
            RunProcessKiller.killTree(root: state.pid)
        }
        RunStateStore.remove(for: workstreamID)
    }

    /// Marks the start so browser tabs hold the waiting overlay until a port
    /// appears. Self-clears after a few seconds so a failed spawn (nothing
    /// ever wrote state) still falls through to the error view.
    @MainActor
    private func markBrowserStartPending() {
        browserStartPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [self] in
            guard self.browserStartPending else { return }
            self.browserStartPending = false
        }
    }

    /// Clears a stale `runStarted` flag when no session materializes. The
    /// grace window covers slow boots (ff-run writes `starting` immediately,
    /// but the file watcher lands a beat later). Without this, a dead server
    /// leaves the Info panel showing Stop/Rerun over an idle Start button.
    private func clearStaleRunFlagAfterGracePeriod() {
        let generationAtSchedule = runGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [self] in
            guard self.runStarted,
                  self.runGeneration == generationAtSchedule,
                  self.portDetector.status == .none,
                  !self.browserStartPending,
                  self.runCommandString != nil
            else { return }
            self.runStarted = false
            self.runOwner = .none
            self.runCommandString = nil
            self.saveTabSnapshot()
        }
    }

    /// Create the run surface eagerly so the dev server starts even while the
    /// browser tab is active and the Info pane is not rendered.
    private func preloadRunSurface() {
        guard let commandString = runCommandString else { return }
        guard let app = TerminalApp.shared.app else { return }
        _ = surfaceCache.surface(
            for: runID,
            app: app,
            workingDirectory: workingDirectory,
            command: commandString,
            environmentVars: runEnvironmentVars
        )
    }

    /// Assembles the final run command: ff-run wrap (port detection) + tmux wrap.
    private func buildRunCommand(script: String, generation: Int) -> String {
        let baseCommand: String
        let ffRunPath = RunLauncher.executableURL()?.path
        if let launcherPath = ffRunPath {
            baseCommand = runScriptCommand(script: script, workstreamID: workstreamID, launcherPath: launcherPath, generation: generation)
        } else {
            baseCommand = scriptCommand(script: script, role: "run")
        }

        let finalCommand: String
        if useTmux, let tmuxPath = appEnv.toolStatus.tmux.path {
            let session = TmuxSession.sessionName(project: projectName, workstream: workstreamName, role: "run")
            finalCommand = TmuxSession.wrapCommand(tmuxPath: tmuxPath, sessionName: session, command: baseCommand, environmentVars: runEnvironmentVars)
        } else {
            finalCommand = baseCommand
        }

        var intermediates = [script, baseCommand]
        if finalCommand != baseCommand {
            intermediates.append(finalCommand)
        }
        LaunchLogger.log(LaunchLogEntry(
            workstreamID: workstreamID,
            event: "run-start",
            finalCommand: finalCommand,
            intermediateCommands: intermediates,
            environmentVariables: runEnvironmentVars,
            workingDirectory: workingDirectory,
            toolPaths: LaunchLogEntry.ToolPaths(
                claude: nil,
                tmux: useTmux ? appEnv.toolStatus.tmux.path : nil,
                ffRun: ffRunPath
            ),
            settings: LaunchLogEntry.Settings(
                tmuxMode: useTmux,
                bypassPermissions: false,
                agentTeams: false,
                autoRenameBranch: false,
                allowOutsideWorktree: false
            ),
            shell: CommandBuilder.userShell
        ))

        return finalCommand
    }

    private func killRunTmuxSession() {
        guard useTmux, let tmuxPath = appEnv.toolStatus.tmux.path else { return }
        let session = TmuxSession.sessionName(project: projectName, workstream: workstreamName, role: "run")
        TmuxSession.killSession(tmuxPath: tmuxPath, sessionName: session)
    }

    private func openEditor() {
        addEditor()
    }

    /// Activate the always-present Changes tab.
    private func addChanges() {
        activeTab = .changes
    }

    private func addEditor(filePath: String? = nil) {
        // Create bridge before adding the tab — never during body evaluation
        createEditorBridgeIfNeeded()
        editorCount += 1
        let id = derivedUUID(from: workstreamID, salt: "editor-\(editorCount)")
        if let filePath {
            editorFilePaths[id] = filePath
        }
        let tab = WorkspaceTab.editor(id)
        tabs.append(tab)
        activeTab = tab
        startFileTreeWatcherIfNeeded()
        saveTabSnapshot()
        Telemetry.shared.track("tab_opened", url: "/tab/editor", title: "Editor Tab", data: ["kind": "editor"])
    }

    private func startFileTreeWatcherIfNeeded() {
        guard directoryWatcher == nil else { return }
        refreshFileTree()
        directoryWatcher = DirectoryWatcher(path: workingDirectory) { [self] in
            debounceRefreshFileTree()
        }
    }

    private func debounceRefreshFileTree() {
        refreshDebounceTask?.cancel()
        refreshDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            refreshFileTree()
        }
    }

    private func refreshFileTree() {
        refreshGeneration += 1
        let gen = refreshGeneration
        let currentTree = fileTree
        DispatchQueue.global(qos: .userInitiated).async {
            let tree: [FileNode]
            if currentTree.isEmpty {
                tree = FileNode.buildShallowTree(rootPath: workingDirectory)
            } else {
                tree = FileNode.refreshLoadedNodes(in: currentTree, rootPath: workingDirectory)
            }
            let statuses = GitOperations.fileStatuses(at: workingDirectory)
            DispatchQueue.main.async {
                guard gen == refreshGeneration else { return }
                fileTree = tree
                gitFileStatuses = GitFileStatusProvider(fileStatuses: statuses)
            }
        }
    }

    private func expandFileTreeFolder(_ relativePath: String) {
        if let node = FileNode.findNode(atPath: relativePath, in: fileTree), node.isLoaded { return }
        let gen = refreshGeneration
        let root = workingDirectory
        DispatchQueue.global(qos: .userInitiated).async {
            let children = FileNode.loadChildren(atRelativePath: relativePath, rootPath: root)
            DispatchQueue.main.async {
                guard gen == refreshGeneration else { return }
                fileTree = FileNode.insertChildren(children, atPath: relativePath, in: fileTree)
            }
        }
    }

    private func stopFileTreeWatcherIfUnneeded() {
        let hasEditorTabs = tabs.contains { if case .editor = $0 { return true } else { return false } }
        if !hasEditorTabs {
            refreshGeneration += 1
            directoryWatcher?.stop()
            directoryWatcher = nil
            fileTree = []
            gitFileStatuses = GitFileStatusProvider()
            // Keep editorBridge alive — the WebView is expensive to recreate (~17 MB JS)
        }
    }

    private func createEditorBridgeIfNeeded() {
        guard editorBridge == nil else { return }
        let bridge = MonacoEditorBridge()
        bridge.onContentChanged = { [self] modelId, dirty in
            if let uuid = UUID(uuidString: modelId) {
                editorDirtyState[uuid] = dirty
                if case .editor(uuid) = activeTab {
                    editorFileDirty = dirty
                }
            }
        }
        editorBridge = bridge
    }

    private func createDiffBridgeIfNeeded() {
        guard diffBridge == nil else { return }
        diffBridge = MonacoDiffBridge()
    }

    private func closeTab(_ tab: WorkspaceTab) {
        if case let .editor(id) = tab, editorDirtyState[id] == true {
            confirmCloseEditor(tab: tab, id: id)
            return
        }
        forceCloseTab(tab)
    }

    private func confirmCloseEditor(tab: WorkspaceTab, id: UUID) {
        let fileName = (editorFilePaths[id] as? NSString)?.lastPathComponent ?? "file"
        let alert = NSAlert()
        alert.messageText = String(
            format: NSLocalizedString("Do you want to save changes to \"%@\"?", comment: ""),
            fileName
        )
        alert.informativeText = NSLocalizedString("Your changes will be lost if you don't save them.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Save", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Don't Save", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alert.alertStyle = .warning

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            // Save then close — async to wait for bridge.getContent()
            Task {
                if let bridge = editorBridge,
                   let relativePath = editorFilePaths[id]
                {
                    let fullPath = (workingDirectory as NSString)
                        .appendingPathComponent(relativePath)
                    guard let content = await bridge.getContent(modelId: id.uuidString) else { return }
                    do {
                        try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
                    } catch {
                        let errorAlert = NSAlert(error: error)
                        errorAlert.runModal()
                        return
                    }
                }
                forceCloseTab(tab)
            }
        case .alertSecondButtonReturn:
            // Don't save, just close
            forceCloseTab(tab)
        default:
            // Cancel — do nothing
            break
        }
    }

    private func forceCloseTab(_ tab: WorkspaceTab) {
        guard let index = tabs.firstIndex(of: tab) else { return }
        tabs.remove(at: index)
        // Clean up cached views
        switch tab {
        case let .terminal(id):
            surfaceCache.removeSurface(for: id)
        case let .browser(id):
            surfaceCache.removeWebView(for: id)
            browserLastDefaultURLs.removeValue(forKey: id)
            // Only browser-owned servers stop with the last browser tab.
            // Info-started servers survive so the user can browse away and
            // back without churning ports.
            let hasBrowserTabs = tabs.contains { tab in
                if case .browser = tab { return true }
                return false
            }
            if !hasBrowserTabs, runOwner == .browser { stopRun() }
        case let .editor(id):
            editorFilePaths.removeValue(forKey: id)
            editorDirtyState.removeValue(forKey: id)
            editorBridge?.closeModel(modelId: id.uuidString)
        default:
            break
        }
        stopFileTreeWatcherIfUnneeded()
        // Switch to previous tab or agent
        if activeTab == tab {
            let newIndex = min(index, tabs.count - 1)
            activeTab = tabs[newIndex]
        }
        saveTabSnapshot()
    }

    private func currentTabSnapshot() -> WorkspaceTabSnapshot {
        WorkspaceTabSnapshot(
            tabs: tabs,
            terminalCount: terminalCount,
            browserCount: browserCount,
            editorCount: editorCount,
            activeTab: activeTab,
            browserTitles: browserTitles,
            terminalTitles: terminalTitles,
            editorFilePaths: editorFilePaths,
            runStarted: runStarted,
            runStoppedManually: runStoppedManually,
            runGeneration: runGeneration,
            runOwner: runOwner
        )
    }

    private func saveTabSnapshot() {
        surfaceCache.saveTabSnapshot(for: workstreamID, snapshot: currentTabSnapshot())
    }

    private func moveCustomTab(to targetTab: WorkspaceTab) {
        guard let currentDraggedTab = draggedCustomTab else { return }
        tabs = reorderedCustomTabs(tabs, dragging: currentDraggedTab, to: targetTab)
        draggedCustomTab = nil
    }

    @MainActor
    private func startWorkspace(defaultBranch: String) {
        workspaceStarted = true
        self.defaultBranch = defaultBranch
        quickActionRunner.onSuccess = { action in
            appEnv.refreshWorktreeState(for: workingDirectory, projectDirectory: projectDirectory)
            if let branch = appEnv.branchName(for: workingDirectory) {
                if action == .closePR {
                    appEnv.clearBranchPR(for: projectDirectory, branch: branch)
                }
                if action == .createPR || action == .closePR {
                    appEnv.refreshGitHubInfo(for: projectDirectory, branch: branch)
                }
            }
        }
        appEnv.refreshWorktreeState(for: workingDirectory, projectDirectory: projectDirectory)
        rebuildAgentCommand()
        logger.info("startWorkspace \(workstreamID) harness=\(harness.rawValue, privacy: .public) liveAgent=\(surfaceCache.hasSurface(for: claudeID), privacy: .public)")
        SurfaceEventLogger.logDetailed(workstreamID: workstreamID, "workspace-enter harness=\(harness.rawValue) liveAgent=\(surfaceCache.hasSurface(for: claudeID)) trackedOpencodeSession=\(trackedOpencodeSessionID ?? "none") cmd=\(SurfaceEventLogger.preview(cachedAgentCommand))")
        scriptsApproved = ScriptTrust.isApproved(scriptConfig, for: projectDirectory)
        setupGateState = SetupGateState.resolve(
            hasSetupScript: scriptConfig.setup != nil,
            setupCompleted: SetupStateStore.isCompleted(for: workstreamID),
            scriptsApproved: scriptsApproved
        )
        if setupGateState == .notNeeded {
            surfaceCache.respawnableIDs.insert(claudeID)
        }
        restoreRunCommandAfterReentry()
        preloadSurfaces()
        // Eagerly create the Monaco bridge so it's ready when the user opens
        // an editor tab. The WKWebView is created lazily when MonacoEditorView
        // enters the tree (it needs a real container to avoid 0x0 initialization).
        createEditorBridgeIfNeeded()
        createDiffBridgeIfNeeded()
        surfaceCache.updateOcclusion(visibleSurfaceIDs: visibleSurfaceIDs)
    }

    /// Rebuild the run command after returning to a workspace. The tab
    /// snapshot restores `runStarted`/`runGeneration` but not the assembled
    /// command string, and `onChange(runStarted)` does not fire when the
    /// value is unchanged — so without this the Info panel shows
    /// Stop/Rerun over an idle Start button. When nothing can be rebuilt
    /// (no command configured), drop the stale flag instead.
    private func restoreRunCommandAfterReentry() {
        guard runStarted, runCommandString == nil else { return }
        if let command = resolvedRunCommand {
            runCommandString = buildRunCommand(script: command, generation: runGeneration)
            preloadRunSurface()
        } else {
            runStarted = false
            runOwner = .none
        }
    }

    /// Pre-create terminal surfaces so they start running before their tab is visible.
    private func preloadSurfaces() {
        guard sessionMode != .waitingForTools else { return }
        guard let app = TerminalApp.shared.app else { return }
        // Nothing may start while the setup script is waiting to be approved.
        guard setupGateState != .awaitingApproval else { return }

        if setupGateState == .running {
            // Setup gate: only preload setup surface, agent waits.
            if let cmd = buildSetupGateCommand() {
                _ = surfaceCache.surface(
                    for: setupGateID,
                    app: app,
                    workingDirectory: workingDirectory,
                    command: cmd,
                    environmentVars: terminalEnvVars,
                    waitAfterCommand: false
                )
            }
        } else {
            // Agent surface: attach non-destructively. A live agent must
            // survive passive workspace re-entry even when the rebuilt
            // command drifted (opencode session file, tool detection, rename).
            if let cmd = cachedAgentCommand {
                _ = surfaceCache.attachAgentSurface(
                    for: claudeID,
                    app: app,
                    workingDirectory: workingDirectory,
                    command: cmd,
                    environmentVars: envVars,
                    reason: "workspace-preload"
                )
            }
        }
    }

    private func buildSetupGateCommand() -> String? {
        guard let setup = scriptConfig.setup else { return nil }
        return scriptCommand(script: setup, role: "setup")
    }

    /// Env vars for plain terminal tabs. Clears tmux vars to prevent inheritance.
    private var terminalEnvVars: [String: String] {
        var vars = envVars
        vars["TMUX"] = ""
        vars["TMUX_PANE"] = ""
        return vars
    }

    private var envVars: [String: String] {
        workspaceEnvironmentVariables(
            workstreamID: workstreamID,
            projectName: projectName,
            workstreamName: workstreamName,
            projectDirectory: projectDirectory,
            workingDirectory: workingDirectory,
            port: workstreamPort,
            agentTeams: agentTeams,
            defaultBranch: defaultBranch,
            scriptSource: scriptConfig.source,
            harness: harness
        )
    }

    private var setupApprovalView: some View {
        ScriptApprovalView(
            scriptConfig: scriptConfig,
            approveLabel: NSLocalizedString("Approve and Run Setup", comment: ""),
            onApprove: approveScripts,
            secondaryLabel: NSLocalizedString("Skip Setup", comment: ""),
            onSecondary: launchAgentAfterSetup
        )
    }

    private func approveScripts() {
        ScriptTrust.approve(scriptConfig, for: projectDirectory)
        scriptsApproved = true
        startApprovedSetup()
    }

    /// Runs the setup script once its commands have been approved.
    private func startApprovedSetup() {
        guard setupGateState == .awaitingApproval else { return }
        setupGateState = .running
        preloadSurfaces()
        surfaceCache.updateOcclusion(visibleSurfaceIDs: visibleSurfaceIDs)
    }

    private var setupGateRunningView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Running setup...")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.bar)
            Divider()
            SingleTerminalView(
                surfaceID: setupGateID,
                workingDirectory: workingDirectory,
                command: buildSetupGateCommand() ?? "",
                isFocused: true,
                environmentVars: terminalEnvVars
            )
        }
    }

    private var setupGateFailedView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 11))
                Text("Setup failed.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Continue to Agent") {
                    launchAgentAfterSetup()
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.bar)
            Divider()
            SingleTerminalView(
                surfaceID: setupGateID,
                workingDirectory: workingDirectory,
                command: buildSetupGateCommand() ?? "",
                isFocused: false,
                environmentVars: terminalEnvVars
            )
        }
    }

    private func handleSetupChildExited(exitCode: Int32) {
        guard setupGateState == .running else { return }
        if exitCode == 0 {
            launchAgentAfterSetup()
        } else {
            setupGateState = .failed
        }
    }

    private func launchAgentAfterSetup() {
        SetupStateStore.markCompleted(for: workstreamID)
        surfaceCache.removeSurface(for: setupGateID)
        setupGateState = .completed
        surfaceCache.respawnableIDs.insert(claudeID)
        preloadSurfaces()
        surfaceCache.updateOcclusion(visibleSurfaceIDs: visibleSurfaceIDs)
    }

    private func terminalLoadingView(message: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab button

private struct WorkspaceTabButton: View {
    let tab: WorkspaceTab
    let label: String?
    let icon: String
    var shortcut: String? = nil
    let isActive: Bool
    var isDirty: Bool = false
    let onSelect: () -> Void
    var onClose: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 4) {
            if isDirty {
                Circle()
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 6, height: 6)
            }
            Image(systemName: icon)
                .font(.system(size: 11))
            if let label {
                Text(label)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                    .lineLimit(1)
            }
            if let shortcut {
                (Text(Image(systemName: "command")) + Text(shortcut))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            if let onClose, isHovering || isActive {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
                    .onTapGesture(perform: onClose)
                    .accessibilityLabel("Close tab")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(isActive ? Color.accentColor.opacity(0.15) : (isHovering ? Color.primary.opacity(0.05) : .clear))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .foregroundStyle(isActive ? .primary : .secondary)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }
}

private struct TabBarActionButton: View {
    let icon: String
    let shortcut: String
    let tooltip: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(isHovering ? .primary : .tertiary)
            .padding(.horizontal, 6)
            .frame(minHeight: 24)
            .background(isHovering ? Color.primary.opacity(0.08) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }
        .help(tooltip)
    }
}

private struct WorkspaceTabDropDelegate: DropDelegate {
    let onDropTab: () -> Void

    func validateDrop(info _: DropInfo) -> Bool {
        true
    }

    func performDrop(info _: DropInfo) -> Bool {
        onDropTab()
        return true
    }
}

private struct GitHubActionMenu: View {
    @ObservedObject var runner: QuickActionRunner
    let harness: CodingHarness
    let agentPath: String?
    let ghPath: String?
    let workingDirectory: String
    let branchName: String?
    let bypassPermissions: Bool
    let worktreeState: WorktreeState
    let hasGitHubRemote: Bool
    let branchPR: GitHubPR?

    private var prState: String? {
        branchPR?.state
    }

    private var hasOpenPR: Bool {
        prState == "OPEN"
    }

    private var isMerged: Bool {
        prState == "MERGED"
    }

    /// The most relevant next action to move the workflow forward.
    private var primaryAction: PrimaryAction? {
        if isMerged {
            return nil
        }
        if hasOpenPR {
            if worktreeState.hasUncommittedChanges {
                return .quickAction(.commit)
            }
            if worktreeState.hasUnpushedCommits, worktreeState.hasRemote {
                return .quickAction(.push)
            }
            if let pr = branchPR {
                return .openPR(pr)
            }
        }
        if prState == nil, hasGitHubRemote, worktreeState.hasBranchCommits {
            return .quickAction(.createPR)
        }
        if worktreeState.hasUncommittedChanges {
            return .quickAction(.commit)
        }
        if worktreeState.hasUnpushedCommits, worktreeState.hasRemote {
            return .quickAction(.push)
        }
        return nil
    }

    /// Secondary actions shown in the dropdown, excluding the primary.
    private var secondaryActions: [PrimaryAction] {
        guard let primary = primaryAction else { return [] }
        var actions: [PrimaryAction] = []

        if worktreeState.hasUncommittedChanges {
            actions.append(.quickAction(.commit))
        }
        if worktreeState.hasUnpushedCommits, worktreeState.hasRemote {
            actions.append(.quickAction(.push))
        }
        if prState == nil, hasGitHubRemote, worktreeState.hasBranchCommits {
            actions.append(.quickAction(.createPR))
        }
        if let pr = branchPR, hasOpenPR {
            actions.append(.openPR(pr))
            actions.append(.quickAction(.closePR))
        }

        return actions.filter { $0 != primary }
    }

    private var isRunning: Bool {
        if case .running = runner.state { return true }
        return false
    }

    private func isRunningAction(_ action: QuickAction) -> Bool {
        if case let .running(a) = runner.state { return a == action }
        return false
    }

    private func resultState(for action: QuickAction) -> QuickActionState? {
        switch runner.state {
        case let .succeeded(a) where a == action: return runner.state
        case let .failed(a) where a == action: return runner.state
        default: return nil
        }
    }

    private func disabledReason(for action: QuickAction) -> String? {
        if action.usesLLM {
            if agentPath == nil {
                return String(format: NSLocalizedString("%@ is not installed.", comment: "Quick actions unavailable because the coding agent CLI is missing"), harness.displayName)
            }
            if !bypassPermissions {
                return NSLocalizedString("Enable \"Bypass permission prompts\" in Settings.", comment: "")
            }
        }
        if action == .closePR, ghPath == nil {
            return NSLocalizedString("gh CLI is not installed.", comment: "")
        }
        return nil
    }

    private func runAction(_ action: QuickAction) {
        guard disabledReason(for: action) == nil else { return }
        runner.run(
            action: action,
            harness: harness,
            agentPath: agentPath,
            ghPath: ghPath,
            workingDirectory: workingDirectory,
            branchName: branchName
        )
    }

    private func executePrimary(_ action: PrimaryAction) {
        guard !isRunning else { return }
        switch action {
        case let .quickAction(qa):
            runAction(qa)
        case let .openPR(pr):
            if let url = URL(string: pr.url) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @ViewBuilder
    private func label(for action: PrimaryAction) -> some View {
        switch action {
        case let .quickAction(qa):
            if isRunningAction(qa) {
                ProgressView()
                    .controlSize(.mini)
            } else if case .succeeded = resultState(for: qa) {
                Label(qa.label, systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.green)
            } else if case .failed = resultState(for: qa) {
                Label(qa.label, systemImage: "xmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.red)
            } else {
                Label(qa.label, systemImage: qa.icon)
                    .labelStyle(.titleAndIcon)
            }
        case let .openPR(pr):
            Label(
                String(format: NSLocalizedString("Open #%d", comment: ""), pr.number),
                systemImage: "arrow.up.forward"
            )
            .labelStyle(.titleAndIcon)
        }
    }

    var body: some View {
        if let primary = primaryAction {
            let secondary = secondaryActions
            if secondary.isEmpty {
                Button { executePrimary(primary) } label: { label(for: primary) }
                    .disabled(isRunning || primaryDisabled(primary))
                    .help(primaryHelp(primary))
            } else {
                Menu {
                    ForEach(secondary) { action in
                        switch action {
                        case let .quickAction(qa):
                            Button { runAction(qa) } label: {
                                Label(qa.label, systemImage: qa.icon)
                            }
                            .disabled(isRunning || disabledReason(for: qa) != nil)
                        case let .openPR(pr):
                            Button {
                                if let url = URL(string: pr.url) {
                                    NSWorkspace.shared.open(url)
                                }
                            } label: {
                                Label(
                                    String(format: NSLocalizedString("Open #%d", comment: ""), pr.number),
                                    systemImage: "arrow.up.forward"
                                )
                            }
                        }
                    }
                } label: {
                    label(for: primary)
                } primaryAction: {
                    executePrimary(primary)
                }
                .disabled(isRunning)
                .menuIndicator(.hidden)
                .help(primaryHelp(primary))
            }
        }
    }

    private func primaryDisabled(_ action: PrimaryAction) -> Bool {
        if case let .quickAction(qa) = action {
            return disabledReason(for: qa) != nil
        }
        return false
    }

    private func primaryHelp(_ action: PrimaryAction) -> String {
        if case let .quickAction(qa) = action {
            return disabledReason(for: qa) ?? qa.label
        }
        if case let .openPR(pr) = action {
            return pr.title
        }
        return ""
    }
}

/// Represents either a quick action or opening a PR in the browser.
private enum PrimaryAction: Equatable, Identifiable {
    case quickAction(QuickAction)
    case openPR(GitHubPR)

    var id: String {
        switch self {
        case let .quickAction(qa): return qa.id
        case let .openPR(pr): return "openPR-\(pr.number)"
        }
    }
}

private struct ScrollableTabStrip<TabContent: View>: View {
    let tabs: [WorkspaceTab]
    let activeTab: WorkspaceTab
    @ViewBuilder let tabButton: (WorkspaceTab) -> TabContent

    @State private var contentOverflows = false
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0

    private var canScrollLeft: Bool {
        scrollOffset > 0
    }

    private var canScrollRight: Bool {
        scrollOffset < contentWidth - viewportWidth
    }

    var body: some View {
        HStack(spacing: 0) {
            if contentOverflows, canScrollLeft {
                scrollArrow(direction: .left)
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.self) { tab in
                            tabButton(tab)
                                .id(tab)
                        }
                    }
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ContentWidthKey.self, value: geo.size.width)
                    })
                }
                .onPreferenceChange(ContentWidthKey.self) { width in
                    contentWidth = width
                    checkOverflow()
                }
                .background(GeometryReader { geo in
                    Color.clear
                        .onAppear { viewportWidth = geo.size.width; checkOverflow() }
                        .onChange(of: geo.size.width) { _, new in viewportWidth = new; checkOverflow() }
                })
                .onChange(of: activeTab) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(activeTab, anchor: .center)
                    }
                }
            }

            if contentOverflows, canScrollRight {
                scrollArrow(direction: .right)
            }
        }
    }

    private enum ScrollDirection {
        case left, right
    }

    private func scrollArrow(direction: ScrollDirection) -> some View {
        Button(action: {}) {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }

    private func checkOverflow() {
        contentOverflows = contentWidth > viewportWidth + 1
    }
}

private struct ContentWidthKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct AddTabButton: View {
    let label: String
    let icon: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11))
                (Text(Image(systemName: "command")) + Text(shortcut))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHovering ? Color.primary.opacity(0.05) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }
    }
}

// MARK: - SingleTerminalView

struct SingleTerminalView: View {
    let surfaceID: UUID
    let workingDirectory: String
    var command: String?
    var initialInput: String?
    var isFocused: Bool = true
    var environmentVars: [String: String] = [:]

    @EnvironmentObject var surfaceCache: TerminalSurfaceCache

    var body: some View {
        if let failedCommand = surfaceCache.failedSurfaces[surfaceID] {
            SurfaceErrorView(command: failedCommand) {
                surfaceCache.retrySurface(for: surfaceID)
            }
        } else {
            GeometryReader { geo in
                TerminalSurfaceView(
                    surfaceID: surfaceID,
                    workingDirectory: workingDirectory,
                    command: command,
                    initialInput: initialInput,
                    isFocused: isFocused,
                    environmentVars: environmentVars,
                    size: geo.size
                )
            }
        }
    }
}

private struct SurfaceErrorView: View {
    let command: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Terminal failed to start")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(command)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(3)
                .truncationMode(.middle)
                .padding(.horizontal, 40)
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TerminalSurfaceView: NSViewRepresentable {
    let surfaceID: UUID
    let workingDirectory: String
    var command: String?
    var initialInput: String?
    var isFocused: Bool = true
    var environmentVars: [String: String] = [:]
    var size: CGSize

    @EnvironmentObject var surfaceCache: TerminalSurfaceCache

    func makeNSView(context _: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        return container
    }

    func updateNSView(_ container: NSView, context _: Context) {
        guard let app = TerminalApp.shared.app else { return }

        let terminalView = surfaceCache.surface(
            for: surfaceID,
            app: app,
            workingDirectory: workingDirectory,
            command: command,
            initialInput: initialInput,
            environmentVars: environmentVars
        )

        if terminalView.superview !== container {
            terminalView.removeFromSuperview()
            container.subviews.forEach { $0.removeFromSuperview() }
            container.addSubview(terminalView)
            terminalView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                terminalView.topAnchor.constraint(equalTo: container.topAnchor),
                terminalView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                terminalView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                terminalView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        }

        // Explicitly push the SwiftUI-measured size to the Ghostty surface.
        // SwiftUI does not reliably call NSView.setFrameSize on resize
        // (see Ghostty SurfaceView.swift:613-616), so we drive it from
        // the GeometryReader instead.
        if terminalView.window != nil {
            terminalView.notifySizeChanged(size)
        }

        if isFocused {
            DispatchQueue.main.async {
                terminalView.window?.makeFirstResponder(terminalView)
            }
        }
    }
}

// MARK: - Quick action debug

private struct QuickActionDebugView: View {
    @ObservedObject var runner: QuickActionRunner

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Quick Action Log")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                if !runner.log.isEmpty {
                    Button("Clear") { runner.clearLog() }
                        .font(.system(size: 10))
                        .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            if runner.log.isEmpty {
                Text("No quick actions run yet.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(runner.log) { entry in
                            QuickActionLogRow(entry: entry)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(height: 200)
        .background(.background)
    }
}

private struct QuickActionLogRow: View {
    let entry: QuickActionLogEntry
    @State private var showsRawOutput = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(Self.timeFormatter.string(from: entry.timestamp))
                    .foregroundStyle(.tertiary)
                Text(entry.action.label)
                    .foregroundStyle(.primary)
                if let code = entry.exitCode {
                    Text("exit \(code)")
                        .foregroundStyle(code == 0 ? .green : .red)
                } else {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))

            Text("$ " + entry.command)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            summarySection

            if !entry.output.isEmpty {
                DisclosureGroup(isExpanded: $showsRawOutput) {
                    Text(entry.output)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("Raw output")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    /// Parsed assistant-text result, or a placeholder while streaming.
    @ViewBuilder
    private var summarySection: some View {
        if let summary = entry.summary, !summary.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                if let artifactURL = entry.artifactURL, let url = URL(string: artifactURL) {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label(artifactLabel, systemImage: "arrow.up.forward")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .help(url.absoluteString)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 5))
        } else if entry.exitCode == nil {
            Text("Working…")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    private var artifactLabel: String {
        if entry.artifactURL?.contains("/pull/") == true {
            return NSLocalizedString("Open Pull Request", comment: "Opens the PR created by a quick action")
        }
        return NSLocalizedString("Open Link", comment: "Opens an artifact link produced by a quick action")
    }
}

// MARK: - Surface cache

extension Notification.Name {
    static let terminalTabExited = Notification.Name("factoryfloor.terminalTabExited")
}

@MainActor
final class TerminalSurfaceCache: ObservableObject {
    private var surfaces: [UUID: TerminalView] = [:]
    private var surfaceParams: [UUID: SurfaceParams] = [:]
    private var tabSnapshots: [UUID: WorkspaceTabSnapshot] = [:]
    private var webViews: [UUID: WKWebView] = [:]
    private var quickActionRunners: [UUID: QuickActionRunner] = [:]
    /// Surface IDs that should respawn when closed (e.g., the agent).
    var respawnableIDs: Set<UUID> = []
    /// Guards against concurrent respawns for the same surface ID.
    private var respawning = Set<UUID>()
    /// Surface IDs where creation failed, with the command that was attempted.
    private(set) var failedSurfaces: [UUID: String] = [:]
    /// Tracks when each surface was created, for detecting immediate process death.
    private var creationTimes: [UUID: Date] = [:]
    /// Surfaces that died within this interval after creation are treated as launch failures.
    private static let healthCheckWindow: TimeInterval = 2.0

    struct SurfaceParams {
        let workingDirectory: String
        let command: String?
        let initialInput: String?
        let environmentVars: [String: String]
        let waitAfterCommand: Bool
    }

    init() {
        NotificationCenter.default.addObserver(
            forName: .terminalSurfaceClosed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, let closedView = notification.object as? TerminalView else { return }
            Task { @MainActor in
                self.handleSurfaceClosed(closedView)
            }
        }
    }

    /// Marks surfaces in the given set as visible; all others are occluded.
    /// Pass nil to mark all surfaces as visible.
    func updateOcclusion(visibleSurfaceIDs: Set<UUID>?) {
        for (id, view) in surfaces {
            let visible = visibleSurfaceIDs.map { $0.contains(id) } ?? true
            view.setVisible(visible)
        }
    }

    /// Whether a live surface exists for `id` (without creating one).
    func hasSurface(for id: UUID) -> Bool {
        surfaces[id] != nil
    }

    func surface(for id: UUID, app: ghostty_app_t, workingDirectory: String, command: String? = nil, initialInput: String? = nil, environmentVars: [String: String] = [:], waitAfterCommand: Bool = true) -> TerminalView {
        if let existing = surfaces[id] {
            existing.workstreamID = id
            logger.detailed("Reusing surface \(id) cmd=\(SurfaceEventLogger.preview(command))")
            SurfaceEventLogger.logDetailed(workstreamID: id, "surface-reused cmd=\(SurfaceEventLogger.preview(command))")
            return existing
        }
        let view = TerminalView(app: app, workingDirectory: workingDirectory, command: command, initialInput: initialInput, environmentVars: environmentVars, waitAfterCommand: waitAfterCommand)
        view.workstreamID = id
        surfaces[id] = view
        surfaceParams[id] = SurfaceParams(workingDirectory: workingDirectory, command: command, initialInput: initialInput, environmentVars: environmentVars, waitAfterCommand: waitAfterCommand)
        if view.surface == nil {
            logger.error("Surface creation failed for \(id) command=\(command ?? "<shell>")")
            SurfaceEventLogger.logInfo(workstreamID: id, "surface-creation-failed cmd=\(SurfaceEventLogger.preview(command))")
            failedSurfaces[id] = command ?? "(default shell)"
            objectWillChange.send()
        } else {
            creationTimes[id] = Date()
            logger.info("Created surface \(id) cmd=\(SurfaceEventLogger.preview(command), privacy: .public)")
            SurfaceEventLogger.logInfo(workstreamID: id, "surface-created cmd=\(SurfaceEventLogger.preview(command)) workdir=\(workingDirectory)")
        }
        return view
    }

    /// Non-destructive attach for the agent surface on passive workspace entry.
    /// A live surface is NEVER killed here: when the rebuilt command drifted
    /// (e.g. opencode wrote a new session id while the agent was running),
    /// the live process is kept and the stored params are updated so a future
    /// genuine respawn uses the latest command. Returns the live or new view.
    func attachAgentSurface(for id: UUID, app: ghostty_app_t, workingDirectory: String, command: String?, initialInput: String? = nil, environmentVars: [String: String] = [:], waitAfterCommand: Bool = true, reason: String = "preload") -> TerminalView {
        if let existing = surfaces[id] {
            existing.workstreamID = id
            let params = surfaceParams[id]
            let cmdChanged = params?.command != command
            let dirChanged = params?.workingDirectory != workingDirectory
            if cmdChanged || dirChanged {
                logger.info("Keeping live agent surface \(id) — command drifted (\(reason, privacy: .public)); NOT replacing old=\(SurfaceEventLogger.preview(params?.command), privacy: .public) new=\(SurfaceEventLogger.preview(command), privacy: .public)")
                SurfaceEventLogger.logInfo(workstreamID: id, "surface-kept-alive reason=\(reason) dirChanged=\(dirChanged) old=\(SurfaceEventLogger.preview(params?.command)) new=\(SurfaceEventLogger.preview(command))")
                // Refresh stored params so a future genuine respawn (after a
                // real exit) uses the latest command instead of a stale one.
                surfaceParams[id] = SurfaceParams(workingDirectory: workingDirectory, command: command, initialInput: initialInput, environmentVars: environmentVars, waitAfterCommand: waitAfterCommand)
            } else {
                logger.detailed("Reusing agent surface \(id) (\(reason))")
                SurfaceEventLogger.logDetailed(workstreamID: id, "surface-reused reason=\(reason) cmd=\(SurfaceEventLogger.preview(command))")
            }
            return existing
        }
        return surface(
            for: id,
            app: app,
            workingDirectory: workingDirectory,
            command: command,
            initialInput: initialInput,
            environmentVars: environmentVars,
            waitAfterCommand: waitAfterCommand
        )
    }

    /// Explicit replacement: kills the live surface when the stored command
    /// differs. Only use for explicit user actions (e.g. an agent restart
    /// button). Passive workspace re-entry MUST use `attachAgentSurface`
    /// instead, which keeps a live agent running across command drift
    /// (opencode session-id file, tool detection, renames).
    func ensureSurface(for id: UUID, app: ghostty_app_t, workingDirectory: String, command: String?, initialInput: String? = nil, environmentVars: [String: String] = [:], waitAfterCommand: Bool = true) -> TerminalView {
        if let existing = surfaces[id],
           let params = surfaceParams[id],
           params.command == command,
           params.workingDirectory == workingDirectory
        {
            return existing
        }
        if surfaces[id] != nil {
            let old = surfaceParams[id]?.command
            logger.info("Replacing surface \(id) — command changed old=\(SurfaceEventLogger.preview(old), privacy: .public) new=\(SurfaceEventLogger.preview(command), privacy: .public)")
            SurfaceEventLogger.logInfo(workstreamID: id, "surface-replaced old=\(SurfaceEventLogger.preview(old)) new=\(SurfaceEventLogger.preview(command))")
            respawnableIDs.remove(id)
            removeSurface(for: id)
        }
        return surface(
            for: id,
            app: app,
            workingDirectory: workingDirectory,
            command: command,
            initialInput: initialInput,
            environmentVars: environmentVars,
            waitAfterCommand: waitAfterCommand
        )
    }

    /// Retry creating a surface that previously failed.
    func retrySurface(for id: UUID) {
        guard let params = surfaceParams[id],
              let app = TerminalApp.shared.app else { return }
        logger.detailed("Retrying surface creation for \(id)")
        if let view = surfaces.removeValue(forKey: id) {
            view.destroy()
        }
        failedSurfaces.removeValue(forKey: id)
        let view = TerminalView(app: app, workingDirectory: params.workingDirectory, command: params.command, initialInput: params.initialInput, environmentVars: params.environmentVars, waitAfterCommand: params.waitAfterCommand)
        view.workstreamID = id
        surfaces[id] = view
        if view.surface == nil {
            logger.error("Surface retry failed for \(id)")
            failedSurfaces[id] = params.command ?? "(default shell)"
        } else {
            creationTimes[id] = Date()
        }
        objectWillChange.send()
    }

    func webView(for id: UUID) -> WKWebView {
        if let existing = webViews[id] { return existing }
        let view = BrowserWebView()
        webViews[id] = view
        return view
    }

    func quickActionRunner(for workstreamID: UUID) -> QuickActionRunner {
        if let existing = quickActionRunners[workstreamID] {
            return existing
        }
        let runner = QuickActionRunner()
        quickActionRunners[workstreamID] = runner
        return runner
    }

    func removeWebView(for id: UUID) {
        webViews.removeValue(forKey: id)
    }

    func removeSurface(for id: UUID) {
        if let view = surfaces.removeValue(forKey: id) {
            logger.info("Removing surface \(id) — destroying Ghostty surface (kills child process)")
            SurfaceEventLogger.logInfo(workstreamID: id, "surface-removed")
            view.destroy()
        }
        surfaceParams.removeValue(forKey: id)
        failedSurfaces.removeValue(forKey: id)
        creationTimes.removeValue(forKey: id)
    }

    func removeWorkstreamSurfaces(for workstreamID: UUID) {
        tabSnapshots.removeValue(forKey: workstreamID)
        RunStateStore.remove(for: workstreamID)
        if let runner = quickActionRunners.removeValue(forKey: workstreamID) {
            runner.cancel()
        }
        // Remove agent surface
        removeSurface(for: workstreamID)
        // Remove the setup-gate surface (separate salt, not in the loop below).
        removeSurface(for: derivedUUID(from: workstreamID, salt: "setup-gate"))
        // Build a set of all possible derived IDs and remove matches.
        // Generations grow on every stop/start, so cover a wide range.
        var derivedIDs = Set<UUID>()
        for prefix in ["terminal", "browser", "editor", "env-setup", "env-run"] {
            for i in 0 ... 999 {
                derivedIDs.insert(derivedUUID(from: workstreamID, salt: "\(prefix)-\(i)"))
            }
        }
        for id in derivedIDs {
            if surfaces[id] != nil { removeSurface(for: id) }
            if webViews[id] != nil { removeWebView(for: id) }
        }
    }

    private func handleSurfaceClosed(_ closedView: TerminalView) {
        guard let (id, _) = surfaces.first(where: { $0.value === closedView }) else { return }

        // Check if the surface died immediately after creation (launch failure).
        let diedImmediately: Bool
        let age: TimeInterval?
        if let created = creationTimes[id] {
            age = Date().timeIntervalSince(created)
            diedImmediately = age! < Self.healthCheckWindow
            if diedImmediately {
                logger.error("Surface \(id) died after \(String(format: "%.1f", age!))s, treating as launch failure")
                SurfaceEventLogger.logInfo(workstreamID: id, "surface-closed age=\(String(format: "%.1f", age!))s decision=launch-failure")
            }
        } else {
            age = nil
            diedImmediately = false
        }

        if respawnableIDs.contains(id) {
            // If the surface died immediately, show error state instead of respawning in a loop.
            if diedImmediately {
                let command = surfaceParams[id]?.command ?? "(default shell)"
                failedSurfaces[id] = command
                objectWillChange.send()
                return
            }

            guard !respawning.contains(id) else {
                logger.detailed("Skipping concurrent respawn for surface \(id)")
                return
            }
            guard let params = surfaceParams[id],
                  let app = TerminalApp.shared.app else { return }

            respawning.insert(id)
            surfaces.removeValue(forKey: id)
            let newView = TerminalView(app: app, workingDirectory: params.workingDirectory, command: params.command, initialInput: params.initialInput, environmentVars: params.environmentVars, waitAfterCommand: params.waitAfterCommand)
            newView.workstreamID = id
            surfaces[id] = newView
            respawning.remove(id)
            if newView.surface == nil {
                logger.error("Respawn failed for surface \(id)")
                SurfaceEventLogger.logInfo(workstreamID: id, "surface-respawn-failed")
                failedSurfaces[id] = params.command ?? "(default shell)"
            } else {
                creationTimes[id] = Date()
                logger.detailed("Respawned surface \(id)")
                SurfaceEventLogger.logInfo(workstreamID: id, "surface-respawned age=\(age.map { String(format: "%.1f", $0) } ?? "?")s cmd=\(SurfaceEventLogger.preview(params.command))")
            }
            objectWillChange.send()
        } else if diedImmediately {
            // Terminal tab died immediately: show error instead of closing the tab.
            let command = surfaceParams[id]?.command ?? "(default shell)"
            failedSurfaces[id] = command
            objectWillChange.send()
        } else {
            logger.info("Surface \(id) closed by child exit (age=\(age.map { String(format: "%.1f", $0) } ?? "?")s) — removing")
            SurfaceEventLogger.logInfo(workstreamID: id, "surface-closed age=\(age.map { String(format: "%.1f", $0) } ?? "?")s decision=remove-tab")
            removeSurface(for: id)
            NotificationCenter.default.post(name: .terminalTabExited, object: id)
        }
    }

    // MARK: - Text injection

    /// Send text to a terminal surface as if it were typed.
    func sendText(to surfaceID: UUID, text: String) {
        guard let view = surfaces[surfaceID],
              let surface = view.surface else { return }
        text.withCString { ptr in
            ghostty_surface_text(surface, ptr, UInt(text.utf8.count))
        }
    }

    // MARK: - Workspace tab snapshots

    func saveTabSnapshot(for workstreamID: UUID, snapshot: WorkspaceTabSnapshot) {
        tabSnapshots[workstreamID] = snapshot
    }

    func restoreTabSnapshot(for workstreamID: UUID) -> WorkspaceTabSnapshot? {
        guard let snapshot = tabSnapshots[workstreamID] else { return nil }
        let liveSurfaceIDs = Set(surfaces.keys)
        return snapshot.reconciled(liveSurfaceIDs: liveSurfaceIDs)
    }

    func removeTabSnapshot(for workstreamID: UUID) {
        tabSnapshots.removeValue(forKey: workstreamID)
    }
}
