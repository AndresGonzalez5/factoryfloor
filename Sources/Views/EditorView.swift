// ABOUTME: Embedded code editor with a file tree sidebar for navigating the worktree.
// ABOUTME: Uses Monaco editor in a shared WKWebView via MonacoEditorBridge for syntax highlighting.

import SwiftUI
import WebKit

struct EditorView: View {
    let workingDirectory: String
    let fileTree: [FileNode]
    let gitStatus: GitFileStatusProvider
    let initialFilePath: String?
    let bridge: MonacoEditorBridge
    let modelId: String
    @Binding var isDirtyState: Bool
    var onFileChanged: ((String?) -> Void)?
    var onExpandFolder: ((String) -> Void)?
    /// Incremented by the workspace when the user presses Cmd+P while this
    /// editor tab is active; each change opens the file finder.
    var fileFinderRequest: Int = 0

    // Current file state
    @State private var currentFilePath: String?
    @State private var fileLoaded = false
    @State private var loadError: String?
    @State private var filePathCopied = false

    /// File tree visibility
    @State private var showFileTree = true

    // File finder (quick open)
    @State private var isFinderOpen = false
    @State private var finderQuery = ""
    @State private var finderSelection: Int?
    @State private var fileIndex: [FileFinder.Entry] = []
    @State private var finderResults: [String] = []
    @State private var isScanningFiles = false
    @State private var finderKeyMonitor: Any?
    @FocusState private var finderFieldFocused: Bool

    // Save confirmation for file switching
    @State private var pendingFilePath: String?
    @State private var showSaveAlert = false

    private var isDirty: Bool {
        isDirtyState
    }

