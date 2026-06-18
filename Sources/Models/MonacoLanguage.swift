// ABOUTME: Maps a filename/extension to a Monaco language identifier.
// ABOUTME: Phase 0 stub — a minimal set of mappings; the full table lands in Phase 2.

import Foundation

/// Resolves a Monaco language id (e.g. "swift", "json") from a file name.
/// Unknown files fall back to "plaintext".
enum MonacoLanguage {
    /// Returns the Monaco language id for the given file name (last path component is fine).
    static func id(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "mjs", "cjs", "jsx": return "javascript"
        case "ts", "tsx": return "typescript"
        case "json": return "json"
        case "md", "markdown": return "markdown"
        default: return "plaintext"
        }
    }
}
