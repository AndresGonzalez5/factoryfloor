// ABOUTME: SwiftUI sidebar showing projects as a collapsible tree with workstreams.
// ABOUTME: Supports adding projects via picker/drag-drop and workstreams inline.

import AppKit
import OSLog
import SwiftUI
import UniformTypeIdentifiers

private let logger = Logger(subsystem: "factoryfloor", category: "sidebar")

func expandedProjectIDs(afterSelecting selection: SidebarSelection?, current: Set<UUID>, projectIDByWorkstreamID: [UUID: UUID]) -> Set<UUID> {
    guard let selection else { return current }
    var expanded = current
    switch selection {
    case let .project(projectID):
        expanded.insert(projectID)
    case let .workstream(workstreamID):
        if let projectID = projectIDByWorkstreamID[workstreamID] {
            expanded.insert(projectID)
        }
    case .settings, .help:
        break
    }
    return expanded
}

extension Notification.Name {
    static let addProject = Notification.Name("factoryfloor.addProject")
    static let addNew = Notification.Name("factoryfloor.addNew")
}

struct ProjectSidebar: View {
    @Binding var projects: [Project]
    @Binding var spaces: [Space]
    @Binding var currentSpaceID: String
    @Binding var selection: SidebarSelection?
    let onProjectsChanged: () -> Void
    let onSpacesChanged: () -> Void

    @State private var showingAddProjectChoice = false
    @State private var showingNewProjectName = false
    @State private var newProjectName = ""
    @State private var newProjectError = ""
    @State private var isDropTargeted = false
    @State private var projectToDelete: UUID?
    @State private var workstreamToRemove: UUID?
    @State private var workstreamToPurge: UUID?
    @State private var purgeWarningMessage: String?
    @State private var expandedProjects: Set<UUID> = SidebarState.loadExpanded()
    @State private var cachedSortedIDs: [UUID] = []
    @State private var cachedSortedWorkstreamIDs: [UUID: [UUID]] = [:]
    @State private var cachedProjectIndex: [UUID: Int] = [:]
    @State private var cachedWorkstreamIndex: [UUID: (Int, Int)] = [:]
    @State private var showWorktreeError = false
    @State private var showNotGitRepoError = false
    @State private var showingNewWorkstreamName = false
    @State private var newWorkstreamName = ""
    @State private var newWorkstreamError = ""
    @State private var newWorkstreamPlaceholder = ""
    @State private var pendingWorkstreamProjectID: UUID?
    @State private var pendingWorkstreamBypass: Bool?
    @State private var pendingWorkstreamHarness: CodingHarness = .claudeCode
    @AppStorage("factoryfloor.defaultHarness") private var defaultHarnessRaw: String = CodingHarness.claudeCode.rawValue

    private func recomputeSortedIDs() -> [UUID] {
        guard let space = UUID(uuidString: currentSpaceID) else {
            // Safety net only: migration (SpacesBootstrap) guarantees currentSpaceID
            // is a valid space id at launch, so this branch should not be reached.
            return []
        }
        return projects
            .filter { $0.spaceID == space }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map(\.id)
    }

    /// After the active space changes, point the detail pane at the new space's
    /// most recently accessed project, or clear selection when it has none.
    private func selectLastOpenedProjectInCurrentSpace() {
        guard let space = UUID(uuidString: currentSpaceID) else { return }
        // If the current selection already lives in the new space, leave it
        // alone (covers launch alignment, where currentSpaceID is changed to
        // match a restored selection without clobbering it).
        if let selectedProjectID = selectedProjectID(for: selection),
           projects.first(where: { $0.id == selectedProjectID })?.spaceID == space
        {
            return
        }
        let lastOpened = projects
            .filter { $0.spaceID == space }
            .max { $0.lastAccessedAt < $1.lastAccessedAt }
        if let lastOpened {
            selection = .project(lastOpened.id)
        } else {
            selection = nil
        }
    }

    /// The owning project id for a selection, or nil for settings/help.
    private func selectedProjectID(for selection: SidebarSelection?) -> UUID? {
        switch selection {
        case let .project(id):
            return id
        case let .workstream(wsID):
            return projects.first(where: { $0.workstreams.contains(where: { $0.id == wsID }) })?.id
        case .settings, .help, .none:
            return nil
        }
    }

    private func rebuildIndices() {
        cachedProjectIndex = Dictionary(uniqueKeysWithValues: projects.enumerated().map { ($1.id, $0) })
        var wsIndex: [UUID: (Int, Int)] = [:]
        var sortedWS: [UUID: [UUID]] = [:]
        for (pi, project) in projects.enumerated() {
            for (wi, ws) in project.workstreams.enumerated() {
                wsIndex[ws.id] = (pi, wi)
            }
            sortedWS[project.id] = project.workstreams
                .sorted { $0.lastAccessedAt > $1.lastAccessedAt }
                .map(\.id)
        }
        cachedWorkstreamIndex = wsIndex
        cachedSortedWorkstreamIDs = sortedWS
    }

    private func totalWorkstreamCount() -> Int {
        projects.reduce(0) { $0 + $1.workstreams.count }
    }

    private func projectBinding(for id: UUID) -> Binding<Project> {
        Binding(
            get: {
                if let idx = cachedProjectIndex[id], idx < projects.count { return projects[idx] }
                return projects.first(where: { $0.id == id }) ?? Project(name: "", directory: "")
            },
            set: { newValue in
                if let idx = cachedProjectIndex[id], idx < projects.count {
                    projects[idx] = newValue
                }
            }
        )
    }

