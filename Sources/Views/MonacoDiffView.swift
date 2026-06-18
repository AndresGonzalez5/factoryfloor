// ABOUTME: WKWebView bridge + NSViewRepresentable for the Monaco stacked-diff view.
// ABOUTME: One WKWebView per workstream; renders a vertical stack of inline diff editors.

import Cocoa
import SwiftUI
import WebKit

// MARK: - MonacoDiffBridge

/// Manages a single WKWebView that loads diff.html and renders a stack of Monaco
/// diff editors. Reuses MonacoResourceSchemeHandler + EditorWebView from the editor
/// pipeline. Queues operations until diff.js posts "ready". All calls on @MainActor.
@MainActor
final class MonacoDiffBridge: ObservableObject {
    private(set) var webView: EditorWebView?
    private(set) var isReady = false
    private var pendingOps: [() -> Void] = []
    private var coordinator: Coordinator?
    private var appearanceObserver: NSKeyValueObservation?

    /// Fired when diff.js reports all editors have finished rendering ("contentReady").
    /// ChangesView uses this to drop its loading / refreshing indicator.
    var onContentReady: (() -> Void)?

    /// Resolves the (original, modified, languageId) content for a single deferred
    /// file when its placeholder is clicked. Invoked off the main thread.
    /// ChangesView installs this so the bridge has the current workDir + base ref.
    var onLoadFile: ((_ filePath: String) -> (original: String, modified: String, languageId: String))?

    /// Git fingerprint from the last successful setFiles() call. ChangesView uses
    /// it to skip reloading when nothing in git has changed between tab visits.
    var lastFingerprint: String?

    /// The mode ("branch"/"uncommitted") that was active for the last load.
    var lastMode: String?

    /// Number of files from the last setFiles() call. Stored here (not @State) so
    /// it survives the SwiftUI view being re-created on a tab switch.
    var lastFileCount = 0

    /// Structured changed-file list from the last load. Cached here (not @State)
    /// so the Changes sidebar tree survives the SwiftUI view being re-created on
    /// a tab switch, matching `lastFileCount`/`hasContent`.
    var lastDiffFiles: [DiffFile] = []

    /// Whether setFiles() has run at least once (cached content lives in the WebView).
    private(set) var hasContent = false

    // MARK: - WebView lifecycle

    /// Lazily creates the WKWebView and starts loading diff.html.
    func ensureWebView() -> EditorWebView {
        if let webView { return webView }

        let coord = Coordinator(bridge: self)
        coordinator = coord

        let contentController = WKUserContentController()
        // diff.js posts via window.webkit.messageHandlers.editor — same handler
        // name as the editor pipeline (each WebView has its own controller).
        contentController.add(coord, name: "editor")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        if let resourceURL = Bundle.main.resourceURL {
            let bundleURL = resourceURL.appendingPathComponent("MonacoEditor")
            let handler = MonacoResourceSchemeHandler(baseURL: bundleURL)
            config.setURLSchemeHandler(handler, forURLScheme: "ff-resource")
        }

        let wv = EditorWebView(frame: .zero, configuration: config)
        wv.underPageBackgroundColor = .windowBackgroundColor
        #if DEBUG
            wv.isInspectable = true
        #endif

        if let url = URL(string: "ff-resource://monaco/diff.html") {
            wv.load(URLRequest(url: url))
        }

        webView = wv
        return wv
    }

    // MARK: - Diff API

    /// Render the given files as a stack of Monaco diff editors.
    /// Each dict carries: filePath, status, languageId, originalText, modifiedText,
    /// and optionally binary/deferred/changedLines for the placeholder cases.
    func setFiles(_ files: [[String: Any]]) {
        hasContent = true
        enqueue {
            guard let webView = self.webView else { return }
            guard let json = Self.jsonString(from: files) else { return }
            webView.evaluateJavaScript("window.diffAPI.setFiles(\(json))")
        }
    }

    /// Inject the loaded content for a previously-deferred file, replacing its
    /// placeholder with a real diff editor in place (no full re-render).
    func loadFileContent(filePath: String, originalText: String, modifiedText: String, languageId: String) {
        enqueue {
            guard let webView = self.webView else { return }
            let payload: [String: Any] = [
                "filePath": filePath,
                "originalText": originalText,
                "modifiedText": modifiedText,
                "languageId": languageId,
            ]
            guard let json = Self.jsonString(from: payload) else { return }
            webView.evaluateJavaScript("window.diffAPI.loadFileContent(\(json))")
        }
    }

    /// Clear all diffs.
    func clear() {
        enqueue {
            guard let webView = self.webView else { return }
            webView.evaluateJavaScript("window.diffAPI.clear()")
        }
    }

    /// Switch the Monaco color theme to match the host appearance.
    func setTheme(isDark: Bool) {
        enqueue {
            guard let webView = self.webView else { return }
            webView.evaluateJavaScript("window.diffAPI.setTheme(\(isDark))")
        }
    }

