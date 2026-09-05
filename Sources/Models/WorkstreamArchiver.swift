// ABOUTME: Handles removing and purging workstreams from projects.
// ABOUTME: Shared by ContentView and ProjectSidebar to avoid duplicated workstream cleanup logic.

import Foundation

enum WorkstreamArchiver {
    /// Paths currently being archived (background removal in progress).
    @MainActor static var archivingPaths: Set<String> = []

    /// Kill a workstream's dev-server processes from a bulk-delete path
    /// (project delete, clear-all, missing-project sweep) that otherwise only
    /// evicts terminal surfaces. Kills the run tmux session, the recorded
    /// process tree, and the run-state file. Runs blocking syscalls, so call
    /// from a background task.
    nonisolated static func killRunProcesses(workstreamID: UUID, tmuxPath: String?, project: String, workstream: String) {
        if let tmuxPath {
            let runSession = TmuxSession.sessionName(project: project, workstream: workstream, role: "run")
            TmuxSession.killSession(tmuxPath: tmuxPath, sessionName: runSession)
        }
        if let state = RunStateStore.load(for: workstreamID) {
            RunProcessKiller.killTree(root: state.pid)
        }
        RunStateStore.remove(for: workstreamID)
    }

    /// Posted on MainActor when a background worktree removal finishes.
    static let archivingDidComplete = Notification.Name("FFWorktreeArchivingComplete")

    /// Posted on MainActor when a background worktree removal begins.
    static let archivingDidStart = Notification.Name("FFWorktreeArchivingStart")

    /// Removes a workstream from the project without deleting the worktree from disk.
    /// Kills running terminals and tmux sessions but leaves files intact.
    @MainActor
    static func remove(
        _ workstreamID: UUID,
        in project: inout Project,
        surfaceCache: TerminalSurfaceCache,
        tmuxPath: String?
    ) {
        if let ws = project.workstreams.first(where: { $0.id == workstreamID }) {
            let projName = project.name
            let wsName = ws.name
            Task.detached {
                if let tmuxPath {
                    TmuxSession.killWorkstreamSessions(tmuxPath: tmuxPath, project: projName, workstream: wsName)
                }
                // The dev server (and its daemonized children) would otherwise
                // keep holding the port with no workstream left to stop it.
                if let state = RunStateStore.load(for: workstreamID) {
                    RunProcessKiller.killTree(root: state.pid)
                }
                RunStateStore.remove(for: workstreamID)
            }
        }
        surfaceCache.removeWorkstreamSurfaces(for: workstreamID)
        LaunchLogger.removeLog(for: workstreamID)
        SurfaceEventLogger.removeLog(for: workstreamID)
        SetupStateStore.remove(for: workstreamID)
        project.workstreams.removeAll { $0.id == workstreamID }
    }

    /// Check if purging a workstream would lose work. Returns a warning message
    /// describing what would be lost, or nil if it is safe to purge.
    static func purgeWarning(for workstream: Workstream) -> String? {
        guard let path = workstream.worktreePath else { return nil }
        var warnings: [String] = []
        if GitOperations.hasUncommittedChanges(at: path) {
            warnings.append(NSLocalizedString("uncommitted changes", comment: ""))
        }
        if GitOperations.hasUnpushedCommits(at: path) {
            warnings.append(NSLocalizedString("unpushed commits", comment: ""))
        }
        guard !warnings.isEmpty else { return nil }
        let list = warnings.joined(separator: NSLocalizedString(" and ", comment: ""))
        return String(
            format: NSLocalizedString("This workstream has %@ that will be lost.", comment: ""),
            list
        )
    }