    private func projectIDByWorkstreamIDSnapshot() -> [UUID: UUID] {
        Dictionary(
            uniqueKeysWithValues: cachedWorkstreamIndex.compactMap { workstreamID, index in
                guard projects.indices.contains(index.0) else { return nil }
                return (workstreamID, projects[index.0].id)
            }
        )
    }

    private func deferSelectionExpansion(_ selected: SidebarSelection, projectIDByWorkstreamID: [UUID: UUID], scrollProxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            guard selection == selected else { return }
            expandedProjects = expandedProjectIDs(
                afterSelecting: selected,
                current: expandedProjects,
                projectIDByWorkstreamID: projectIDByWorkstreamID
            )
            withAnimation {
                scrollProxy.scrollTo(selected, anchor: .center)
            }
        }
    }

    private func projectRows() -> some View {
        ForEach(cachedSortedIDs, id: \.self) { projectID in
            let projectBind = projectBinding(for: projectID)
            let project = projectBind.wrappedValue
            let hasChildren = !project.workstreams.isEmpty

            ProjectHeaderRow(
                project: project,
                isExpanded: expandedProjects.contains(project.id),
                onToggle: hasChildren ? {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if expandedProjects.contains(project.id) {
                            expandedProjects.remove(project.id)
                        } else {
                            expandedProjects.insert(project.id)
                        }
                    }
                } : nil,
                isGitRepo: appEnv.isGitRepo(project.directory),
                githubURL: appEnv.githubURL(for: project.directory),
                onAdd: { logger.warning("[FF] onAdd button tapped for project \(project.name, privacy: .public)"); addWorkstream(for: project.id) },
                onAddWithPermissions: { addWorkstream(for: project.id, bypassPermissions: true) },
                onAddWithoutPermissions: { addWorkstream(for: project.id, bypassPermissions: false) },
                onDelete: { projectToDelete = project.id },
                spaces: spaces,
                onMoveToSpace: { spaceID in moveProject(project.id, toSpace: spaceID) }
            )
            .tag(SidebarSelection.project(project.id))

            if hasChildren && expandedProjects.contains(project.id) {
                let sortedWorkstreamIDs = cachedSortedWorkstreamIDs[project.id] ?? project.workstreams.map(\.id)
                ForEach(sortedWorkstreamIDs, id: \.self) { workstreamID in
                    if let (pIdx, wIdx) = cachedWorkstreamIndex[workstreamID],
                       projects.indices.contains(pIdx),
                       projects[pIdx].workstreams.indices.contains(wIdx)
                    {
                        let workstream = projects[pIdx].workstreams[wIdx]
                        let branch = appEnv.branchName(for: workstream.worktreePath)
                        let pr = branch.flatMap { appEnv.githubPR(for: project.directory, branch: $0) }
                        let wsRuns = agentStateTracker.runs(for: workstream.id)
                        let mainRun = wsRuns.first(where: \.isMain)
                        let subRuns = wsRuns.filter { !$0.isMain }

                        VStack(alignment: .leading, spacing: 2) {
                            WorkstreamRow(
                                name: workstream.label,
                                branchName: branch,
                                worktreePath: workstream.worktreePath,
                                isPathValid: appEnv.isPathValid(workstream.worktreePath),
                                agentState: agentStateTracker.state(for: workstream.id),
                                hasLiveSession: agentStateTracker.hasLiveSession(for: workstream.id),
                                portraitName: workstream.harness.portraitName,
                                mainActivity: mainRun?.activity,
                                // Passed regardless of whether the main run
                                // is still rostered: the tracker keeps the
                                // last reading after a turn ends so the bar
                                // persists (dimmed) at Done/Idle.
                                mainContextUsage: agentStateTracker.mainContextUsage(for: workstream.id),
                                startedAt: mainRun?.startedAt,
                                githubURL: appEnv.githubURL(for: project.directory),
                                taskDescription: appEnv.taskDescription(for: workstream.worktreePath),
                                prTitle: pr?.title,
                                prNumber: pr?.number,
                                prState: pr?.state,
                                harness: workstream.harness,
                                onSwitchHarness: { switchHarness(workstream, to: $0) },
                                onRemove: { workstreamToRemove = workstream.id },
                                onPurge: { confirmPurge(workstream) },
                                onRename: { promptRenameWorkstream(workstream) }
                            )

                            if !subRuns.isEmpty {
                                WorkstreamAgentRosterView(runs: subRuns) {
                                    selectAndFocusAgent(workstreamID: workstream.id)
                                }
                                .padding(.leading, 6)
                            }
                        }
                        .tag(SidebarSelection.workstream(workstream.id))
                        .padding(.leading, 8)
                    }
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 4) {
            if let version = updateChecker.availableVersion {
                UpdateBanner(
                    version: version,
                    pendingReleases: updateChecker.pendingReleases,
                    updater: updater
                )
            }

            // Credit
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Text("by ")
                        .foregroundStyle(.tertiary)
                    Link("David Poblador i Garcia.", destination: URL(string: "https://davidpoblador.com/")!)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 0) {
                    Text("Enhanced by ")
                        .foregroundStyle(.tertiary)
                    Link("Andrés González.", destination: URL(string: "https://github.com/AndresGonzalez5")!)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 0) {
                    Text("Help ")
                        .foregroundStyle(.tertiary)
                    Link("supporting", destination: sponsorURL)
                        .foregroundStyle(.secondary)
                    Text(" the development.")
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.system(size: 10))

            HStack {
                SidebarBottomButton(icon: "plus") {
                    showingAddProjectChoice = true
                }
                .accessibilityLabel("Add project")
                Spacer()
                SidebarBottomButton(icon: "questionmark.circle") {
                    NotificationCenter.default.post(name: .openHelp, object: nil)
                }
                .accessibilityLabel("Help")
                SidebarBottomButton(icon: "gear") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .accessibilityLabel("Settings")
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    var body: some View {
        sidebar
            .alert(
                "Remove Project",
                isPresented: Binding(
                    get: { projectToDelete != nil },
                    set: { if !$0 { projectToDelete = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { projectToDelete = nil }
                Button("Remove", role: .destructive) {
                    if let id = projectToDelete {
                        deleteProject(id: id)
                    }
                }
            } message: {
                if let id = projectToDelete, let project = projects.first(where: { $0.id == id }) {
                    Text(String(format: NSLocalizedString("Remove \"%@\" from the list? Files in %@ will not be deleted.", comment: ""), project.name, project.directory))
                }
            }
            .alert(
                "Remove Workstream",
                isPresented: Binding(
                    get: { workstreamToRemove != nil },
                    set: { if !$0 { workstreamToRemove = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { workstreamToRemove = nil }
                Button("Remove", role: .destructive) {
                    performRemove()
                }
            } message: {
                Text("Ongoing terminals and Coding Agent sessions will be killed. The worktree and its files will remain on disk.")
            }
            .alert(
                "Purge Workstream",
                isPresented: Binding(
                    get: { workstreamToPurge != nil },
                    set: { if !$0 { workstreamToPurge = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { workstreamToPurge = nil }
                Button(purgeWarningMessage != nil ? "Purge Anyway" : "Purge", role: .destructive) {
                    performPurge()
                }
            } message: {
                if let warning = purgeWarningMessage {
                    Text(warning)
                } else {
                    Text("The worktree and its branch will be permanently deleted.")
                }
            }
            .alert(
                "Worktree Creation Failed",
                isPresented: $showWorktreeError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Could not create the git worktree. The branch may already exist, or there may be an ongoing merge or rebase.")
            }
            .alert(
                "Not a Git Repository",
                isPresented: $showNotGitRepoError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Workstreams require a git repository. Initialize one with git init or select a different directory.")
            }
    }

    private var sidebar: some View {
        sidebarList
            .sheet(isPresented: $showingAddProjectChoice) {
                AddProjectChoiceSheet(
                    onNewProject: {
                        showingAddProjectChoice = false
                        newProjectName = ""
                        newProjectError = ""
                        showingNewProjectName = true
                    },
                    onExistingDirectory: {
                        showingAddProjectChoice = false
                        openDirectoryPicker()
                    },
                    onCancel: { showingAddProjectChoice = false }
                )
            }
            .sheet(isPresented: $showingNewProjectName) {
                NewProjectSheet(
                    name: $newProjectName,
                    error: $newProjectError,
                    baseDirectory: baseDirectory,
                    onAdd: { createNewProject() },
                    onCancel: { showingNewProjectName = false }
                )
            }
            .sheet(isPresented: $showingNewWorkstreamName) {
                NewWorkstreamSheet(
                    name: $newWorkstreamName,
                    error: $newWorkstreamError,
                    projectName: pendingWorkstreamProjectID.flatMap { id in projects.first(where: { $0.id == id })?.name } ?? "",
                    placeholder: newWorkstreamPlaceholder,
                    harness: $pendingWorkstreamHarness,
                    onAdd: { createWorkstream() },
                    onCancel: {
                        showingNewWorkstreamName = false
                        pendingWorkstreamProjectID = nil
                        pendingWorkstreamBypass = nil
                        pendingWorkstreamHarness = CodingHarness(rawValue: defaultHarnessRaw) ?? .claudeCode
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .addProject)) { _ in
                showingAddProjectChoice = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .addNew)) { _ in
                if case let .workstream(wsID) = selection,
                   let project = projects.first(where: { $0.workstreams.contains(where: { $0.id == wsID }) })
                {
                    addWorkstream(for: project.id)
                } else if case let .project(pid) = selection {
                    addWorkstream(for: pid)
                } else {
                    showingAddProjectChoice = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openDirectory)) { notification in
                guard let directory = notification.object as? String else { return }
                addProject(name: URL(fileURLWithPath: directory).lastPathComponent, directory: directory)
            }
    }

    private var sidebarList: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                ScrollViewReader { scrollProxy in
                    List(selection: $selection) {
                        projectRows()
                    }
                    .listStyle(.sidebar)
                    .safeAreaInset(edge: .top) {
                        if !spaces.isEmpty {
                            SpaceSwitcher(
                                spaces: $spaces,
                                currentSpaceID: $currentSpaceID,
                                projects: $projects,
                                onChanged: onProjectsChanged,
                                onSpacesChanged: onSpacesChanged
                            )
                        }
                    }
                    .onChange(of: selection) { _, sel in
                        guard let sel else { return }
                        deferSelectionExpansion(sel, projectIDByWorkstreamID: projectIDByWorkstreamIDSnapshot(), scrollProxy: scrollProxy)
                    }
                } // ScrollViewReader

                // Bottom bar (always visible)
                bottomBar
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .terminalActivity)) { notification in
            guard let wsID = notification.object as? UUID else { return }
            guard let (pi, wi) = cachedWorkstreamIndex[wsID] else { return }
            let now = Date()
            projects[pi].lastAccessedAt = now
            projects[pi].workstreams[wi].lastAccessedAt = now
            onProjectsChanged()
            // Workstreams are ordered by recency, so re-sort this project's
            // workstreams on activity. Projects themselves are always A–Z.
            cachedSortedWorkstreamIDs[projects[pi].id] = projects[pi].workstreams
                .sorted { $0.lastAccessedAt > $1.lastAccessedAt }
                .map(\.id)
        }
        .onAppear {
            cachedSortedIDs = recomputeSortedIDs()
            rebuildIndices()
        }
        .onChange(of: currentSpaceID) { _, _ in
            cachedSortedIDs = recomputeSortedIDs()
            // Drive the detail pane to the new space: select its most recently
            // accessed project, or clear the selection if the space is empty.
            // One-directional: switcher → currentSpaceID → selection. Selecting a
            // project must never change currentSpaceID (would loop).
            selectLastOpenedProjectInCurrentSpace()
        }
        .onChange(of: spaces) { _, _ in cachedSortedIDs = recomputeSortedIDs() }
        .onChange(of: expandedProjects) { _, newValue in SidebarState.saveExpanded(newValue) }
        .onChange(of: projects.count) { _, _ in
            cachedSortedIDs = recomputeSortedIDs()
            rebuildIndices()
        }
        .onChange(of: totalWorkstreamCount()) { _, _ in
            rebuildIndices()
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Workstream management

    @AppStorage("factoryfloor.bypassPermissions") private var defaultBypass: Bool = false
    @AppStorage("factoryfloor.symlinkEnv") private var symlinkEnv: Bool = true

    private func addWorkstream(for projectID: UUID, bypassPermissions: Bool? = nil) {
        logger.warning("[FF] addWorkstream called for projectID=\(projectID, privacy: .public)")
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else {
            logger.warning("[FF] addWorkstream: project not found")
            return
        }
        let project = projects[index]
        logger.warning("[FF] addWorkstream: project=\(project.name, privacy: .public) dir=\(project.directory, privacy: .public)")

        guard GitOperations.isGitRepo(at: project.directory) else {
            logger.warning("[FF] addWorkstream: not a git repo")
            showNotGitRepoError = true
            return
        }
        logger.warning("[FF] addWorkstream: is git repo")

        let existingNames = Set(project.workstreams.map(\.name))
        newWorkstreamName = ""
        newWorkstreamError = ""
        newWorkstreamPlaceholder = NameGenerator.generate(avoiding: existingNames)
        pendingWorkstreamProjectID = projectID
        pendingWorkstreamBypass = bypassPermissions
        pendingWorkstreamHarness = CodingHarness(rawValue: defaultHarnessRaw) ?? .claudeCode
        showingNewWorkstreamName = true
    }

    private func createWorkstream() {
        guard let projectID = pendingWorkstreamProjectID else { return }
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else {
            showingNewWorkstreamName = false
            return
        }
        let project = projects[index]
        let existingNames = Set(project.workstreams.map(\.name))

        let typedName = newWorkstreamName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typedName.isEmpty {
            guard GitOperations.isValidBranchName(typedName) else {
                newWorkstreamError = NSLocalizedString(
                    "That name isn't valid for a git branch.",
                    comment: "Error when the workstream name is not a valid git branch name"
                )
                return
            }
            guard !existingNames.contains(typedName) else {
                newWorkstreamError = NSLocalizedString(
                    "A workstream with this name already exists.",
                    comment: "Error when the workstream name collides with an existing workstream"
                )
                return
            }
        }

        let bypass = pendingWorkstreamBypass ?? defaultBypass
        let name = typedName.isEmpty ? NameGenerator.generate(avoiding: existingNames) : typedName
        logger.warning("[FF] createWorkstream: \(typedName.isEmpty ? "generated" : "user") name=\(name, privacy: .public)")

        showingNewWorkstreamName = false
        pendingWorkstreamProjectID = nil
        pendingWorkstreamBypass = nil
        let workstream = Workstream(name: name, worktreePath: nil, bypassPermissions: bypass, harness: pendingWorkstreamHarness)
        expandedProjects.insert(projectID)
        NotificationCenter.default.post(
            name: .workstreamCreated,
            object: nil,
            userInfo: ["projectID": projectID, "workstream": workstream]
        )
        rebuildIndices()
        logger.warning("[FF] addWorkstream: posted notification (optimistic), starting background worktree creation")

        let projectPath = project.directory
        let projectName = project.name
        let symlink = symlinkEnv
        let workstreamID = workstream.id

        DispatchQueue.global(qos: .userInitiated).async {
            let worktreePath = GitOperations.createWorktree(
                projectPath: projectPath,
                projectName: projectName,
                workstreamName: name,
                symlinkEnv: symlink
            )
            DispatchQueue.main.async {
                if let worktreePath {
                    logger.warning("[FF] addWorkstream: worktree created at \(worktreePath, privacy: .public)")
                    NotificationCenter.default.post(
                        name: .workstreamWorktreeReady,
                        object: nil,
                        userInfo: ["workstreamID": workstreamID, "worktreePath": worktreePath]
                    )
                } else {
                    logger.warning("[FF] addWorkstream: createWorktree FAILED, rolling back")
                    NotificationCenter.default.post(
                        name: .workstreamCreationFailed,
                        object: nil,
                        userInfo: ["projectID": projectID, "workstreamID": workstreamID]
                    )
                    showWorktreeError = true
                }
            }
        }
    }

    @EnvironmentObject private var surfaceCache: TerminalSurfaceCache
    @EnvironmentObject private var appEnv: AppEnvironment
    @EnvironmentObject private var updateChecker: UpdateChecker
    @EnvironmentObject private var updater: Updater
    @EnvironmentObject private var agentStateTracker: WorkstreamAgentStateTracker

    private func confirmPurge(_ workstream: Workstream) {
        purgeWarningMessage = WorkstreamArchiver.purgeWarning(for: workstream)
        workstreamToPurge = workstream.id
    }

    /// Selects a workstream and focuses its Coding Agent tab. When the
    /// workstream isn't already selected, focus is deferred briefly so the
    /// detail pane can swap to the new container first.
    private func selectAndFocusAgent(workstreamID: UUID) {
        if case let .workstream(selected) = selection, selected == workstreamID {
            NotificationCenter.default.post(name: .focusAgent, object: nil)
            return
        }
        selection = SidebarSelection.workstream(workstreamID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NotificationCenter.default.post(name: .focusAgent, object: nil)
        }
    }

    private func promptRenameWorkstream(_ workstream: Workstream) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Rename workstream", comment: "Title of the rename workstream dialog")
        alert.informativeText = NSLocalizedString(
            "Leave blank to use the branch name.",
            comment: "Helper text in the rename workstream dialog"
        )
        alert.addButton(withTitle: NSLocalizedString("Rename", comment: "Confirm button in the rename workstream dialog"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel button"))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        textField.stringValue = workstream.label
        textField.placeholderString = workstream.name
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let trimmed = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pi = projects.firstIndex(where: { $0.id == workstreamProjectID(for: workstream.id) }),
              let wi = projects[pi].workstreams.firstIndex(where: { $0.id == workstream.id }) else { return }
        if trimmed.isEmpty || trimmed == projects[pi].workstreams[wi].name {
            projects[pi].workstreams[wi].displayName = nil
        } else {
            projects[pi].workstreams[wi].displayName = trimmed
        }
        onProjectsChanged()
    }

    private func workstreamProjectID(for workstreamID: UUID) -> UUID? {
        for project in projects where project.workstreams.contains(where: { $0.id == workstreamID }) {
            return project.id
        }
        return nil
    }

    /// Flips a workstream's coding agent. Tears down the current agent surface
    /// (and its tmux session) so the next spawn relaunches under the new harness.
    private func switchHarness(_ workstream: Workstream, to harness: CodingHarness) {
        guard workstream.harness != harness,
              let pi = projects.firstIndex(where: { $0.id == workstreamProjectID(for: workstream.id) }),
              let wi = projects[pi].workstreams.firstIndex(where: { $0.id == workstream.id })
        else { return }

        logger.warning("[FF] switchHarness \(workstream.harness.rawValue, privacy: .public) -> \(harness.rawValue, privacy: .public) for \(workstream.name, privacy: .public)")

        surfaceCache.removeSurface(for: workstream.id)
        let tmuxSession = TmuxSession.sessionName(project: projects[pi].name, workstream: workstream.name, role: "agent")
        if let tmuxPath = appEnv.toolStatus.tmux.path {
            TmuxSession.killSession(tmuxPath: tmuxPath, sessionName: tmuxSession)
        }
        agentStateTracker.clear(workstreamID: workstream.id)

        projects[pi].workstreams[wi].harness = harness
        onProjectsChanged()
    }

    private func performRemove() {
        guard let wsID = workstreamToRemove,
              let pi = projects.firstIndex(where: { $0.workstreams.contains(where: { $0.id == wsID }) }) else { return }
        let projectID = projects[pi].id
        WorkstreamArchiver.remove(wsID, in: &projects[pi], surfaceCache: surfaceCache, tmuxPath: appEnv.toolStatus.tmux.path)
        agentStateTracker.clear(workstreamID: wsID)
        rebuildIndices()
        if case let .workstream(id) = selection, id == wsID {
            selection = projects[pi].workstreams.first.map { .workstream($0.id) } ?? .project(projectID)
        }
        onProjectsChanged()
        workstreamToRemove = nil
    }

    private func performPurge() {
        guard let wsID = workstreamToPurge,
              let pi = projects.firstIndex(where: { $0.workstreams.contains(where: { $0.id == wsID }) }) else { return }
        let projectID = projects[pi].id
        WorkstreamArchiver.purge(wsID, in: &projects[pi], surfaceCache: surfaceCache, tmuxPath: appEnv.toolStatus.tmux.path)
        agentStateTracker.clear(workstreamID: wsID)
        rebuildIndices()
        if case let .workstream(id) = selection, id == wsID {
            selection = projects[pi].workstreams.first.map { .workstream($0.id) } ?? .project(projectID)
        }
        onProjectsChanged()
        workstreamToPurge = nil
    }

    // MARK: - Project management

    private func moveProject(_ projectID: UUID, toSpace spaceID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        guard projects[index].spaceID != spaceID else { return }
        projects[index].spaceID = spaceID
        onProjectsChanged()
        cachedSortedIDs = recomputeSortedIDs()
    }

    private func deleteProject(id: UUID) {
        if let project = projects.first(where: { $0.id == id }) {
            for ws in project.workstreams {
                surfaceCache.removeWorkstreamSurfaces(for: ws.id)
                agentStateTracker.clear(workstreamID: ws.id)
            }
        }
        projects.removeAll { $0.id == id }
        if case let .project(pid) = selection, pid == id { selection = nil }
        if case let .workstream(wsID) = selection,
           !projects.contains(where: { $0.workstreams.contains(where: { $0.id == wsID }) })
        {
            selection = nil
        }
        projectToDelete = nil
        onProjectsChanged()
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                guard let data = data as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.hasDirectoryPath || FileManager.default.isDirectory(at: url) else { return }

                DispatchQueue.main.async {
                    addProject(name: url.lastPathComponent, directory: url.path)
                }
            }
        }
        return true
    }

    private var sponsorURL: URL {
        let lang = Locale.current.language.languageCode?.identifier ?? "en"
        let path = lang == "en" ? "/sponsor" : "/\(lang)/sponsor"
        return URL(string: "https://factory-floor.com\(path)")!
    }

    @AppStorage("factoryfloor.baseDirectory") private var baseDirectory: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""

    private func openDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: baseDirectory)
        panel.message = NSLocalizedString("Choose a project directory", comment: "")
        panel.prompt = NSLocalizedString("Select", comment: "")
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            self.addProject(name: url.lastPathComponent, directory: url.path)
        }
    }

    private func createNewProject() {
        let name = newProjectName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let dirURL = URL(fileURLWithPath: baseDirectory).appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: dirURL.path) {
            newProjectError = NSLocalizedString("A file or directory with this name already exists.", comment: "")
            return
        }

        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        } catch {
            newProjectError = error.localizedDescription
            return
        }

        // Initialize git repo in the new directory
        _ = GitOperations.initRepo(at: dirURL.path)

        showingNewProjectName = false
        addProject(name: name, directory: dirURL.path)
    }

    private func addProject(name: String, directory: String) {
        // Resolve worktree branches to their main repository
        let resolvedDirectory: String
        let resolvedName: String
        if let mainRepoPath = GitOperations.mainRepositoryPath(for: directory) {
            resolvedDirectory = mainRepoPath
            resolvedName = URL(fileURLWithPath: mainRepoPath).lastPathComponent
        } else {
            resolvedDirectory = directory
            resolvedName = name
        }

        if let existing = projects.first(where: { $0.directory == resolvedDirectory }) {
            selection = .project(existing.id)
            return
        }

        let projectName = resolvedName.isEmpty ? URL(fileURLWithPath: resolvedDirectory).lastPathComponent : resolvedName
        let project = Project(name: projectName, directory: resolvedDirectory)
        NotificationCenter.default.post(
            name: .projectCreated,
            object: nil,
            userInfo: ["project": project]
        )
    }
}

extension FileManager {
    func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}

func copyTextToPasteboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}

/// Opens a directory in the user's configured terminal, falling back to Apple Terminal.
func openDirectoryInTerminal(_ directory: String) {
    let terminalBundleID = UserDefaults.standard.string(forKey: "factoryfloor.defaultTerminal") ?? ""
    let appURL: URL?
    if !terminalBundleID.isEmpty {
        appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminalBundleID)
    } else {
        appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
    }
    guard let appURL else { return }
    let config = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.open([URL(fileURLWithPath: directory)], withApplicationAt: appURL, configuration: config)
}

private struct ProjectHeaderRow: View {
    let project: Project
    let isExpanded: Bool
    let onToggle: (() -> Void)?
    let isGitRepo: Bool
    var githubURL: URL?
    let onAdd: () -> Void
    let onAddWithPermissions: () -> Void
    let onAddWithoutPermissions: () -> Void
    let onDelete: () -> Void
    let spaces: [Space]
    let onMoveToSpace: (UUID) -> Void

    @State private var isHovering = false
    @State private var isChevronHovering = false

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Group {
                if onToggle != nil {
                    Button(action: { onToggle?() }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isChevronHovering ? .primary : .secondary)
                            .frame(width: 22, height: 22)
                            .background(isChevronHovering ? Color.primary.opacity(0.1) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.borderless)
                    .onHover { isChevronHovering = $0 }
                    .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
                    .accessibilityValue(isExpanded ? "expanded" : "collapsed")
                } else {
                    Color.clear
                }
            }
            .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 13, weight: .medium))

                    if !project.workstreams.isEmpty {
                        Text("\(project.workstreams.count)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.quaternary)
                            .clipShape(Capsule())
                            .accessibilityLabel("\(project.workstreams.count) workstreams")
                    }
                }

                Text(project.directory.abbreviatedPath)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                if isGitRepo {
                    SidebarIconButton(icon: "plus", action: onAdd)
                        .accessibilityLabel("Add workstream to \(project.name)")
                        .contextMenu {
                            Button(action: onAddWithPermissions) {
                                Label("New workstream (full permissions)", systemImage: "lock.open")
                            }
                            Button(action: onAddWithoutPermissions) {
                                Label("New workstream (with prompts)", systemImage: "lock.shield")
                            }
                        }
                }
                SidebarIconButton(icon: "trash", action: onDelete)
                    .accessibilityLabel("Remove project")
            }
            .opacity(isHovering ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 1)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu {
            Button {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.directory)
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }
            Button {
                openDirectoryInTerminal(project.directory)
            } label: {
                Label("Open in External Terminal", systemImage: "terminal")
            }
            if let githubURL {
                Button {
                    NSWorkspace.shared.open(githubURL)
                } label: {
                    Label("Open on GitHub", image: "github")
                }
            }
            if !spaces.isEmpty {
                Divider()
                Menu("Move to Space") {
                    ForEach(spaces) { space in
                        Button {
                            onMoveToSpace(space.id)
                        } label: {
                            if project.spaceID == space.id {
                                Label("\(space.emoji) \(space.name)", systemImage: "checkmark")
                            } else {
                                Text("\(space.emoji) \(space.name)")
                            }
                        }
                    }
                }
            }
            Divider()
            Button {
                copyTextToPasteboard(project.directory)
            } label: {
                Label("Copy project path", systemImage: "doc.on.doc")
            }
        }
    }
}