    private var currentFileName: String {
        guard let path = currentFilePath else { return "file" }
        return (path as NSString).lastPathComponent
    }

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                if showFileTree {
                    fileTreePanel
                        .frame(width: 220)
                    Divider()
                }
                VStack(spacing: 0) {
                    editorToolbar
                    editorPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            if isFinderOpen {
                finderOverlay
                    .padding(.top, 44)
            }
        }
        .onAppear {
            if let initialFilePath, currentFilePath == nil {
                navigateToFile(initialFilePath)
            } else if fileLoaded {
                bridge.switchModel(modelId: modelId)
            }
        }
        .onDisappear {
            closeFileFinder()
        }
        .onChange(of: fileFinderRequest) { _, _ in
            openFileFinder()
        }
        .onChange(of: finderQuery) { _, newQuery in
            print("[FF] query -> \(newQuery)")
            refreshFinderResults()
        }
        .alert(
            Text(String(
                format: NSLocalizedString("Do you want to save changes to \"%@\"?", comment: ""),
                currentFileName
            )),
            isPresented: $showSaveAlert
        ) {
            Button(NSLocalizedString("Save", comment: "")) {
                Task {
                    await saveFile()
                    if let pending = pendingFilePath {
                        navigateToFile(pending)
                    }
                    pendingFilePath = nil
                }
            }
            Button(NSLocalizedString("Don't Save", comment: ""), role: .destructive) {
                if let pending = pendingFilePath {
                    navigateToFile(pending)
                }
                pendingFilePath = nil
            }
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) {
                pendingFilePath = nil
            }
        } message: {
            Text("Your changes will be lost if you don't save them.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveEditor)) { _ in
            Task { await saveFile() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveEditorAs)) { _ in
            Task { await saveFileAs() }
        }
    }

    // MARK: - Editor Toolbar

    private var editorToolbar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showFileTree.toggle()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .foregroundStyle(showFileTree ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle file tree")

            Button {
                openFileFinder()
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(isFinderOpen ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(NSLocalizedString("Find File (\u{2318}P)", comment: ""))

            if let currentFilePath {
                HStack(spacing: 6) {
                    Text((currentFilePath as NSString).lastPathComponent)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    copyFilePathButton
                }
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    /// Copies the current file's relative path and flashes a checkmark as
    /// confirmation.
    @ViewBuilder
    private var copyFilePathButton: some View {
        Group {
            if filePathCopied {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
                    .help(Text("File path copied"))
                    .accessibilityLabel(Text("File path copied"))
            } else {
                Button {
                    guard let path = currentFilePath else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                    filePathCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        filePathCopied = false
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(Text("Copy File Path"))
                .accessibilityLabel(Text("Copy File Path"))
            }
        }
        .animation(.easeInOut(duration: 0.12), value: filePathCopied)
    }

    // MARK: - File Tree Panel

    private var fileTreePanel: some View {
        FileTreeView(nodes: fileTree, selectedPath: currentFilePath, gitStatus: gitStatus) { selectedPath in
            handleFileSelection(selectedPath)
        } onExpandFolder: { path in
            onExpandFolder?(path)
        }
    }

    // MARK: - Editor Panel

    /// MonacoEditorView is ALWAYS in the tree so the WKWebView starts loading
    /// immediately when the editor tab opens (before the user picks a file).
    /// Placeholder and error states overlay on top with opaque backgrounds.
    private var editorPanel: some View {
        ZStack {
            MonacoEditorView(bridge: bridge)
            if currentFilePath == nil {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text("Select a file to edit")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            } else if let loadError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundStyle(.tertiary)
                    Text(loadError)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            }
        }
    }

    // MARK: - File Finder

    private var finderOverlay: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField(
                    NSLocalizedString("Search files by name", comment: ""),
                    text: $finderQuery
                )
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($finderFieldFocused)
                if isScanningFiles {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Divider()

            if finderResults.isEmpty {
                if isScanningFiles {
                    Text(NSLocalizedString("Scanning files…", comment: ""))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if !finderQuery.isEmpty {
                    Text(NSLocalizedString("No files found", comment: ""))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Rows are identified by their POSITION, so SwiftUI
                            // can never render stale content for an index: row
                            // content is a pure function of the current array.
                            // (Using the path string as ForEach id AND .id() on
                            // rows caused two competing identity systems and
                            // desynced rendering in the lazy container.)
                            ForEach(Array(finderResults.enumerated()), id: \.offset) { index, path in
                                finderRow(path: path, index: index)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: finderSelection) { _, newValue in
                        guard let newValue else { return }
                        withAnimation(nil) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
            // Debug telemetry: makes the query/results state visible so any
            // divergence between what is typed and what is searched is obvious.
            Text("'\(finderQuery)' -> \(finderResults.count) results" +
                 (finderResults.first.map { " | \($0)" } ?? ""))
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
        }
        .frame(width: 480)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }

    private func finderRow(path: String, index: Int) -> some View {
        let isSelected = index == finderSelection
        let name = (path as NSString).lastPathComponent
        let dir = (path as NSString).deletingLastPathComponent
        let icon = FileTypeIcon.icon(for: name)

        return HStack(spacing: 6) {
            Image(systemName: icon.symbolName)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(name)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .lineLimit(1)
            if !dir.isEmpty {
                Text(dir)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.18) : .clear)
        .onTapGesture {
            selectFinderResult(at: index)
        }
    }

    private func openFileFinder() {
        isFinderOpen = true
        finderQuery = ""
        finderResults = []
        finderSelection = nil
        installFinderKeyMonitor()
        DispatchQueue.main.async {
            finderFieldFocused = true
        }
        scanFinderFiles()
    }

    private func closeFileFinder() {
        isFinderOpen = false
        finderFieldFocused = false
        if let monitor = finderKeyMonitor {
            NSEvent.removeMonitor(monitor)
            finderKeyMonitor = nil
        }
    }

    /// The finder's query is driven entirely by this local key monitor, not by
    /// the TextField's first-responder editing. This makes the query a faithful
    /// replay of the exact keys pressed regardless of focus state, field editor
    /// quirks, or SwiftUI binding timing — the field is a pure display.
    /// arrow/return/escape keys are intercepted here (field editor would consume
    /// them before SwiftUI's focus system).
    private func installFinderKeyMonitor() {
        guard finderKeyMonitor == nil else { return }
        finderKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isFinderOpen else { return event }
            if let chars = event.charactersIgnoringModifiers {
                switch chars {
                case "\u{1b}": // Escape
                    self.closeFileFinder()
                    return nil
                case "\r", "\n": // Return
                    self.openSelectedFinderResult()
                    return nil
                case "\u{F700}", "\u{F701}": // Up / Down arrow
                    self.moveFinderSelection(chars == "\u{F700}" ? -1 : 1)
                    return nil
                case "\u{7f}", "\u{08}": // Delete / Backspace
                    if !self.finderQuery.isEmpty {
                        self.finderQuery.removeLast()
                    }
                    return nil
                default:
                    let flags = event.modifierFlags
                    if flags.contains(.command), chars.lowercased() == "v" {
                        self.appendPasteboardText()
                        return nil
                    }
                    // Plain printable characters: append and never let them
                    // reach the field editor (which would double-insert).
                    if flags.intersection([.command, .option, .control]).isEmpty, !chars.isEmpty {
                        self.finderQuery.append(chars)
                        return nil
                    }
                    return event
                }
            }
            return event
        }
    }

    private func appendPasteboardText() {
        guard let text = NSPasteboard.general.string(forType: .string) else { return }
        finderQuery.append(text.replacingOccurrences(of: "\n", with: " "))
    }

    private func scanFinderFiles() {
        isScanningFiles = true
        fileIndex = []
        finderResults = []
        let root = workingDirectory
        let ignored = gitStatus
        DispatchQueue.global(qos: .userInitiated).async {
            let scanned = FileFinder.scanFiles(at: root)
            let visible = scanned.filter { !ignored.isIgnored($0.path) }
            DispatchQueue.main.async {
                self.fileIndex = visible
                self.isScanningFiles = false
                print("[FF] scan done: \(visible.count) files")
                self.refreshFinderResults()
            }
        }
    }

    /// Synchronously recompute the displayed results from the current query.
    /// Matching is allocation-free and fast enough (milliseconds) that this can
    /// run on every keystroke; the displayed list can never be stale.
    private func refreshFinderResults() {
        let results = FileFinder.results(matching: finderQuery, in: fileIndex)
        finderResults = results
        finderSelection = results.isEmpty ? nil : 0
        print("[FF] refresh(\(finderQuery)) -> \(results.prefix(3).map { ($0 as NSString).lastPathComponent }.joined(separator: ", "))")
    }

    private func moveFinderSelection(_ delta: Int) {
        guard !finderResults.isEmpty else { return }
        let current = finderSelection ?? (delta > 0 ? -1 : finderResults.count)
        finderSelection = min(max(current + delta, 0), finderResults.count - 1)
    }

    private func openSelectedFinderResult() {
        // Results are always current (recomputed synchronously on every
        // keystroke); never re-compute here — refreshFinderResults() resets the
        // selection to 0 and would ignore a selection moved with the arrows.
        guard let index = finderSelection, index < finderResults.count else { return }
        selectFinderResult(at: index)
    }

    private func selectFinderResult(at index: Int) {
        guard index < finderResults.count else { return }
        let path = finderResults[index]
        closeFileFinder()
        handleFileSelection(path)
    }

    // MARK: - Navigation

    private func handleFileSelection(_ path: String) {
        guard path != currentFilePath else { return }

        if isDirty {
            pendingFilePath = path
            showSaveAlert = true
        } else {
            navigateToFile(path)
        }
    }

    private func navigateToFile(_ relativePath: String) {
        // Don't toggle fileLoaded — MonacoEditorView must stay in the tree.
        // Just clear errors and update the path; loadFile() will push new content.
        loadError = nil
        isDirtyState = false

        currentFilePath = relativePath
        onFileChanged?(relativePath)

        loadFile()
    }

    // MARK: - File I/O

    private func loadFile() {
        guard let relativePath = currentFilePath else { return }
        let fullPath = (workingDirectory as NSString).appendingPathComponent(relativePath)
        let url = URL(fileURLWithPath: fullPath)

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let fileName = (relativePath as NSString).lastPathComponent
            let langId = Self.monacoLanguageId(for: fileName)
            bridge.openFile(modelId: modelId, text: content, languageId: langId, filePath: fullPath)
            isDirtyState = false
            fileLoaded = true
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveFile() async {
        guard let relativePath = currentFilePath, fileLoaded, isDirty else { return }
        let fullPath = (workingDirectory as NSString).appendingPathComponent(relativePath)
        guard let content = await bridge.getContent(modelId: modelId) else { return }
        do {
            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
            bridge.markClean(modelId: modelId)
            isDirtyState = false

        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveFileAs() async {
        guard fileLoaded else { return }
        guard let content = await bridge.getContent(modelId: modelId) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = currentFileName
        if let currentFilePath {
            let fullPath = (workingDirectory as NSString).appendingPathComponent(currentFilePath)
            panel.directoryURL = URL(fileURLWithPath: fullPath).deletingLastPathComponent()
        }

        guard let window = NSApp.keyWindow else { return }
        let response = await panel.beginSheetModal(for: window)
        guard response == .OK, let url = panel.url else { return }

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            bridge.markClean(modelId: modelId)
            isDirtyState = false

        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Language Detection

    private static func monacoLanguageId(for fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "mjs", "cjs": return "javascript"
        case "ts", "mts", "cts": return "typescript"
        case "tsx": return "typescriptreact"
        case "jsx": return "javascriptreact"
        case "py": return "python"
        case "rs": return "rust"
        case "go": return "go"
        case "rb": return "ruby"
        case "json": return "json"
        case "jsonc": return "jsonc"
        case "yaml", "yml": return "yaml"
        case "toml": return "toml"
        case "md", "markdown": return "markdown"
        case "html", "htm": return "html"
        case "css": return "css"
        case "scss": return "scss"
        case "less": return "less"
        case "sh", "bash", "zsh": return "shellscript"
        case "xml", "plist": return "xml"
        case "sql": return "sql"
        case "c", "h": return "c"
        case "cpp", "cc", "cxx", "hpp": return "cpp"
        case "m": return "objective-c"
        case "java": return "java"
        case "kt", "kts": return "kotlin"
        case "php": return "php"
        case "r": return "r"
        case "lua": return "lua"
        case "dart": return "dart"
        case "dockerfile": return "dockerfile"
        case "diff", "patch": return "diff"
        case "ini", "cfg": return "ini"
        case "bat", "cmd": return "bat"
        case "ps1": return "powershell"
        case "graphql", "gql": return "graphql"
        default:
            let name = fileName.lowercased()
            switch name {
            case "makefile", "gnumakefile": return "makefile"
            case "dockerfile": return "dockerfile"
            default: return "plaintext"
            }
        }
    }
}
