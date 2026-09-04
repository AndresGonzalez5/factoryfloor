// ABOUTME: GitHub-style Changes view showing stacked inline diffs for all of a workstream's edits.
// ABOUTME: Renders git-derived diffs in Monaco diff editors inside one WKWebView via MonacoDiffBridge.

import AppKit
import Combine
import SwiftUI

/// Transfer box for a completed diff load across isolation boundaries. The
/// `[[String: Any]]` payload can't be `Sendable` (`Any` isn't), but each box
/// is built wholly inside one detached task and never mutated afterwards, so
/// sharing it back to the main actor is race-free by construction.
private final class ChangesLoadBox: @unchecked Sendable {
    let payload: [[String: Any]]
    let files: [DiffFile]
    let baseRef: String

    init(payload: [[String: Any]], files: [DiffFile], baseRef: String) {
        self.payload = payload
        self.files = files
        self.baseRef = baseRef
    }
}

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
    let workstreamID: UUID
    let workingDirectory: String
    let projectDirectory: String
    let bridge: MonacoDiffBridge

    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var fileCount = 0
    @State private var mode: ChangesMode = .branch
    /// Short base-range label for the toolbar (e.g. "main…a1b2c3d"), resolved
    /// with the same load that builds the payload. Empty while loading.
    @State private var baseLabel = ""

    /// Monotonic load generation. Every full/background load bumps it; async
    /// completions whose generation no longer matches are stale (mode switch,
    /// refresh spam, tab switch) and must not touch state or the bridge.
    @State private var loadGeneration = 0
    @State private var loadTask: Task<Void, Never>?

    /// The current changed-file set, surfaced for the sidebar tree. Captured
    /// from the same load that builds the diff payload (no extra git read).
    @State private var diffFiles: [DiffFile] = []
    /// The leaf currently selected in the sidebar (its full relative path).
    @State private var selectedFilePath: String?
    /// Paths currently marked viewed (post-prune). Mirrors the checkboxes in
    /// JS; kept here for the toolbar progress count.
    @State private var viewedPaths: Set<String> = []
    /// Current content version per path (strong hash for loaded bodies, weak
    /// stamp for placeholders). Used to stamp newly-checked Viewed boxes.
    @State private var versionMap: [String: String] = [:]
    /// Base ref string the current content was built against (for viewed-mark
    /// identity, distinct from the short toolbar label).
    @State private var contentBaseRef = "HEAD"

    /// Live width of the files-changed sidebar. Init from UserDefaults so it
    /// survives tab switches and relaunches; a divider DragGesture commits the
    /// final value on release.
    @State private var sidebarWidth: Double

    init(workstreamID: UUID, workingDirectory: String, projectDirectory: String, bridge: MonacoDiffBridge) {
        self.workstreamID = workstreamID
        self.workingDirectory = workingDirectory
        self.projectDirectory = projectDirectory
        self.bridge = bridge
        _sidebarWidth = State(initialValue: Self.loadSidebarWidth())
    }

    /// The whole Changes tab shares ONE loading gate: while a load is in
    /// flight the tree is disabled (skeleton-dimmed, non-interactive) and the
    /// diff pane shows a spinner. The tree never becomes clickable before the
    /// diffs it navigates to exist, which removes the select-during-load race
    /// by construction instead of queuing scrolls.
    private var isBusy: Bool { isLoading || isRefreshing }

    var body: some View {
        VStack(spacing: 0) {
            changesToolbar
            if fileCount == 0 && diffFiles.isEmpty {
                // Empty state: no sidebar — just the "No changes" webview.
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
                HStack(spacing: 0) {
                    ZStack {
                        ChangesFileTreeSidebar(
                            files: diffFiles,
                            selectedFilePath: $selectedFilePath,
                            isEnabled: !isBusy,
                            onSelect: { path in
                                bridge.scrollToFile(path)
                            }
                        )
                        // Dim + block interaction while (re)loading; the stale
                        // tree stays visible instead of flashing away.
                        if isBusy {
                            Color(nsColor: .windowBackgroundColor)
                                .opacity(0.45)
                                .allowsHitTesting(true)
                        }
                    }
                    .frame(width: sidebarWidth)
                    .frame(maxHeight: .infinity)

                    sidebarDivider

                    ZStack {
                        MonacoDiffView(bridge: bridge)
                        if isBusy {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.background.opacity(0.6))
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
            configureLoadHandler(files: bridge.lastDiffFiles)

            if bridge.hasContent && bridge.lastMode == mode.rawValue {
                // Cached content exists for this mode — show it, refresh in background.
                isLoading = false
                fileCount = bridge.lastFileCount
                diffFiles = bridge.lastDiffFiles
                baseLabel = bridge.lastBaseLabel
                backgroundRefreshIfNeeded()
            } else {
                fullLoad()
            }
        }
        .onDisappear {
            // The view is rebuilt on every tab switch; cancel in-flight git
            // work so a stale completion can't overwrite the next visit.
            loadTask?.cancel()
            loadTask = nil
        }
        .onChange(of: mode) {
            // Mode changed — always do a full load.
            bridge.lastFingerprint = nil
            configureLoadHandler()
            fullLoad()
        }
        // Poll the (cheap) fingerprint while visible; silent no-op when
        // nothing in git moved. The view only exists while its tab is active,
        // so no timer leaks into background workstreams.
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            guard !isBusy else { return }
            backgroundRefreshIfNeeded()
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
                if !baseLabel.isEmpty {
                    Text(baseLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(Text(baseLabel))
                }
            }

            Spacer()

            if fileCount > 0 {
                Text(String(
                    format: NSLocalizedString(
                        "%d of %d viewed",
                        comment: "Changes tab: viewed-files progress count"
                    ),
                    viewedPaths.count,
                    fileCount
                ))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                Button {
                    setAllCollapsed(true)
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help(Text("Collapse all files"))
                .accessibilityLabel(Text("Collapse all files"))
                .disabled(isBusy)

                Button {
                    setAllCollapsed(false)
                } label: {
                    Image(systemName: "chevron.down.chevron.up")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help(Text("Expand all files"))
                .accessibilityLabel(Text("Expand all files"))
                .disabled(isBusy)
            }

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

    /// Manual refresh: invalidate cached git state and force a full reload.
    private func refresh() {
        bridge.lastFingerprint = nil
        GitOperations.invalidateRefCaches()
        configureLoadHandler()
        fullLoad()
    }

    /// Collapse or expand every file section at once. JS applies silently (no
    /// per-file message storm); persistence is updated here in bulk.
    private func setAllCollapsed(_ collapsed: Bool) {
        ChangesViewStateStore.setAllCollapsed(
            collapsed,
            workstreamID: workstreamID,
            mode: mode.rawValue,
            paths: diffFiles.map(\.relativePath)
        )
        bridge.setAllCollapsed(collapsed)
    }

    /// Apply one completed load to state + bridge, atomically swapping the
    /// tree and the diff pane together so they can never disagree.
    private func applyLoadedContents(
        _ contents: ChangesLoadBox,
        fingerprint: String,
        mode: ChangesMode,
        baseDisplay: String,
        generation: Int,
        background: Bool
    ) {
        guard generation == loadGeneration else { return }
        let wsID = workstreamID
        let modeKey = mode.rawValue
        let base = contents.baseRef

        // Viewed marks: stamp current versions, prune stale (base moved or
        // content changed under the mark), and flag surviving marks + collapsed
        // sections into the payload before it reaches JS.
        var payload = contents.payload
        let versions = Self.reviewVersions(payload: payload, files: contents.files)
        let viewed = ChangesViewStateStore.pruneViewed(
            workstreamID: wsID,
            mode: modeKey,
            base: base,
            currentVersions: versions
        )
        let collapsed = ChangesViewStateStore.collapsedSet(workstreamID: wsID, mode: modeKey)
        if !viewed.isEmpty || !collapsed.isEmpty {
            for index in payload.indices {
                guard let path = payload[index]["filePath"] as? String else { continue }
                if viewed.contains(path) { payload[index]["viewed"] = true }
                if collapsed.contains(path) { payload[index]["collapsed"] = true }
            }
        }

        diffFiles = contents.files
        selectedFilePath = nil
        fileCount = payload.count
        baseLabel = baseDisplay
        contentBaseRef = base
        versionMap = versions
        viewedPaths = viewed
        bridge.lastFileCount = payload.count
        bridge.lastDiffFiles = contents.files
        bridge.lastFingerprint = fingerprint
        bridge.lastMode = modeKey
        bridge.lastBaseLabel = baseDisplay
        bridge.reviewContext = MonacoDiffBridge.ReviewContext(
            workstreamID: wsID,
            mode: modeKey,
            base: base
        )
        configureLoadHandler(files: contents.files)
        wireReviewCallbacks()
        if background {
            isRefreshing = true
        } else {
            isLoading = true
        }
        bridge.onContentReady = { [generation] in
            // The bridge outlives this view struct (tab switches rebuild the
            // struct); the generation check drops callbacks from superseded
            // loads. @State storage is shared across struct copies, so this
            // assignment reaches the live view when generations match.
            if generation == loadGeneration {
                isLoading = false
                isRefreshing = false
            }
        }
        bridge.setFiles(payload)
    }

    /// Route JS header callbacks (Viewed checkbox, collapse chevron) into the
    /// store + toolbar progress state. Re-installed per load so the captured
    /// workstream/mode/base always match the rendered content.
    private func wireReviewCallbacks() {
        let wsID = workstreamID
        let modeKey = mode.rawValue
        bridge.onViewedChanged = { [contentBaseRef, versionMap] path, viewed in
            let version = versionMap[path]
                ?? ChangesViewStateStore.weakVersion(changedLines: 0, sizeHint: 0)
            ChangesViewStateStore.setViewed(
                viewed,
                workstreamID: wsID,
                mode: modeKey,
                base: contentBaseRef,
                path: path,
                version: version
            )
            if viewed {
                viewedPaths.insert(path)
            } else {
                viewedPaths.remove(path)
            }
        }
        bridge.onCollapsedChanged = { path, collapsed in
            ChangesViewStateStore.setCollapsed(
                collapsed,
                workstreamID: wsID,
                mode: modeKey,
                path: path
            )
        }
    }

    // MARK: - Full load (first visit, mode switch, or explicit refresh)

    private func fullLoad() {
        loadTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        isRefreshing = false
        let workDir = workingDirectory
        let projDir = projectDirectory
        let currentMode = mode

        loadTask = Task {
            // Phase the detached work so rapid mode-switch/refresh spam can
            // cancel between the cheap fingerprint and the expensive build.
            let fingerprint = await Task.detached(priority: .userInitiated) {
                GitOperations.diffFingerprint(
                    worktreePath: workDir,
                    projectPath: projDir,
                    mode: currentMode.rawValue
                )
            }.value
            guard !Task.isCancelled else { return }
            // The payload crosses isolation in an immutable box (see
            // ChangesLoadBox): built wholly inside the detached task.
            let contents = await Task.detached(priority: .userInitiated) { () -> ChangesLoadBox in
                let built = Self.buildContents(workDir: workDir, projDir: projDir, mode: currentMode)
                return ChangesLoadBox(payload: built.payload, files: built.files, baseRef: built.baseRef)
            }.value
            guard !Task.isCancelled else { return }
            let baseDisplay = await Task.detached(priority: .userInitiated) {
                Self.baseDisplayName(workDir: workDir, projDir: projDir, mode: currentMode)
            }.value
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard generation == loadGeneration, currentMode == mode else { return }
                applyLoadedContents(
                    contents,
                    fingerprint: fingerprint,
                    mode: currentMode,
                    baseDisplay: baseDisplay,
                    generation: generation,
                    background: false
                )
            }
        }
    }

    // MARK: - Background refresh (revisit with cached content already shown)

    private func backgroundRefreshIfNeeded() {
        // Never overlap loads; the timer + onAppear can both fire. Stale
        // `loadTask` handles are cancelled outright — only `isBusy` gates.
        guard !isBusy else { return }
        loadTask?.cancel()
        loadGeneration += 1
        let generation = loadGeneration
        let workDir = workingDirectory
        let projDir = projectDirectory
        let currentMode = mode
        let cachedFingerprint = bridge.lastFingerprint

        loadTask = Task {
            let fingerprint = await Task.detached(priority: .userInitiated) {
                GitOperations.diffFingerprint(
                    worktreePath: workDir,
                    projectPath: projDir,
                    mode: currentMode.rawValue
                )
            }.value
            guard !Task.isCancelled else { return }

            // Nothing changed — keep the cached content, no reload, no flicker.
            if fingerprint == cachedFingerprint {
                await MainActor.run {
                    if generation == loadGeneration {
                        loadTask = nil
                    }
                }
                return
            }

            let contents = await Task.detached(priority: .userInitiated) { () -> ChangesLoadBox in
                let built = Self.buildContents(workDir: workDir, projDir: projDir, mode: currentMode)
                return ChangesLoadBox(payload: built.payload, files: built.files, baseRef: built.baseRef)
            }.value
            guard !Task.isCancelled else { return }
            let baseDisplay = await Task.detached(priority: .userInitiated) {
                Self.baseDisplayName(workDir: workDir, projDir: projDir, mode: currentMode)
            }.value
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard generation == loadGeneration, currentMode == mode else { return }
                applyLoadedContents(
                    contents,
                    fingerprint: fingerprint,
                    mode: currentMode,
                    baseDisplay: baseDisplay,
                    generation: generation,
                    background: true
                )
            }
        }
    }

    /// Short human-readable base range for the toolbar (e.g. "main…a1b2c3d").
    /// Falls back to the mode label when git state is unavailable.
    nonisolated static func baseDisplayName(workDir: String, projDir: String, mode: ChangesMode) -> String {
        switch mode {
        case .uncommitted:
            let head = (GitOperations.runData(args: ["rev-parse", "--short", "HEAD"], in: workDir))
                .flatMap { String(data: $0, encoding: .utf8) }?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return head.isEmpty ? mode.label : "HEAD \(head)"
        case .branch:
            let branch = GitOperations.cachedDefaultBranch(at: projDir)
            let shortBranch = (branch as NSString).lastPathComponent
            let base = baseRef(workDir: workDir, projDir: projDir, mode: mode)
            let short = String(base.prefix(7))
            if short.isEmpty || short == "HEAD" { return mode.label }
            return "\(shortBranch)…\(short)"
        }
    }

    // MARK: - Click-to-load wiring

    /// Give the bridge enough context (workDir + mode) to resolve a single
    /// deferred file's content when its placeholder is clicked. The git base ref
    /// is resolved lazily inside the resolver, which the bridge runs off the main
    /// thread, so no git command blocks the main thread here.
    private func configureLoadHandler(files: [DiffFile] = []) {
        let workDir = workingDirectory
        let projDir = projectDirectory
        let currentMode = mode
        // Snapshot rename/status metadata so deferred click-to-load resolves
        // the original side through the pre-rename path without a main-thread
        // lookup when the bridge fires off-thread.
        let meta = Dictionary(uniqueKeysWithValues: files.map { ($0.relativePath, $0) })
        bridge.onLoadFile = { filePath in
            // Runs off the main thread; resolves base ref + content for one file.
            let baseRef = Self.baseRef(workDir: workDir, projDir: projDir, mode: currentMode)
            let file = meta[filePath]
            let (original, modified) = Self.fileTexts(
                workDir: workDir,
                baseRef: baseRef,
                filePath: filePath,
                status: file?.status,
                oldPath: file?.oldPath
            )
            let languageId = MonacoLanguage.id(for: (filePath as NSString).lastPathComponent)
            return (original, modified, languageId)
        }
    }

    // MARK: - Sidebar width persistence

    /// Clamp bounds for the files-changed sidebar width.
    private static let changesSidebarMinWidth: Double = 180
    private static let changesSidebarMaxWidth: Double = 480
    /// Default width matching the pre-persistence behavior.
    private static let changesSidebarDefault: Double = 240
    private static let changesSidebarWidthKey = "factoryfloor.changesSidebarWidth"

    static func loadSidebarWidth() -> Double {
        let stored = UserDefaults.standard.double(forKey: changesSidebarWidthKey)
        return stored == 0 ? changesSidebarDefault : clampWidth(stored)
    }

    static func clampWidth(_ width: Double) -> Double {
        min(changesSidebarMaxWidth, max(changesSidebarMinWidth, width))
    }

    /// The resizable divider between the sidebar and the diff review. Drags
    /// resize the sidebar live; the final width is committed to UserDefaults
    /// on release so it survives tab switches and relaunches.
    private var sidebarDivider: some View {
        Color.clear
            .frame(width: 9)
            .overlay(
                Rectangle()
                    .fill(.separator)
                    .frame(width: 1)
            )
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        sidebarWidth = Self.clampWidth(
                            Self.loadSidebarWidth() + Double(value.translation.width)
                        )
                    }
                    .onEnded { value in
                        sidebarWidth = Self.clampWidth(
                            Self.loadSidebarWidth() + Double(value.translation.width)
                        )
                        UserDefaults.standard.set(sidebarWidth, forKey: Self.changesSidebarWidthKey)
                    }
            )
    }

    // MARK: - Large-file guard thresholds

    /// A file with more than this many changed lines is deferred (Hardening 3).
    nonisolated static let largeFileLineThreshold = 1500
    /// A file larger than this many bytes on disk is deferred (Hardening 3).
    nonisolated static let largeFileByteThreshold = 500 * 1024
    /// A file with a single line longer than this many characters is deferred:
    /// minified bundles stall Monaco's diff computation far out of proportion
    /// to their line count. Checked AFTER content is read (post-classify
    /// demotion); click-to-load still renders on demand.
    nonisolated static let largeFileSingleLineThreshold = 20_000
    /// A file whose combined original+modified text exceeds this many
    /// characters is deferred for the same reason as above.
    nonisolated static let largeFileCharThreshold = 1_000_000

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

    /// Post-read demotion for files that passed `classify` but whose content
    /// would stall Monaco (minified single-line bundles, huge totals).
    /// Runs on already-read text so no extra I/O is involved.
    nonisolated static func exceedsContentLimits(original: String, modified: String) -> Bool {
        if original.count + modified.count > largeFileCharThreshold { return true }
        for text in [original, modified] {
            var lineLength = 0
            for scalar in text.unicodeScalars {
                if scalar == "\n" {
                    lineLength = 0
                } else {
                    lineLength += 1
                    if lineLength > largeFileSingleLineThreshold { return true }
                }
            }
        }
        return false
    }

    /// Stable version stamp for a file's diff content. The Viewed store keeps
    /// this per path and clears the mark when the stamp moves (GitHub-style
    /// invalidate-on-modify), covering both base-side and worktree-side edits.
    nonisolated static func contentVersion(original: String, modified: String) -> String {
        GitOperations.stableHash("\(original.count)\n\(original)\n\(modified.count)\n\(modified)")
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

    /// Build both the JS `setFiles` payload AND the structured, tree-ordered
    /// list of changed files in one pass. The sidebar tree is built from `files`
    /// while the diff webview renders `payload` in that same tree order; sharing
    /// one git read keeps the two in sync and avoids re-running git for the
    /// sidebar. Also returns the base ref the originals were read from, which
    /// identifies viewed marks in `ChangesViewStateStore`.
    nonisolated static func buildContents(
        workDir: String,
        projDir: String,
        mode: ChangesMode
    ) -> (payload: [[String: Any]], files: [DiffFile], baseRef: String) {
        let diffFiles: [DiffFile]
        switch mode {
        case .branch:
            diffFiles = GitOperations.branchDiffFiles(worktreePath: workDir, projectPath: projDir)
        case .uncommitted:
            diffFiles = GitOperations.uncommittedDiffFiles(at: workDir)
        }

        let baseRef = baseRef(workDir: workDir, projDir: projDir, mode: mode)

        // Order diffs exactly as the sidebar tree displays them (directories
        // before files, alphabetical at every level), so the code review scrolls
        // in lockstep with the "Files changed" sidebar.
        let orderedFiles = Self.flattenedTreeOrder(diffFiles)

        // Classify first so original-side git reads batch into ONE
        // `git cat-file --batch` process instead of one `git show` per file.
        // Renames look up the OLD path at the base ref.
        let classes = orderedFiles.map {
            classify(isBinary: $0.isBinary, changedLines: $0.changedLines, sizeHint: $0.sizeHint)
        }
        var originalByLookup: [String: String] = [:]
        let neededLookups = orderedFiles.indices.compactMap { index -> String? in
            guard classes[index] == .normal, orderedFiles[index].status != .added else { return nil }
            return orderedFiles[index].oldPath ?? orderedFiles[index].relativePath
        }
        if !neededLookups.isEmpty {
            originalByLookup = GitOperations.batchFileContents(at: workDir, ref: baseRef, paths: neededLookups)
        }

        var payload: [[String: Any]] = []
        payload.reserveCapacity(orderedFiles.count)

        for (index, file) in orderedFiles.enumerated() {
            var entry: [String: Any] = [
                "filePath": file.relativePath,
                "status": file.status.rawValue,
                "languageId": MonacoLanguage.id(for: (file.relativePath as NSString).lastPathComponent),
                "changedLines": file.changedLines,
            ]

            switch classes[index] {
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
                let lookup = file.oldPath ?? file.relativePath
                let original = file.status == .added ? "" : (originalByLookup[lookup] ?? "")
                let modified: String = {
                    if file.status == .deleted { return "" }
                    let fullPath = (workDir as NSString).appendingPathComponent(file.relativePath)
                    // Lossy decode: undecodable bytes become U+FFFD instead of
                    // failing the whole read (which rendered empty diffs).
                    return GitOperations.lossyFileText(atPath: fullPath) ?? ""
                }()
                if exceedsContentLimits(original: original, modified: modified) {
                    // Minified/huge content: demote to click-to-load even
                    // though the line/byte pre-checks passed.
                    entry["deferred"] = true
                    entry["originalText"] = ""
                    entry["modifiedText"] = ""
                } else {
                    entry["originalText"] = original
                    entry["modifiedText"] = modified
                }
            }

            payload.append(entry)
        }

        return (payload, orderedFiles, baseRef)
    }

    /// Current review version per path for a built payload: strong content
    /// hash for entries carrying bodies, weak size stamp for binary/deferred
    /// placeholders. Pure (testable) so the store prune can run anywhere.
    nonisolated static func reviewVersions(
        payload: [[String: Any]],
        files: [DiffFile]
    ) -> [String: String] {
        var versions: [String: String] = [:]
        versions.reserveCapacity(files.count)
        let bodies = Dictionary(uniqueKeysWithValues: payload.compactMap { entry -> (String, [String: Any])? in
            guard let path = entry["filePath"] as? String else { return nil }
            return (path, entry)
        })
        for file in files {
            let path = file.relativePath
            if let entry = bodies[path],
               let original = entry["originalText"] as? String,
               let modified = entry["modifiedText"] as? String,
               entry["binary"] as? Bool != true,
               entry["deferred"] as? Bool != true
            {
                versions[path] = contentVersion(original: original, modified: modified)
            } else {
                versions[path] = ChangesViewStateStore.weakVersion(
                    changedLines: file.changedLines,
                    sizeHint: file.sizeHint
                )
            }
        }
        return versions
    }

    /// Depth-first flattening of the sidebar tree. Directories come before
    /// sibling files and every level is alphabetical (case-insensitive) —
    /// identical to how `ChangesFileTreeSidebar` renders its rows, so the diff
    /// order always matches what the user sees in the sidebar.
    nonisolated static func flattenedTreeOrder(_ files: [DiffFile]) -> [DiffFile] {
        var ordered: [DiffFile] = []
        func visit(_ node: FileTreeNode) {
            if let file = node.diffFile {
                ordered.append(file)
            } else if let children = node.children {
                for child in children {
                    visit(child)
                }
            }
        }
        if let topLevel = FileTreeNode.build(from: files).children {
            for node in topLevel {
                visit(node)
            }
        }
        return ordered
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
    /// Renames resolve the original side through `oldPath` (the pre-rename path
    /// at the base ref). Disk reads decode lossy so non-UTF8 files still diff.
    nonisolated static func fileTexts(
        workDir: String,
        baseRef: String,
        filePath: String,
        status: DiffFile.Status? = nil,
        oldPath: String? = nil
    ) -> (original: String, modified: String) {
        let original: String
        if status == .added {
            original = ""
        } else {
            original = GitOperations.fileContent(at: workDir, ref: baseRef, filePath: oldPath ?? filePath) ?? ""
        }

        let modified: String
        if status == .deleted {
            modified = ""
        } else {
            let fullPath = (workDir as NSString).appendingPathComponent(filePath)
            modified = GitOperations.lossyFileText(atPath: fullPath) ?? ""
        }

        return (original, modified)
    }
}