    /// Purges a workstream by running teardown, removing the git worktree from disk,
    /// deleting the local branch, updating the default branch to latest,
    /// killing tmux sessions, and evicting terminal surfaces from the cache.
    @MainActor
    static func purge(
        _ workstreamID: UUID,
        in project: inout Project,
        surfaceCache: TerminalSurfaceCache,
        tmuxPath: String?
    ) {
        if let ws = project.workstreams.first(where: { $0.id == workstreamID }) {
            let projectDir = project.directory
            let worktreePath = ws.worktreePath ?? projectDir
            let standardizedPath = URL(fileURLWithPath: worktreePath).standardizedFileURL.path
            let wsName = ws.name
            let projName = project.name
            // Capture the branch name before the worktree is removed
            let branchName = GitOperations.currentBranch(at: worktreePath)
            archivingPaths.insert(standardizedPath)
            NotificationCenter.default.post(name: archivingDidStart, object: nil)
            Telemetry.shared.track("workstream_archived", url: "/workstream/archive", title: "Workstream Archived")
            Task.detached {
                defer {
                    Task { @MainActor in
                        archivingPaths.remove(standardizedPath)
                        NotificationCenter.default.post(name: archivingDidComplete, object: nil)
                    }
                }
                ScriptConfig.runTeardown(in: worktreePath, projectDirectory: projectDir)
                GitOperations.removeWorktree(projectPath: projectDir, worktreePath: worktreePath)
                if let branchName {
                    GitOperations.deleteLocalBranch(at: projectDir, branchName: branchName)
                }
                GitOperations.fetchDefaultBranch(at: projectDir)
                if let tmuxPath {
                    TmuxSession.killWorkstreamSessions(tmuxPath: tmuxPath, project: projName, workstream: wsName)
                }
                if let state = RunStateStore.load(for: workstreamID) {
                    RunProcessKiller.killTree(root: state.pid)
                }
                RunStateStore.remove(for: workstreamID)
                // Clean up the agent launch script for this workstream.
                try? FileManager.default.removeItem(atPath: AppConstants.agentScriptPath(for: workstreamID))
            }
        }
        surfaceCache.removeWorkstreamSurfaces(for: workstreamID)
        LaunchLogger.removeLog(for: workstreamID)
        SurfaceEventLogger.removeLog(for: workstreamID)
        SetupStateStore.remove(for: workstreamID)
        project.workstreams.removeAll { $0.id == workstreamID }
    }

    /// Warning describing what work would be lost if the orphan worktree at `path`
    /// is purged, or nil if it is safe to purge.
    static func orphanPurgeWarning(at path: String) -> String? {
        var warnings: [String] = []
        if GitOperations.hasUncommittedChanges(at: path) {
            warnings.append(NSLocalizedString("uncommitted changes", comment: ""))
        }
        if GitOperations.hasUnpushedCommits(at: path) {
            warnings.append(NSLocalizedString("unpushed commits", comment: ""))
        }
        guard !warnings.isEmpty else { return nil }
        let list = warnings.joined(separator: NSLocalizedString(" and ", comment: ""))
        return String(
            format: NSLocalizedString("This worktree has %@ that will be lost.", comment: ""),
            list
        )
    }

    /// Purges an orphan worktree (one that is not associated with any workstream):
    /// removes the worktree from disk, deletes the local branch, and refreshes
    /// the default branch. Does not touch workstream-only state (terminals,
    /// tmux, agent script) because there is none.
    @MainActor
    static func purgeOrphanWorktree(projectDirectory: String, worktreePath: String) {
        let standardizedPath = URL(fileURLWithPath: worktreePath).standardizedFileURL.path
        let branchName = GitOperations.currentBranch(at: worktreePath)
        archivingPaths.insert(standardizedPath)
        NotificationCenter.default.post(name: archivingDidStart, object: nil)
        Telemetry.shared.track("worktree_purged", url: "/worktree/purge", title: "Orphan Worktree Purged")
        Task.detached {
            defer {
                Task { @MainActor in
                    archivingPaths.remove(standardizedPath)
                    NotificationCenter.default.post(name: archivingDidComplete, object: nil)
                }
            }
            GitOperations.removeWorktree(projectPath: projectDirectory, worktreePath: worktreePath)
            if let branchName {
                GitOperations.deleteLocalBranch(at: projectDirectory, branchName: branchName)
            }
            GitOperations.fetchDefaultBranch(at: projectDirectory)
        }
    }
}