private struct WorkstreamRow: View {
    let name: String
    var branchName: String?
    var worktreePath: String?
    let isPathValid: Bool
    var agentState: WorkstreamAgentStateTracker.AgentRunState = .idle
    var hasLiveSession: Bool = false
    var portraitName: String = "Claude"
    var mainActivity: String?
    var mainContextUsage: WorkstreamAgentStateTracker.ContextUsage?
    /// When this workstream's main run was first seen this launch; drives
    /// the status line's ticking elapsed time.
    var startedAt: Date?
    var githubURL: URL?
    var taskDescription: String?
    var prTitle: String?
    var prNumber: Int?
    var prState: String?
    var harness: CodingHarness = .claudeCode
    var onSwitchHarness: (CodingHarness) -> Void = { _ in }
    let onRemove: () -> Void
    let onPurge: () -> Void
    let onRename: () -> Void

    @State private var isHovering = false

    private var headline: String {
        if let prTitle { return prTitle }
        if let taskDescription { return taskDescription }
        return name
    }

    private var hasRichHeadline: Bool {
        prTitle != nil || taskDescription != nil
    }

    private var subtitle: String? {
        guard isPathValid else { return nil }
        if hasRichHeadline {
            return branchName ?? name
        }
        if let branchName, branchName != name {
            return branchName
        }
        return nil
    }

