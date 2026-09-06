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
    /// Working-tree changes vs HEAD (plus untracked files). The default: this
    /// is what you watch while an agent is working.
    case uncommitted
    /// Everything that differs between merge-base(defaultBranch, HEAD) and the worktree.
    case branch

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
    /// Open a file in a full Editor tab (wired by the workspace container).
    var onOpenInEditor: ((String) -> Void)? = nil
    /// Reports whether ANY diff edit is unsaved (wired by the workspace
    /// container to drive the Save menu item state).
    var onDirtyChanged: ((Bool) -> Void)? = nil
    /// Whether this workspace is frontmost. Guards the Cmd+S handler so a
    /// save keypress can't persist diff edits in a background workstream
    /// (every mounted ChangesView observes the same notification).
    var isActive = true

    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var fileCount = 0
    @State private var mode: ChangesMode = .uncommitted
    /// Short base-range label for the toolbar (e.g. "main…a1b2c3d"), resolved
    /// with the same load that builds the payload. Empty while loading.
    @State private var baseLabel = ""

    /// Monotonic load generation. Every full/background load bumps it; async
    /// completions whose generation no longer matches are stale (mode switch,
    /// refresh spam, tab switch) and must not touch state or the bridge.
    @State private var loadGeneration = 0
    @State private var loadTask: Task<Void, Never>?
    /// Backstop for a `contentReady` that never arrives (JS stall, dropped
    /// bridge message): clears the loading flags so the tab can never stick
    /// in a spinner forever. Cancelled on every new load and on disappear;
    /// stale firings self-skip via the captured generation.
    @State private var watchdogTask: Task<Void, Never>?

    /// The current changed-file set, surfaced for the sidebar tree. Captured
    /// from the same load that builds the diff payload (no extra git read).
    @State private var diffFiles: [DiffFile] = []
    /// The leaf currently selected in the sidebar (its full relative path).
    @State private var selectedFilePath: String?
    /// Paths currently marked viewed (post-prune). Mirrors the checkboxes in
    /// JS; kept here for the toolbar progress count.
    @State private var viewedPaths: Set<String> = []
    /// Paths currently collapsed. Mirrors the chevrons in JS (per-file
    /// toggles report via `onCollapsedChanged`, bulk ones via
    /// `setAllCollapsed`); drives the collapse-all/expand-all toggle button.
    @State private var collapsedPaths: Set<String> = []
    /// Current content version per path (strong hash for loaded bodies, weak
    /// stamp for placeholders). Used to stamp newly-checked Viewed boxes.
    @State private var versionMap: [String: String] = [:]
    /// Base ref string the current content was built against (for viewed-mark
    /// identity, distinct from the short toolbar label).
    @State private var contentBaseRef = "HEAD"

    /// Paths with unsaved inline edits in the diff (mirrors `bridge.dirtyPaths`,
    /// which is the copy that survives tab switches rebuilding this struct).
    @State private var dirtyPaths: Set<String> = []
    /// Paths currently being written to disk (re-entrant Save guard).
    @State private var savingPaths: Set<String> = []
    /// File whose inline-edit save just failed (nil = no alert).
    @State private var saveErrorPath: String?
    /// File awaiting delete confirmation (nil = no alert). Trash vs Discard
    /// wording resolves via `pendingDeleteTrash` before showing.
    @State private var pendingDelete: DiffFile?
    @State private var pendingDeleteTrash = false
    @State private var pendingDeleteStagedNew = false
    /// File whose delete/discard just failed (nil = no alert).
    @State private var deleteErrorPath: String?

    /// Live width of the files-changed sidebar. Init from UserDefaults so it
    /// survives tab switches and relaunches; a divider DragGesture commits the
    /// final value on release.
    @State private var sidebarWidth: Double

    init(workstreamID: UUID, workingDirectory: String, projectDirectory: String, bridge: MonacoDiffBridge, onOpenInEditor: ((String) -> Void)? = nil, onDirtyChanged: ((Bool) -> Void)? = nil, isActive: Bool = true) {
        self.workstreamID = workstreamID
        self.workingDirectory = workingDirectory
        self.projectDirectory = projectDirectory
        self.bridge = bridge
        self.onOpenInEditor = onOpenInEditor
        self.onDirtyChanged = onDirtyChanged
        self.isActive = isActive
        _sidebarWidth = State(initialValue: Self.loadSidebarWidth())
    }

    /// The whole Changes tab shares ONE loading gate: while a load is in
    /// flight the diff pane shows a spinner. The file tree is gated
    /// separately (`isTreeEnabled`): it stays interactive whenever it has
    /// files to navigate to, so Monaco diff computation can never freeze
    /// file navigation. Tree selection force-mounts its target, so picking
    /// a file whose body is still streaming simply prioritizes it.
    private var isBusy: Bool { isLoading || isRefreshing }

    /// The tree only blocks on the very first load, when there is nothing to
    /// show yet. Stale files during a reload stay clickable: the tree and the
    /// diff pane swap atomically per load, so they can never disagree.
    private var isTreeEnabled: Bool { !(diffFiles.isEmpty && isBusy) }

    /// Whether every listed file is currently collapsed. Drives the single
    /// collapse/expand-all toggle: collapsing when anything is expanded,
    /// expanding when all are already collapsed.
    private var allCollapsed: Bool {
        !diffFiles.isEmpty && diffFiles.allSatisfy { collapsedPaths.contains($0.relativePath) }
    }

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
                            isEnabled: isTreeEnabled,
                            onSelect: { path in
                                bridge.scrollToFile(path)
                            },
                            onOpenInEditor: { path in
                                onOpenInEditor?(path)
                            },
                            onDelete: { file in
                                requestDelete(file)
                            }
                        )
                        // Dim + block interaction only while the first load has
                        // nothing to show yet; reloads keep the stale tree live.
                        if diffFiles.isEmpty && isBusy {
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
                        // Cover the diff pane only when there is no content to
                        // show yet. Reloads render shells in milliseconds and
                        // stream bodies into skeleton placeholders, so the
                        // stale diffs stay visible instead of flashing away
                        // behind a spinner.
                        if isBusy && diffFiles.isEmpty {
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
            // The bridge outlives this struct across tab switches; restore any
            // unsaved-edit marks so refresh guards stay correct.
            dirtyPaths = bridge.dirtyPaths
            onDirtyChanged?(!dirtyPaths.isEmpty)

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
            // The body stream is intentionally NOT cancelled: it touches only
            // the bridge (which outlives the view) and superseded streams
            // stop themselves via streamGeneration.
            loadTask?.cancel()
            loadTask = nil
            watchdogTask?.cancel()
            watchdogTask = nil
        }
        .onChange(of: mode) {
            // Mode changed — always do a full load.
            bridge.lastFingerprint = nil
            configureLoadHandler()
            fullLoad()
        }
        // Poll the (cheap) fingerprint while visible; silent no-op when
        // nothing in git moved. The view only exists while its tab is active,
        // so no timer leaks into background workstreams. Skips while git work
        // is in flight instead of cancelling it: restarting a slow load on
        // every tick meant it never completed.
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            guard loadTask == nil else { return }
            backgroundRefreshIfNeeded()
        }
        // Cmd+S (Save menu): persist diff edits without reaching for the mouse.
        .onReceive(NotificationCenter.default.publisher(for: .saveEditor)) { _ in
            saveViaKeyboard()
        }
        .alert(
            pendingDeleteTrash ? "Move to Trash" : "Discard Changes",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) {}
            Button(
                pendingDeleteTrash ? "Move to Trash" : "Discard",
                role: .destructive
            ) {
                if let file = pendingDelete {
                    performDelete(
                        file,
                        trash: pendingDeleteTrash,
                        stagedNew: pendingDeleteStagedNew
                    )
                }
            }
        } message: {
            if let file = pendingDelete {
                if pendingDeleteTrash {
                    Text(String(
                        format: NSLocalizedString(
                            "\"%@\" will be moved to the Trash.",
                            comment: "Changes tab: untracked/staged-new file delete confirmation"
                        ),
                        file.relativePath
                    ))
                } else {
                    Text(String(
                        format: NSLocalizedString(
                            "Discard all uncommitted changes to \"%@\"? This cannot be undone.",
                            comment: "Changes tab: tracked file discard confirmation"
                        ),
                        file.relativePath
                    ))
                }
            }
        }
        .alert(
            "Could Not Save",
            isPresented: Binding(
                get: { saveErrorPath != nil },
                set: { if !$0 { saveErrorPath = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let path = saveErrorPath {
                Text(String(
                    format: NSLocalizedString(
                        "Could not save \"%@\".",
                        comment: "Changes tab: inline-edit save failure"
                    ),
                    path
                ))
            }
        }
        .alert(
            "Could Not Delete",
            isPresented: Binding(
                get: { deleteErrorPath != nil },
                set: { if !$0 { deleteErrorPath = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let path = deleteErrorPath {
                Text(String(
                    format: NSLocalizedString(
                        "Could not delete \"%@\".",
                        comment: "Changes tab: file delete/discard failure"
                    ),
                    path
                ))
            }
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
            // Mode switches rebuild every editor: block while edits are
            // unsaved rather than silently dropping them.
            .disabled(!dirtyPaths.isEmpty)
            .help(dirtyPaths.isEmpty ? Text(mode.label) : Text("Save your edits before switching modes"))

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
                if !dirtyPaths.isEmpty {
                    Text("•")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.orange)
                    Text("Unsaved changes")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
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
                    setAllCollapsed(!allCollapsed)
                } label: {
                    // Verified-existant pair (chevron.down.chevron.up does not
                    // exist and renders blank — it hid the old expand button).
                    Image(systemName: allCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help(Text(allCollapsed ? "Expand all files" : "Collapse all files"))
                .accessibilityLabel(Text(allCollapsed ? "Expand all files" : "Collapse all files"))
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
            .disabled(isLoading || isRefreshing || !dirtyPaths.isEmpty)
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
    /// per-file message storm); persistence and the toolbar-toggle mirror are
    /// updated here in bulk.
    private func setAllCollapsed(_ collapsed: Bool) {
        ChangesViewStateStore.setAllCollapsed(
            collapsed,
            workstreamID: workstreamID,
            mode: mode.rawValue,
            paths: diffFiles.map(\.relativePath)
        )
        if collapsed {
            collapsedPaths.formUnion(diffFiles.map(\.relativePath))
        } else {
            collapsedPaths.subtract(diffFiles.map(\.relativePath))
        }
        bridge.setAllCollapsed(collapsed)
    }

    /// Apply one completed load to state + bridge, atomically swapping the
    /// tree and the diff shells together so they can never disagree. Sends
    /// metadata-only shells (not bodies), so first paint never waits on
    /// Monaco diff computation or one giant JSON transfer — and installs the
    /// watchdog in case `contentReady` never arrives. Returns the body
    /// entries the caller must stream via `streamBodies`.
    private func applyLoadedContents(
        _ contents: ChangesLoadBox,
        fingerprint: String,
        mode: ChangesMode,
        baseDisplay: String,
        generation: Int,
        background: Bool
    ) -> [[String: Any]] {
        guard generation == loadGeneration else { return [] }
        let wsID = workstreamID
        let modeKey = mode.rawValue
        let base = contents.baseRef

        // Viewed marks: stamp current versions, prune stale (base moved or
        // content changed under the mark), and flag surviving marks + collapsed
        // sections into the shells before they reach JS. Versions come from
        // the full background-built payload, so streamed bodies arriving later
        // never invalidate the marks stamped here.
        let payload = contents.payload
        let versions = Self.reviewVersions(payload: payload, files: contents.files)
        let viewed = ChangesViewStateStore.pruneViewed(
            workstreamID: wsID,
            mode: modeKey,
            base: base,
            currentVersions: versions
        )
        let collapsed = ChangesViewStateStore.collapsedSet(workstreamID: wsID, mode: modeKey)
        var shells = Self.shells(from: payload)
        if !viewed.isEmpty || !collapsed.isEmpty {
            for index in shells.indices {
                guard let path = shells[index]["filePath"] as? String else { continue }
                if viewed.contains(path) { shells[index]["viewed"] = true }
                if collapsed.contains(path) { shells[index]["collapsed"] = true }
            }
        }

        diffFiles = contents.files
        selectedFilePath = nil
        fileCount = shells.count
        baseLabel = baseDisplay
        contentBaseRef = base
        versionMap = versions
        viewedPaths = viewed
        // The store's collapsed set is append-only across listings, so it can
        // hold stale paths; intersect for the toggle mirror (shell stamping
        // above is unaffected — stale paths simply match nothing).
        collapsedPaths = collapsed.intersection(contents.files.map(\.relativePath))
        // setShells rebuilds every JS model from scratch, so any edit state is
        // clean by construction. Loads only happen while clean (refresh, mode
        // switch, and revisit paths all gate on dirtyPaths), so this is a
        // safety net, not a data-loss path.
        clearAllDirty()
        // Record on-disk conventions for the save path (Monaco round-trips
        // everything as LF without BOM). Deferred/binary placeholders carry
        // no texts and are stamped when their bodies load instead.
        for entry in payload {
            guard let path = entry["filePath"] as? String,
                  let modified = entry["modifiedText"] as? String,
                  !modified.isEmpty
            else { continue }
            stampEOL(path: path, modified: modified)
        }
        bridge.lastFileCount = shells.count
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
        if bridge.setShells(shells) {
            startWatchdog(generation: generation, modeKey: modeKey, fileCount: shells.count)
        } else {
            // Serialization failed: contentReady will never arrive. The tree
            // data is local and already swapped in, so show it instead of
            // sticking the spinner forever.
            isLoading = false
            isRefreshing = false
        }
        return Self.bodyEntries(from: payload)
    }

    /// Backstop for a `contentReady` that never arrives (JS stall or dropped
    /// bridge message): force-clears the loading flags and logs, so the tab
    /// can never stick in "Refreshing…" forever. Stale firings self-skip via
    /// the captured generation. The 10s fingerprint timer resumes afterwards
    /// and retries the load on its next tick.
    private func startWatchdog(generation: Int, modeKey: String, fileCount: Int) {
        watchdogTask?.cancel()
        watchdogTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            guard !Task.isCancelled, generation == loadGeneration else { return }
            if isLoading || isRefreshing {
                print(
                    "[Changes] watchdog: contentReady never arrived "
                        + "(mode=\(modeKey), files=\(fileCount)); clearing loading state"
                )
                isLoading = false
                isRefreshing = false
            }
        }
    }

    /// Stream diff bodies into the rendered shells in small chunks, yielding
    /// between chunks so the main thread stays responsive. Runs outside
    /// `loadTask` in a task touching only the bridge (which outlives the
    /// view), so a tab switch mid-stream can't strand skeleton placeholders:
    /// the stream continues into the persistent webview. Superseded streams
    /// stop themselves via `streamGeneration`; duplicate deliveries are
    /// ignored by JS.
    private func streamBodies(_ bodies: [[String: Any]]) {
        let bridge = bridge
        let streamGen = bridge.streamGeneration
        guard !bodies.isEmpty, bridge.streamGeneration == streamGen else { return }
        Task { @MainActor in
            let chunkSize = 12
            var index = 0
            while index < bodies.count {
                guard bridge.streamGeneration == streamGen else { return }
                let end = min(index + chunkSize, bodies.count)
                for entry in bodies[index..<end] {
                    guard bridge.streamGeneration == streamGen,
                          let path = entry["filePath"] as? String,
                          let original = entry["originalText"] as? String,
                          let modified = entry["modifiedText"] as? String,
                          let languageId = entry["languageId"] as? String
                    else { continue }
                    bridge.loadFileContent(
                        filePath: path,
                        originalText: original,
                        modifiedText: modified,
                        languageId: languageId,
                        editable: entry["editable"] as? Bool ?? false
                    )
                }
                index = end
                await Task.yield()
            }
        }
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
            if collapsed {
                collapsedPaths.insert(path)
            } else {
                collapsedPaths.remove(path)
            }
        }
        bridge.onContentChanged = { path, dirty in
            setDirty(path, dirty: dirty)
        }
        bridge.onSaveFile = { path in
            saveFile(path)
        }
        bridge.onRevertFile = { path in
            reloadFileContent(path)
        }
        bridge.onOpenInEditor = { [onOpenInEditor] path in
            onOpenInEditor?(path)
        }
    }

    // MARK: - Inline edit + delete

    /// Single funnel for dirty-state changes: keeps the @State mirror and the
    /// bridge copy (which survives tab switches) in sync, and pushes the
    /// any-dirty bit to the workspace container for the Save menu item.
    private func setDirty(_ path: String, dirty: Bool) {
        if dirty {
            dirtyPaths.insert(path)
            bridge.dirtyPaths.insert(path)
        } else {
            dirtyPaths.remove(path)
            bridge.dirtyPaths.remove(path)
        }
        onDirtyChanged?(!dirtyPaths.isEmpty)
    }

    /// Clear all dirty marks (fresh shells content is clean by construction).
    private func clearAllDirty() {
        dirtyPaths.removeAll()
        bridge.dirtyPaths.removeAll()
        bridge.eolMap.removeAll()
        bridge.bomPaths.removeAll()
        onDirtyChanged?(false)
    }

    /// Line ending of on-disk text, detected at load. Monaco normalizes to LF
    /// in the model, so saves convert back — otherwise persisting one edit in
    /// a CRLF file rewrites every line ending. Pure (testable).
    nonisolated static func detectEOL(_ text: String) -> String {
        text.contains("\r\n") ? "crlf" : "lf"
    }

    /// Restore a saved text to its on-disk conventions: CRLF line endings and
    /// a UTF-8 BOM when the loaded file had them. Normalizes to LF first so
    /// an already-CRLF fragment can never double up. Pure (testable).
    nonisolated static func encodeForSave(_ text: String, eol: String, bom: Bool) -> String {
        var out = text
        if eol == "crlf" {
            out = out.replacingOccurrences(of: "\r\n", with: "\n")
            out = out.replacingOccurrences(of: "\n", with: "\r\n")
        }
        if bom, !out.hasPrefix("\u{FEFF}") {
            out = "\u{FEFF}" + out
        }
        return out
    }

    /// Record one file's on-disk conventions from freshly resolved text.
    /// Same lifetime as the dirty mirrors: cleared on every fresh load.
    private func stampEOL(path: String, modified: String) {
        if modified.contains("\r\n") {
            bridge.eolMap[path] = "crlf"
        } else {
            bridge.eolMap.removeValue(forKey: path)
        }
        if modified.hasPrefix("\u{FEFF}") {
            bridge.bomPaths.insert(path)
        } else {
            bridge.bomPaths.remove(path)
        }
    }

    /// Cmd+S: save the focused dirty file, else the selected dirty file, else
    /// all dirty files. Target order resolves in JS against live editor state,
    /// so a keypress racing the contentChanged message still hits the file
    /// being typed in.
    private func saveViaKeyboard() {
        guard isActive else { return }
        let selected = selectedFilePath
        Task {
            for path in await bridge.saveTargets(selected: selected) {
                saveFile(path)
            }
        }
    }

    /// Persist one file's inline diff edit to the worktree. Reads the live
    /// modified-side text from JS, restores its on-disk line endings/BOM,
    /// writes it atomically, then clears the dirty mark. Refreshes fully only
    /// when nothing else is unsaved; otherwise just the saved file's section
    /// is reloaded in place — a full reload would drop other unsaved edits.
    private func saveFile(_ path: String) {
        guard !savingPaths.contains(path) else { return }
        savingPaths.insert(path)
        let workDir = workingDirectory
        let eol = bridge.eolMap[path] ?? "lf"
        let bom = bridge.bomPaths.contains(path)
        Task {
            let rawText = await bridge.getContent(filePath: path)
            guard let rawText else {
                await MainActor.run { savingPaths.remove(path) }
                return
            }
            let text = Self.encodeForSave(rawText, eol: eol, bom: bom)
            let saved = await Task.detached(priority: .userInitiated) { () -> Bool in
                let fullPath = (workDir as NSString).appendingPathComponent(path)
                do {
                    try text.write(toFile: fullPath, atomically: true, encoding: .utf8)
                    return true
                } catch {
                    return false
                }
            }.value
            await MainActor.run {
                savingPaths.remove(path)
                guard saved else {
                    saveErrorPath = path
                    return
                }
                bridge.markClean(filePath: path)
                setDirty(path, dirty: false)
                if dirtyPaths.isEmpty {
                    backgroundRefreshIfNeeded()
                } else {
                    reloadFileContent(path)
                }
            }
        }
    }

    /// Re-resolve one file's texts off the main thread and push them into the
    /// live section in place (no full reload). Shared by Revert (abandon the
    /// inline edit — the escape hatch for the refresh/mode-switch guards) and
    /// post-save refresh (collapse the saved diff while other files stay
    /// dirty). Re-stamps EOL/BOM detection and revalidates the Viewed mark
    /// against the fresh content, mirroring a real reload.
    private func reloadFileContent(_ path: String) {
        guard !savingPaths.contains(path) else { return }
        // Snapshot everything the background read needs: the view struct
        // itself must not cross into the detached task.
        let workDir = workingDirectory
        let projDir = projectDirectory
        let currentMode = mode
        let meta = bridge.lastDiffFiles.first { $0.relativePath == path }
        let status = meta?.status
        let oldPath = meta?.oldPath
        let wsID = workstreamID
        let modeKey = mode.rawValue
        let base = contentBaseRef
        Task.detached(priority: .userInitiated) {
            let fresh = Self.freshTexts(
                workDir: workDir,
                projDir: projDir,
                mode: currentMode,
                filePath: path,
                status: status,
                oldPath: oldPath
            )
            await MainActor.run {
                self.bridge.setFileContent(
                    filePath: path,
                    originalText: fresh.original,
                    modifiedText: fresh.modified
                )
                self.stampEOL(path: path, modified: fresh.modified)
                self.setDirty(path, dirty: false)
                let version = Self.contentVersion(original: fresh.original, modified: fresh.modified)
                let survives = ChangesViewStateStore.validateViewed(
                    workstreamID: wsID,
                    mode: modeKey,
                    base: base,
                    path: path,
                    version: version
                )
                if !survives {
                    self.bridge.setViewed(filePath: path, viewed: false)
                    self.viewedPaths.remove(path)
                }
            }
        }
    }

    /// Resolve a fresh (original, modified, editable) triple for one file with
    /// the same base-ref + lossy-decode + strict-UTF-8-gate rules as the
    /// initial payload and click-to-load. Pure (apart from git/disk reads).
    nonisolated static func freshTexts(
        workDir: String,
        projDir: String,
        mode: ChangesMode,
        filePath: String,
        status: DiffFile.Status?,
        oldPath: String?
    ) -> (original: String, modified: String, editable: Bool) {
        let base = Self.baseRef(workDir: workDir, projDir: projDir, mode: mode)
        let (original, modified) = Self.fileTexts(
            workDir: workDir,
            baseRef: base,
            filePath: filePath,
            status: status,
            oldPath: oldPath
        )
        let editable = mode == .uncommitted
            && status != .deleted
            && GitOperations.isValidUTF8(
                atPath: (workDir as NSString).appendingPathComponent(filePath)
            )
        return (original, modified, editable)
    }

    /// Start the git-aware delete flow for a tree file: resolve Trash
    /// (untracked, plus staged-new which has no HEAD version to restore) vs
    /// Discard (tracked) off the main thread, then show the confirmation.
    private func requestDelete(_ file: DiffFile) {
        let workDir = workingDirectory
        let path = file.relativePath
        Task {
            let (untracked, stagedNew) = await Task.detached(priority: .userInitiated) {
                (
                    GitOperations.isUntrackedFile(at: workDir, filePath: path),
                    GitOperations.isStagedNew(at: workDir, filePath: path)
                )
            }.value
            await MainActor.run {
                pendingDelete = file
                pendingDeleteTrash = untracked || stagedNew
                pendingDeleteStagedNew = stagedNew
            }
        }
    }

    /// Carry out a confirmed delete: trash untracked files (unstaging
    /// staged-new ones first so no index entry is stranded), restore tracked
    /// ones from HEAD. A failed discard (renames, unexpected index states)
    /// reports instead of silently leaving the file. Clears any unsaved-edit
    /// mark for the path, then prunes the row locally — a full reload waits
    /// for other unsaved edits to clear, so the trashed file would otherwise
    /// linger in the tree.
    private func performDelete(_ file: DiffFile, trash: Bool, stagedNew: Bool) {
        pendingDelete = nil
        let workDir = workingDirectory
        let path = file.relativePath
        Task {
            let succeeded = await Task.detached(priority: .userInitiated) { () -> Bool in
                if trash {
                    if stagedNew {
                        GitOperations.unstageFile(at: workDir, filePath: path)
                    }
                    let url = URL(
                        fileURLWithPath: (workDir as NSString).appendingPathComponent(path)
                    )
                    do {
                        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                        return true
                    } catch {
                        return false
                    }
                } else {
                    return GitOperations.discardFileChanges(at: workDir, filePath: path)
                }
            }.value
            await MainActor.run {
                guard succeeded else {
                    deleteErrorPath = path
                    return
                }
                setDirty(path, dirty: false)
                pruneDeletedFile(path)
                GitOperations.invalidateRefCaches()
                bridge.lastFingerprint = nil
                if dirtyPaths.isEmpty {
                    backgroundRefreshIfNeeded()
                }
            }
        }
    }

    /// Drop one deleted file from the tree and the diff page without a full
    /// reload (which may be blocked by other unsaved edits). The next full
    /// load rebuilds everything from git, reconciling any drift.
    private func pruneDeletedFile(_ path: String) {
        diffFiles.removeAll { $0.relativePath == path }
        fileCount = diffFiles.count
        if selectedFilePath == path { selectedFilePath = nil }
        viewedPaths.remove(path)
        collapsedPaths.remove(path)
        bridge.removeFile(filePath: path)
        bridge.lastDiffFiles.removeAll { $0.relativePath == path }
        bridge.lastFileCount = diffFiles.count
    }

    // MARK: - Full load (first visit, mode switch, or explicit refresh)

    private func fullLoad() {
        loadTask?.cancel()
        watchdogTask?.cancel()
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
                // Stale completions must not clear a newer load's task handle.
                defer { if generation == loadGeneration { loadTask = nil } }
                guard generation == loadGeneration, currentMode == mode else { return }
                let bodies = applyLoadedContents(
                    contents,
                    fingerprint: fingerprint,
                    mode: currentMode,
                    baseDisplay: baseDisplay,
                    generation: generation,
                    background: false
                )
                streamBodies(bodies)
            }
        }
    }

    // MARK: - Background refresh (revisit with cached content already shown)

    private func backgroundRefreshIfNeeded() {
        // Never overlap git work: the timer can fire mid-load. Cancelling the
        // in-flight load on every tick meant a git phase slower than the
        // interval restarted forever and never applied — skipping is correct
        // because the in-flight load already covers the refresh.
        guard loadTask == nil else { return }
        // Never reload under unsaved inline edits: setShells rebuilds every
        // editor and would drop them. The timer retries once the user saves.
        guard dirtyPaths.isEmpty else { return }
        watchdogTask?.cancel()
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
            // Also clear any loading flags a superseded apply left behind:
            // bumping the generation above drops its contentReady callback,
            // so without this the tab could stick in "Refreshing…".
            if fingerprint == cachedFingerprint {
                await MainActor.run {
                    if generation == loadGeneration {
                        loadTask = nil
                        isLoading = false
                        isRefreshing = false
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
                // Stale completions must not clear a newer load's task handle.
                defer { if generation == loadGeneration { loadTask = nil } }
                guard generation == loadGeneration, currentMode == mode else { return }
                let bodies = applyLoadedContents(
                    contents,
                    fingerprint: fingerprint,
                    mode: currentMode,
                    baseDisplay: baseDisplay,
                    generation: generation,
                    background: true
                )
                streamBodies(bodies)
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
            // Deferred files were marked non-editable until their content was
            // known; re-gate here with the same strict-UTF-8 rule as the
            // initial payload so saving can never corrupt undecodable bytes.
            let editable = currentMode == .uncommitted
                && file?.status != .deleted
                && GitOperations.isValidUTF8(
                    atPath: (workDir as NSString).appendingPathComponent(filePath)
                )
            return (original, modified, languageId, editable)
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

    /// Build the shell payload for ALL changed files in the given mode.
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

    /// Build both the full diff payload AND the structured, tree-ordered
    /// list of changed files in one pass. The sidebar tree is built from `files`
    /// while the diff webview first renders metadata-only shells derived from
    /// `payload` (see `shells(from:)`) in that same tree order and streams
    /// bodies afterwards; sharing one git read keeps the two in sync and
    /// avoids re-running git for the sidebar. Also returns the base ref the
    /// originals were read from, which identifies viewed marks in
    /// `ChangesViewStateStore`.
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
                // Inline editing is uncommitted-mode only (branch stays a
                // read-only review) and never applies to deletions, which have
                // no modified side. Deferred placeholders start non-editable
                // and are re-gated when their content loads (see onLoadFile).
                "editable": mode == .uncommitted && file.status != .deleted,
            ]

            switch classes[index] {
            case .binary:
                // No content read; diff.js renders a "Binary file (not shown)" badge.
                entry["binary"] = true
                entry["originalText"] = ""
                entry["modifiedText"] = ""
            case .deferred:
                // No content read yet; diff.js renders a click-to-load placeholder.
                // Editing re-enables on upgrade only if the loaded content is
                // strict UTF-8 (see onLoadFile).
                entry["deferred"] = true
                entry["editable"] = false
                entry["originalText"] = ""
                entry["modifiedText"] = ""
            case .normal:
                let lookup = file.oldPath ?? file.relativePath
                let fullPath = (workDir as NSString).appendingPathComponent(file.relativePath)
                let original = file.status == .added ? "" : (originalByLookup[lookup] ?? "")
                let modified: String = {
                    if file.status == .deleted { return "" }
                    // Lossy decode: undecodable bytes become U+FFFD instead of
                    // failing the whole read (which rendered empty diffs).
                    return GitOperations.lossyFileText(atPath: fullPath) ?? ""
                }()
                if exceedsContentLimits(original: original, modified: modified) {
                    // Minified/huge content: demote to click-to-load even
                    // though the line/byte pre-checks passed.
                    entry["deferred"] = true
                    entry["editable"] = false
                    entry["originalText"] = ""
                    entry["modifiedText"] = ""
                } else {
                    entry["originalText"] = original
                    entry["modifiedText"] = modified
                    // Inline editing writes the decoded text back to disk, so it
                    // stays off unless the file round-trips strict UTF-8 — a
                    // lossy save would persist U+FFFD over the original bytes.
                    if mode == .uncommitted && file.status != .deleted {
                        entry["editable"] = GitOperations.isValidUTF8(atPath: fullPath)
                    }
                }
            }

            payload.append(entry)
        }

        return (payload, orderedFiles, baseRef)
    }

    /// Metadata-only shells for one payload: every entry keeps its flags and
    /// counts, but normal files lose their texts and gain `pending: true`.
    /// Shells serialize small and render as cheap DOM, so the tree and the
    /// section headers paint before any Monaco work. Pure (testable).
    nonisolated static func shells(from payload: [[String: Any]]) -> [[String: Any]] {
        payload.map { entry in
            var shell = entry
            let isPlaceholder = entry["binary"] as? Bool == true
                || entry["deferred"] as? Bool == true
            if !isPlaceholder {
                shell["originalText"] = ""
                shell["modifiedText"] = ""
                shell["pending"] = true
            }
            return shell
        }
    }

    /// The entries whose bodies must stream after the shells: every normal
    /// (non-binary, non-deferred) entry with its texts intact. Pure (testable).
    nonisolated static func bodyEntries(from payload: [[String: Any]]) -> [[String: Any]] {
        payload.filter { entry in
            entry["binary"] as? Bool != true && entry["deferred"] as? Bool != true
        }
    }

    /// Current review version per path for a built payload: strong content
    /// hash for entries carrying bodies, weak mtime/size stamp for
    /// binary/deferred placeholders. Pure (testable) so the store prune can
    /// run anywhere.
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
                versions[path] = ChangesViewStateStore.weakVersion(for: file)
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
