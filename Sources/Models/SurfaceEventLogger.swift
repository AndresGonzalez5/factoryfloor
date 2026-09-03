// ABOUTME: Plain-text per-workstream log for terminal surface lifecycle events.
// ABOUTME: Complements LaunchLogger JSON lines; written to <workstream-id>-surface.log when detailedLogging is enabled.

import Foundation
import os

private let surfaceEventConsole = Logger(subsystem: "factoryfloor", category: "surface-cache")

enum SurfaceEventLogger {
    static var logsDirectoryURL: URL {
        LaunchLogger.logsDirectoryURL
    }

    static func logFileURL(for workstreamID: UUID) -> URL {
        logsDirectoryURL.appendingPathComponent("\(workstreamID.uuidString.lowercased())-surface.log")
    }

    /// Console info (always visible) + file append (gated on detailedLogging).
    /// Use for rare, high-signal events: create, replace, remove, close, respawn.
    static func logInfo(workstreamID: UUID, _ message: String) {
        surfaceEventConsole.info("\(message, privacy: .public)")
        append(workstreamID: workstreamID, message: message)
    }

    /// Console debug (gated on detailedLogging) + file append (gated).
    /// Use for frequent events: reuse on every workspace entry, occlusion, resize.
    static func logDetailed(workstreamID: UUID, _ message: String) {
        surfaceEventConsole.detailed(message)
        append(workstreamID: workstreamID, message: message)
    }

    /// Short preview of a (potentially very long) shell command for log lines.
    static func preview(_ command: String?, limit: Int = 160) -> String {
        guard let command, !command.isEmpty else { return "<shell>" }
        let singleLine = command.replacingOccurrences(of: "\n", with: " ")
        guard singleLine.count > limit else { return singleLine }
        return String(singleLine.prefix(limit)) + "…"
    }

    /// Delete the surface log for a workstream. Called during archive cleanup.
    static func removeLog(for workstreamID: UUID) {
        try? FileManager.default.removeItem(at: logFileURL(for: workstreamID))
    }

    // MARK: - Private

    private static func append(workstreamID: UUID, message: String) {
        guard UserDefaults.standard.bool(forKey: "factoryfloor.detailedLogging") else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let line = "\(formatter.string(from: Date())) [\(workstreamID.uuidString.lowercased())] \(message)\n"

        let dir = logsDirectoryURL
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fileURL = logFileURL(for: workstreamID)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                handle.write(Data(line.utf8))
                handle.closeFile()
            }
        } else {
            try? Data(line.utf8).write(to: fileURL, options: .atomic)
        }
    }
}