    /// The main session's context bar stays visible once usage is known so a
    /// finished turn's consumption remains readable; it dims while the agent
    /// isn't actively spending context.
    private var showsMainContextMeter: Bool {
        mainContextUsage != nil && isPathValid && hasLiveSession
    }

    /// True while the agent is actively spending context this turn.
    private var isAgentActive: Bool {
        switch agentState {
        case .working, .stalled: true
        case .idle, .needsAttention: false
        }
    }

    /// Dot/word color mirroring the portrait ring; nil when dormant.
    private var statusColor: Color? {
        MainAgentPortrait.ringColor(for: agentState, hasLiveSession: hasLiveSession)
    }

    private var statusText: LocalizedStringKey? {
        switch agentState {
        case .working: "Working"
        case .stalled: "Stalled"
        case .needsAttention(.permission): "Waiting for approval"
        case .needsAttention(.justFinished): "Done"
        case .idle where hasLiveSession: "Idle"
        case .idle: nil
        }
    }

    /// "● Working · Editing AuthView.swift · 4m" — colored dot + localized
    /// status word, current tool activity while active, and time since the
    /// run started. Rendered only for workstreams with a live session.
    private func statusMeta(word: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 0) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .padding(.trailing, 4)

            Text(word)
                .foregroundStyle(color)

