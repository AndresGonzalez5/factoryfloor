// ABOUTME: GitHub-style Changes view showing stacked inline diffs for all of a workstream's edits.
// ABOUTME: Renders git-derived diffs in Monaco diff editors inside one WKWebView via MonacoDiffBridge.

import SwiftUI

/// The diff scope shown by the Changes tab.
enum ChangesMode: String, CaseIterable {
    /// Everything that differs between merge-base(defaultBranch, HEAD) and the worktree.
    case branch
    /// Working-tree changes vs HEAD (plus untracked files).
    case uncommitted

    var label: String {
        switch self {
        case .branch: return NSLocalizedString("Branch", comment: "Changes tab: branch diff mode")
        case .uncommitted: return NSLocalizedString("Uncommitted", comment: "Changes tab: uncommitted diff mode")
        }
    }
}

/// The Changes tab. Lists every changed file as a stacked Monaco inline diff,
/// computed live from git. Supports Branch/Uncommitted modes, fingerprint-gated
/// refresh, and a per-file binary/large-file guard with click-to-load.
struct ChangesView: View {
    let workingDirectory: String
    let projectDirectory: String
    let bridge: MonacoDiffBridge

    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var fileCount = 0
    @State private var mode: ChangesMode = .branch

    /// The current changed-file set, surfaced for the sidebar tree. Captured
    /// from the same load that builds the diff payload (no extra git read).
    @State private var diffFiles: [DiffFile] = []
    /// The leaf currently selected in the sidebar (its full relative path).
    @State private var selectedFilePath: String?

