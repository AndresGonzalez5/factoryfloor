// ABOUTME: SwiftUI host for the Changes tab — renders git-derived diffs in Monaco.
// ABOUTME: Phase 0 tracer: loads the FIRST uncommitted file into a single diff editor.

import SwiftUI

/// The Changes tab. Phase 0 renders a single git-derived file diff (Uncommitted
/// mode) to prove the end-to-end path. Modes, refresh, and multi-file payloads
/// arrive in later phases.
struct ChangesView: View {
    let workingDirectory: String
    let projectDirectory: String
    let bridge: MonacoDiffBridge

    var body: some View {
        MonacoDiffView(bridge: bridge)
            .onAppear {
                loadFirstFile()
            }
    }

    /// Compute the first changed file's diff off the main thread, then hand the
    /// payload to the bridge on the main thread.
    private func loadFirstFile() {
        let workingDirectory = workingDirectory
        let bridge = bridge
        DispatchQueue.global(qos: .userInitiated).async {
            guard let file = GitOperations.uncommittedDiffFiles(at: workingDirectory).first else {
                Task { @MainActor in bridge.setFiles([]) }
                return
            }

            let dict = Self.payload(for: file, in: workingDirectory)
            Task { @MainActor in bridge.setFiles([dict]) }
        }
    }

    /// Build the setFiles payload dict for a single file (Phase 0 — Uncommitted mode).
    nonisolated private static func payload(for file: DiffFile, in workingDirectory: String) -> [String: Any] {
        let baseText: String
        let modifiedText: String

        switch file.status {
        case .added:
            baseText = ""
            modifiedText = diskContent(workingDirectory: workingDirectory, relativePath: file.relativePath)
        case .deleted:
            baseText = GitOperations.fileContent(at: workingDirectory, ref: "HEAD", filePath: file.relativePath) ?? ""
            modifiedText = ""
        case .modified, .renamed:
            baseText = GitOperations.fileContent(at: workingDirectory, ref: "HEAD", filePath: file.relativePath) ?? ""
            modifiedText = diskContent(workingDirectory: workingDirectory, relativePath: file.relativePath)
        }

        return [
            "filePath": file.relativePath,
            "status": file.status.rawValue,
            "languageId": MonacoLanguage.id(for: file.relativePath),
            "originalText": baseText,
            "modifiedText": modifiedText,
        ]
    }

    /// Read a worktree file from disk, returning "" if it cannot be read.
    nonisolated private static func diskContent(workingDirectory: String, relativePath: String) -> String {
        let fullPath = (workingDirectory as NSString).appendingPathComponent(relativePath)
        return (try? String(contentsOfFile: fullPath, encoding: .utf8)) ?? ""
    }
}