            if isAgentActive, let activity = mainActivity {
                metaSeparator
                Text(activity)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            if let startedAt {
                metaSeparator
                ElapsedLabel(startedAt: startedAt, fontSize: 9)
            }
        }
        .font(.system(size: 9, design: .monospaced))
        .lineLimit(1)
    }

    private var metaSeparator: some View {
        Text("·")
            .foregroundStyle(.quaternary)
            .padding(.horizontal, 3)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            MainAgentPortrait(
                state: agentState,
                isPathValid: isPathValid,
                hasLiveSession: hasLiveSession,
                portraitName: portraitName
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(headline)
                    .font(.system(size: 11))
                    .strikethrough(!isPathValid)
                    .foregroundStyle(isPathValid ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                    .lineLimit(2)

                if let subtitle {
                    HStack(spacing: 3) {
                        if prState == "MERGED" {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 8))
                                .foregroundStyle(.purple)
                        }
                        Text(subtitle)
                            .lineLimit(1)
                    }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(prState == "MERGED" ? AnyShapeStyle(.purple) : AnyShapeStyle(.tertiary))
                }

                if let statusText, let statusColor {
                    statusMeta(word: statusText, color: statusColor)
                }

                if showsMainContextMeter, let usage = mainContextUsage {
                    ContextMeter(usage: usage, style: .bar)
                        .opacity(isAgentActive ? 1 : 0.45)
                        .animation(.easeInOut(duration: 0.2), value: isAgentActive)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .overlay(alignment: .trailing) {
            SidebarIconButton(icon: "xmark", action: onRemove)
                .accessibilityLabel("Remove workstream")
                .opacity(isHovering ? 1 : 0)
        }
        .contentShape(Rectangle())
        .help(taskDescription ?? "")
        .onHover { isHovering = $0 }
        .contextMenu {
            if let worktreePath {
                Button {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: worktreePath)
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
                Button {
                    openDirectoryInTerminal(worktreePath)
                } label: {
                    Label("Open in External Terminal", systemImage: "terminal")
                }
            }
            if let githubURL {
                Button {
                    NSWorkspace.shared.open(githubURL)
                } label: {
                    Label("Open on GitHub", image: "github")
                }
            }
            if worktreePath != nil || githubURL != nil {
                Divider()
            }
            if let branchName {
                Button {
                    copyTextToPasteboard(branchName)
                } label: {
                    Label("Copy branch name", systemImage: "arrow.triangle.branch")
                }
            }
            if let worktreePath {
                Button {
                    copyTextToPasteboard(worktreePath)
                } label: {
                    Label("Copy worktree path", systemImage: "doc.on.doc")
                }
            }
            Divider()
            Menu {
                ForEach(CodingHarness.allCases, id: \.self) { candidate in
                    Button {
                        onSwitchHarness(candidate)
                    } label: {
                        if candidate == harness {
                            Label(candidate.displayName, systemImage: "checkmark")
                        } else {
                            Label {
                                Text(candidate.displayName)
                            } icon: {
                                Image(nsImage: candidate.brandDotImage)
                            }
                        }
                    }
                }
            } label: {
                Label {
                    Text("Coding Agent")
                } icon: {
                    if let img = AgentSpriteStore.shared.avatar(name: harness.portraitName, palette: 0, variant: 0) {
                        Image(nsImage: img)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 16, height: 16)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    } else {
                        Image(nsImage: harness.brandDotImage)
                    }
                }
            }
            Button(action: onRename) {
                Label("Rename…", systemImage: "pencil")
            }
            Button(action: onRemove) {
                Label("Remove", systemImage: "xmark")
            }
            Button(role: .destructive, action: onPurge) {
                Label("Purge", systemImage: "trash")
            }
        }
    }
}