    /// Force Monaco to recalculate its layout after reparenting the WKWebView.
    func relayout() {
        enqueue {
            guard let webView = self.webView else { return }
            webView.evaluateJavaScript("window.diffAPI.layout()")
        }
    }

    /// Scroll the diff page so the given file's section is at the top. Queues
    /// until the webview is ready, mirroring the other bridge calls. Works for
    /// normal, binary, and deferred files (each registers a section element).
    func scrollToFile(_ path: String) {
        enqueue {
            guard let webView = self.webView else { return }
            guard let json = Self.jsonString(fromString: path) else { return }
            webView.evaluateJavaScript("window.diffAPI.scrollToFile(\(json))")
        }
    }

    // MARK: - Ready state

    fileprivate func markReady() {
        isReady = true
        injectLocalizedStrings()
        syncThemeWithAppearance()
        startAppearanceObservation()
        for op in pendingOps {
            op()
        }
        pendingOps.removeAll()
    }

    /// Hand the localized placeholder/empty-state strings to diff.js so the
    /// "Binary file (not shown)" and "Large file — %d changes…" labels are
    /// localized rather than the English fallbacks baked into the bundle.
    private func injectLocalizedStrings() {
        guard let webView else { return }
        let strings: [String: String] = [
            "binary": NSLocalizedString("Binary file (not shown)", comment: "Changes tab: binary file placeholder"),
            "largeFile": NSLocalizedString(
                "Large file — %d changes, click to load",
                comment: "Changes tab: large-file click-to-load placeholder"
            ),
            "noChanges": NSLocalizedString("No changes", comment: "Changes tab: empty state"),
        ]
        guard let json = Self.jsonString(from: strings) else { return }
        webView.evaluateJavaScript("window.diffAPI.setStrings(\(json))")
    }

    fileprivate func contentReady() {
        onContentReady?()
    }

    /// Resolve content for a deferred file off the main thread, then inject it.
    fileprivate func handleLoadFile(_ filePath: String) {
        guard let resolver = onLoadFile else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let (original, modified, languageId) = resolver(filePath)
            DispatchQueue.main.async {
                self.loadFileContent(
                    filePath: filePath,
                    originalText: original,
                    modifiedText: modified,
                    languageId: languageId
                )
            }
        }
    }

    // MARK: - Theme

    private func syncThemeWithAppearance() {
        let isDark = NSApp?.effectiveAppearance.isDark ?? true
        guard let webView else { return }
        webView.evaluateJavaScript("window.diffAPI.setTheme(\(isDark))")
    }

    private func startAppearanceObservation() {
        guard appearanceObserver == nil else { return }
        appearanceObserver = NSApplication.shared.observe(
            \.effectiveAppearance,
            options: [.new]
        ) { [weak self] _, _ in
            Task { @MainActor in
                self?.syncThemeWithAppearance()
            }
        }
    }

    // MARK: - Private

    private func enqueue(_ op: @escaping @MainActor () -> Void) {
        if isReady {
            op()
        } else {
            pendingOps.append(op)
        }
    }

    /// Serialize a JSON-compatible value into a JavaScript-safe JSON string.
    /// JSONSerialization escapes all content (quotes, backticks, newlines, unicode).
    private static func jsonString(from value: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value),
              let json = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return json
    }

    /// JSON-encode a bare string into a JS-safe quoted literal (e.g. a file
    /// path passed as a function argument). `.fragmentsAllowed` lets us encode a
    /// top-level string, which `isValidJSONObject` would otherwise reject.
    private static func jsonString(fromString value: String) -> String? {
        guard let data = try? JSONSerialization.data(
            withJSONObject: value,
            options: [.fragmentsAllowed]
        ), let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKScriptMessageHandler, @unchecked Sendable {
        private let bridge: MonacoDiffBridge

        init(bridge: MonacoDiffBridge) {
            self.bridge = bridge
        }

        nonisolated func userContentController(
            _: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            Task { @MainActor in
                guard let body = message.body as? [String: Any],
                      let type = body["type"] as? String else { return }

                switch type {
                case "ready":
                    self.bridge.markReady()
                case "contentReady":
                    self.bridge.contentReady()
                case "loadFile":
                    if let filePath = body["filePath"] as? String {
                        self.bridge.handleLoadFile(filePath)
                    }
                case "error":
                    if let msg = body["message"] as? String {
                        print("[MonacoDiff] JS error: \(msg)")
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - MonacoDiffView

/// NSViewRepresentable that reparents the diff WKWebView into its container.
/// The WKWebView is created lazily on first update so it has a real frame.
struct MonacoDiffView: NSViewRepresentable {
    let bridge: MonacoDiffBridge

    func makeNSView(context _: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        return container
    }

    func updateNSView(_ container: NSView, context _: Context) {
        let webView = bridge.ensureWebView()

        if webView.superview !== container {
            webView.removeFromSuperview()
            container.subviews.forEach { $0.removeFromSuperview() }
            container.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: container.topAnchor),
                webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
            DispatchQueue.main.async {
                self.bridge.relayout()
            }
        }
    }
}
