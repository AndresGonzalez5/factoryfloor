// ABOUTME: Maps a filename/extension to a Monaco language identifier.
// ABOUTME: Shared between the Editor and the Changes (diff) view.

import Foundation

/// Resolves a Monaco language id (e.g. "swift", "json") from a file name.
/// Unknown files fall back to "plaintext". The last path component is fine.
enum MonacoLanguage {
    /// Returns the Monaco language id for the given file name.
    static func id(for fileName: String) -> String {
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
        case "diff", "patch": return "diff"
        case "ini", "cfg": return "ini"
        case "bat", "cmd": return "bat"
        case "ps1": return "powershell"
        case "graphql", "gql": return "graphql"
        default:
            let name = (fileName as NSString).lastPathComponent.lowercased()
            switch name {
            case "makefile", "gnumakefile": return "makefile"
            case "dockerfile": return "dockerfile"
            default: return "plaintext"
            }
        }
    }
}
