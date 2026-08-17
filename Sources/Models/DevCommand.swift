// ABOUTME: Resolves the command that starts a workstream's local dev server.
// ABOUTME: Precedence: .factoryfloor.json run script, user override, package.json dev script.

import Foundation

/// The command that starts a workstream's dev server, and where it came from.
struct DevCommand: Equatable {
    enum Source: String, Equatable {
        /// run script from .factoryfloor.json (or fallback config). Still approval-gated.
        case configScript
        /// Per-workstream command saved by the user in the Environment pane.
        case override
        /// Auto-detected dev script from the repository's package.json.
        case packageJSON
    }

    let command: String
    let source: Source
    let sourceDescription: String?
}

enum DevCommandResolver {
    private static let overrideKeyPrefix = "factoryfloor.devCommand."

    // MARK: - Per-workstream override

    static func overrideKey(for workstreamID: UUID) -> String {
        overrideKeyPrefix + workstreamID.uuidString.lowercased()
    }

    static func savedOverride(for workstreamID: UUID) -> String? {
        guard let value = UserDefaults.standard.string(forKey: overrideKey(for: workstreamID)),
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return value
    }

    static func saveOverride(_ command: String?, for workstreamID: UUID) {
        guard let command, !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            UserDefaults.standard.removeObject(forKey: overrideKey(for: workstreamID))
            return
        }
        UserDefaults.standard.set(command, forKey: overrideKey(for: workstreamID))
    }

    // MARK: - Resolution

    /// Resolution order: config run script > user override > package.json dev script.
    /// `override` is the per-workstream override already loaded by the caller.
    static func resolve(
        scriptConfig: ScriptConfig,
        workstreamID: UUID,
        workingDirectory: String,
        override: String?
    ) -> DevCommand? {
        if let run = scriptConfig.run {
            return DevCommand(command: run, source: .configScript, sourceDescription: scriptConfig.source)
        }
        if let override, !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return DevCommand(command: override, source: .override, sourceDescription: nil)
        }
        return detectPackageScript(in: workingDirectory)
    }

    // MARK: - package.json detection

    /// The dev command from the repository's package.json, if it has a dev script.
    static func detectPackageScript(in directory: String) -> DevCommand? {
        guard let script = devScript(in: directory) else { return nil }
        let manager = packageManager(in: directory)
        return DevCommand(
            command: "\(manager) run \(script)",
            source: .packageJSON,
            sourceDescription: "package.json"
        )
    }

    /// The package manager to use, inferred from lockfiles. Defaults to npm.
    static func packageManager(in directory: String) -> String {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: directory)
        if fm.fileExists(atPath: url.appendingPathComponent("bun.lock").path)
            || fm.fileExists(atPath: url.appendingPathComponent("bun.lockb").path) {
            return "bun"
        }
        if fm.fileExists(atPath: url.appendingPathComponent("pnpm-lock.yaml").path) {
            return "pnpm"
        }
        if fm.fileExists(atPath: url.appendingPathComponent("yarn.lock").path) {
            return "yarn"
        }
        return "npm"
    }

    /// The name of the `dev` script in package.json, if any.
    static func devScript(in directory: String) -> String? {
        let url = URL(fileURLWithPath: directory).appendingPathComponent("package.json")
        guard let data = FileManager.default.contents(atPath: url.path),
              let json = try? JSONSerialization.jsonObject(with: data),
              let dict = json as? [String: Any],
              let scripts = dict["scripts"] as? [String: Any],
              let dev = scripts["dev"] as? String,
              !dev.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return "dev"
    }
}