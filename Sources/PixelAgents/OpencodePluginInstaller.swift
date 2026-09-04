// ABOUTME: Installs the Factory Floor OpenCode plugin into ~/.config/opencode/plugins.
// ABOUTME: Idempotent — rewrites only when the bundled plugin version changes.

import Foundation
import os

private let logger = Logger(subsystem: "factoryfloor", category: "opencode-plugin-installer")

enum OpencodePluginInstaller {

    /// Bump when the bundled factoryfloor-opencode.js changes so existing installs refresh.
    /// v4: tool hooks + context reporting; v5-v8: subtask descriptions, inline roster title.
    /// v9: remove debug file logging, deduplicate description handling.
    /// v10: session_id on all payloads, question-tool user-waiting signal,
    /// session_switched reset, bus/direct tool-event dedupe, per-session info fingerprint.
    private static let pluginVersion = 10

    private static var pluginsDirectory: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/opencode/plugins").path
    }

    private static var installPath: String {
        pluginsDirectory.appending("/factoryfloor.js")
    }

    // MARK: - Install

    /// Copies the bundled plugin into the user's global opencode plugin directory.
    /// - Parameter bundledPath: Absolute path to `factoryfloor-opencode.js` in the app bundle.
    static func install(bundledPath: String) {
        let fm = FileManager.default
        guard let bundled = fm.contents(atPath: bundledPath), !bundled.isEmpty else {
            logger.warning("Bundled opencode plugin missing at \(bundledPath, privacy: .public)")
            return
        }

        let versioned = """
        // FACTORYFLOOR_OPENCODE_PLUGIN version=\(pluginVersion)
        \(String(decoding: bundled, as: UTF8.self))
        """

        if let existing = try? String(contentsOfFile: installPath, encoding: .utf8),
           existing.contains("FACTORYFLOOR_OPENCODE_PLUGIN"),
           existing.contains("version=\(pluginVersion)")
        {
            return
        }

        try? fm.createDirectory(atPath: pluginsDirectory, withIntermediateDirectories: true)

        do {
            try versioned.write(toFile: installPath, atomically: true, encoding: .utf8)
            logger.info("Installed Factory Floor opencode plugin (v\(Self.pluginVersion))")
        } catch {
            logger.error("Failed to write opencode plugin: \(error.localizedDescription)")
        }
    }
}