    var body: some View {
        VStack(spacing: 0) {
            changesToolbar
            if fileCount == 0 {
                // Empty state: no sidebar skeleton — just the "No changes" webview.
                ZStack {
                    MonacoDiffView(bridge: bridge)
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.background)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    ChangesFileTreeSidebar(
                        files: diffFiles,
                        selectedFilePath: $selectedFilePath,
                        onSelect: { path in
                            bridge.scrollToFile(path)
                        }
                    )
                    .frame(minWidth: 180, idealWidth: 240, maxWidth: 480)

                    ZStack {
                        MonacoDiffView(bridge: bridge)
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.background)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Make sure the bridge can resolve content for click-to-load before
            // any deferred-file click can happen.
            configureLoadHandler()

            if bridge.hasContent && bridge.lastMode == mode.rawValue {
                // Cached content exists for this mode — show it, refresh in background.
                isLoading = false
                fileCount = bridge.lastFileCount
                diffFiles = bridge.lastDiffFiles
                backgroundRefreshIfNeeded()
            } else {
                fullLoad()
            }
        }
        .onChange(of: mode) {
            // Mode changed — always do a full load.
            bridge.lastFingerprint = nil
            configureLoadHandler()
            fullLoad()
        }
    }

    // MARK: - Toolbar

    private var changesToolbar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $mode) {
                ForEach(ChangesMode.allCases, id: \.self) { m in
                    Text(m.label).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: 170)
            .opacity(0.85)
            .labelsHidden()

            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
                Text("Refreshing…")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            } else if fileCount == 0 {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
                Text("No changes")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text(String(
                    format: NSLocalizedString("%d file(s) changed", comment: "Changes tab: changed-file count"),
                    fileCount
                ))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help(Text("Refresh changes"))
            .accessibilityLabel(Text("Refresh changes"))
            .disabled(isLoading || isRefreshing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Refresh

    /// Manual refresh: invalidate the cached fingerprint and force a full reload.
    private func refresh() {
        bridge.lastFingerprint = nil
        configureLoadHandler()
        fullLoad()
    }

    // MARK: - Full load (first visit, mode switch, or explicit refresh)

    private func fullLoad() {
        isLoading = true
        let workDir = workingDirectory
        let projDir = projectDirectory
        let currentMode = mode

        DispatchQueue.global(qos: .userInitiated).async {
            let fingerprint = GitOperations.diffFingerprint(
                worktreePath: workDir,
                projectPath: projDir,
                mode: currentMode.rawValue
            )
            let contents = Self.buildContents(
                workDir: workDir,
                projDir: projDir,
                mode: currentMode
            )

            DispatchQueue.main.async {
                diffFiles = contents.files
                selectedFilePath = nil
                fileCount = contents.payload.count
                bridge.lastFileCount = contents.payload.count
                bridge.lastDiffFiles = contents.files
                bridge.lastFingerprint = fingerprint
                bridge.lastMode = currentMode.rawValue
                bridge.onContentReady = {
                    isLoading = false
                }
                bridge.setFiles(contents.payload)
            }
        }
    }

    // MARK: - Background refresh (revisit with cached content already shown)

    private func backgroundRefreshIfNeeded() {
        let workDir = workingDirectory
        let projDir = projectDirectory
        let currentMode = mode
        let cachedFingerprint = bridge.lastFingerprint

        DispatchQueue.global(qos: .userInitiated).async {
            let fingerprint = GitOperations.diffFingerprint(
                worktreePath: workDir,
                projectPath: projDir,
                mode: currentMode.rawValue
            )

            // Nothing changed — keep the cached content, no reload, no flicker.
            if fingerprint == cachedFingerprint {
                return
            }

            let contents = Self.buildContents(
                workDir: workDir,
                projDir: projDir,
                mode: currentMode
            )

            DispatchQueue.main.async {
                diffFiles = contents.files
                selectedFilePath = nil
                fileCount = contents.payload.count
                bridge.lastFileCount = contents.payload.count
                bridge.lastDiffFiles = contents.files
                bridge.lastFingerprint = fingerprint
                bridge.lastMode = currentMode.rawValue
                isRefreshing = true
                bridge.onContentReady = {
                    isRefreshing = false
                }
                bridge.setFiles(contents.payload)
            }
        }
    }

    // MARK: - Click-to-load wiring

    /// Give the bridge enough context (workDir + mode) to resolve a single
    /// deferred file's content when its placeholder is clicked. The git base ref
    /// is resolved lazily inside the resolver, which the bridge runs off the main
    /// thread, so no git command blocks the main thread here.
    private func configureLoadHandler() {
        let workDir = workingDirectory
        let projDir = projectDirectory
        let currentMode = mode
        bridge.onLoadFile = { filePath in
            // Runs off the main thread; resolves base ref + content for one file.
            let baseRef = Self.baseRef(workDir: workDir, projDir: projDir, mode: currentMode)
            let (original, modified) = Self.fileTexts(
                workDir: workDir,
                baseRef: baseRef,
                filePath: filePath
            )
            let languageId = MonacoLanguage.id(for: (filePath as NSString).lastPathComponent)
            return (original, modified, languageId)
        }
    }

    // MARK: - Large-file guard thresholds

    /// A file with more than this many changed lines is deferred (Hardening 3).
    static let largeFileLineThreshold = 1500
    /// A file larger than this many bytes on disk is deferred (Hardening 3).
    static let largeFileByteThreshold = 500 * 1024

    /// How a file's diff body should be produced.
    enum PayloadClass: Equatable {
        /// Binary — never rendered as a UTF-8 diff (Hardening 2).
        case binary
        /// Oversize — collapsed to a click-to-load placeholder (Hardening 3).
        case deferred
        /// Rendered immediately as a Monaco inline diff.
        case normal
    }

    /// Pure classification of a file's diff body. Decides BEFORE any content is
    /// read so git-show / disk reads are skipped for binary and deferred files.
    nonisolated static func classify(isBinary: Bool, changedLines: Int, sizeHint: Int) -> PayloadClass {
        if isBinary { return .binary }
        if changedLines > largeFileLineThreshold || sizeHint > largeFileByteThreshold {
            return .deferred
        }
        return .normal
    }

    // MARK: - Payload builder

    /// Build the `setFiles` payload for ALL changed files in the given mode.
    /// Runs on a background queue (nonisolated, captures no @State). Decides each
    /// file's class (binary / deferred / normal) before reading content so that
    /// git show and disk reads are skipped for binary and deferred files.
    nonisolated static func buildPayload(
        workDir: String,
        projDir: String,
        mode: ChangesMode
    ) -> [[String: Any]] {
        buildContents(workDir: workDir, projDir: projDir, mode: mode).payload
    }

    /// Build both the JS `setFiles` payload AND the structured, sorted list of
    /// changed files in one pass. The sidebar tree is built from `files` while
    /// the diff webview renders `payload`; sharing one git read keeps the two in
    /// sync and avoids re-running git for the sidebar.
    nonisolated static func buildContents(
        workDir: String,
        projDir: String,
        mode: ChangesMode
    ) -> (payload: [[String: Any]], files: [DiffFile]) {
        let diffFiles: [DiffFile]
        switch mode {
        case .branch:
            diffFiles = GitOperations.branchDiffFiles(worktreePath: workDir, projectPath: projDir)
        case .uncommitted:
            diffFiles = GitOperations.uncommittedDiffFiles(at: workDir)
        }

        let baseRef = baseRef(workDir: workDir, projDir: projDir, mode: mode)

        // Alphabetical by path — there is no review-driven ordering.
        let sorted = diffFiles.sorted {
            $0.relativePath.localizedStandardCompare($1.relativePath) == .orderedAscending
        }

        var payload: [[String: Any]] = []
        payload.reserveCapacity(sorted.count)

        for file in sorted {
            var entry: [String: Any] = [
                "filePath": file.relativePath,
                "status": file.status.rawValue,
                "languageId": MonacoLanguage.id(for: (file.relativePath as NSString).lastPathComponent),
                "changedLines": file.changedLines,
            ]

            switch classify(isBinary: file.isBinary, changedLines: file.changedLines, sizeHint: file.sizeHint) {
            case .binary:
                // No content read; diff.js renders a "Binary file (not shown)" badge.
                entry["binary"] = true
                entry["originalText"] = ""
                entry["modifiedText"] = ""
            case .deferred:
                // No content read yet; diff.js renders a click-to-load placeholder.
                entry["deferred"] = true
                entry["originalText"] = ""
                entry["modifiedText"] = ""
            case .normal:
                let (original, modified) = fileTexts(
                    workDir: workDir,
                    baseRef: baseRef,
                    filePath: file.relativePath,
                    status: file.status
                )
                entry["originalText"] = original
                entry["modifiedText"] = modified
            }

            payload.append(entry)
        }

        return (payload, sorted)
    }

    // MARK: - Content resolution helpers

    /// The diff base ref for a mode: merge-base for branch (falling back to HEAD),
    /// HEAD for uncommitted.
    nonisolated static func baseRef(workDir: String, projDir: String, mode: ChangesMode) -> String {
        switch mode {
        case .branch:
            return GitOperations.mergeBase(worktreePath: workDir, projectPath: projDir) ?? "HEAD"
        case .uncommitted:
            return "HEAD"
        }
    }

    /// Read (original, modified) text for a file. The original side comes from the
    /// base ref via `git show`; the modified side from disk. `status` lets us skip
    /// reads that would always be empty (added has no base, deleted has no disk).
    nonisolated static func fileTexts(
        workDir: String,
        baseRef: String,
        filePath: String,
        status: DiffFile.Status? = nil
    ) -> (original: String, modified: String) {
        let original: String
        if status == .added {
            original = ""
        } else {
            original = GitOperations.fileContent(at: workDir, ref: baseRef, filePath: filePath) ?? ""
        }

        let modified: String
        if status == .deleted {
            modified = ""
        } else {
            let fullPath = (workDir as NSString).appendingPathComponent(filePath)
            modified = (try? String(contentsOfFile: fullPath, encoding: .utf8)) ?? ""
        }

        return (original, modified)
    }
}
