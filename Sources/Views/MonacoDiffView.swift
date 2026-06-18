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
    /// Each dict carries: filePath, status, languageId, originalText, modifiedText.
    func setFiles(_ files: [[String: Any]]) {
        enqueue {
            guard let webView = self.webView else { return }
            guard let json = Self.jsonString(from: files) else { return }
            webView.evaluateJavaScript("window.diffAPI.setFiles(\(json))")
        }
    }

    /// Force Monaco to recalculate its layout after reparenting the WKWebView.
    func relayout() {
        enqueue {
            guard let webView = self.webView else { return }
            webView.evaluateJavaScript("window.diffAPI.layout()")
        }
    }

    // MARK: - Ready state

    fileprivate func markReady() {
        isReady = true
        for op in pendingOps {
            op()
        }
        pendingOps.removeAll()
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