private struct SidebarIconButton: View {
    let icon: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(isHovering ? .primary : .secondary)
                .frame(width: 22, height: 22)
                .background(isHovering ? Color.primary.opacity(0.1) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }
    }
}

private struct SidebarBottomButton: View {
    let icon: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isHovering ? .primary : .secondary)
                .frame(width: 32, height: 32)
                .background(isHovering ? Color.primary.opacity(0.08) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.borderless)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private struct AddProjectChoiceSheet: View {
    let onNewProject: () -> Void
    let onExistingDirectory: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Project")
                .font(.headline)

            VStack(spacing: 12) {
                Button(action: onNewProject) {
                    HStack {
                        Image(systemName: "plus.rectangle.on.folder")
                            .font(.system(size: 20))
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("New Project")
                                .font(.system(.body, weight: .medium))
                            Text("Create a new directory in the base directory")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.defaultAction)

                Button(action: onExistingDirectory) {
                    HStack {
                        Image(systemName: "folder")
                            .font(.system(size: 20))
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Existing Directory")
                                .font(.system(.body, weight: .medium))
                            Text("Select an existing directory from disk")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.borderless)
            }

            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
        }
        .padding(20)
        .frame(width: 380)
    }
}

private struct NewWorkstreamSheet: View {
    @Binding var name: String
    @Binding var error: String
    let projectName: String
    let placeholder: String
    @Binding var harness: CodingHarness
    let onAdd: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool
    @State private var tabMonitor: Any?

    var body: some View {
        VStack(spacing: 18) {
            Text("New Workstream")
                .font(.headline)

            Divider()
                .opacity(0.35)

            VStack(alignment: .leading, spacing: 4) {
                Text("Project")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Text(projectName)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("Workstream name")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .help("Leave blank for a random name. This becomes the branch and worktree name.")
                        .accessibilityLabel(Text("Leave blank for a random name. This becomes the branch and worktree name."))
                }
                TextField("", text: $name, prompt: Text(placeholder).font(.system(.body, design: .monospaced)).foregroundStyle(.tertiary))
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit { onAdd() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text("Coding Agent")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                HarnessPicker(selection: $harness)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create", action: onAdd)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            isFocused = true
            installTabMonitor()
        }
        .onDisappear { removeTabMonitor() }
    }

    private func installTabMonitor() {
        guard tabMonitor == nil else { return }
        tabMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == 48,
                  !event.modifierFlags.contains(.command),
                  !event.modifierFlags.contains(.control),
                  !event.modifierFlags.contains(.option) else {
                return event
            }
            let forward = !event.modifierFlags.contains(.shift)
            let all = CodingHarness.allCases
            if let idx = all.firstIndex(of: self.harness) {
                let next = (idx + (forward ? 1 : -1) + all.count) % all.count
                self.harness = all[next]
                self.isFocused = true
            }
            return nil
        }
    }

    private func removeTabMonitor() {
        if let monitor = tabMonitor {
            NSEvent.removeMonitor(monitor)
            tabMonitor = nil
        }
    }
}

private struct NewProjectSheet: View {
    @Binding var name: String
    @Binding var error: String
    let baseDirectory: String
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("New Project")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Base directory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(baseDirectory.abbreviatedPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Text("(change in Settings)")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Project Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { if !name.trimmingCharacters(in: .whitespaces).isEmpty { onAdd() } }

            if !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create", action: onAdd)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
