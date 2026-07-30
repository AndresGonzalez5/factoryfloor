// ABOUTME: Records which repository-provided setup/run/teardown commands the user has approved.
// ABOUTME: Approval is bound to the command text, so an edited config has to be approved again.

import CryptoKit
import Foundation

enum ScriptTrust {
    private static let userDefaultsKey = "factoryfloor.approvedScripts"

    /// Identifies the executable content of a config. Any change to a command,
    /// to the role a command sits in, or to the file it was read from produces a
    /// different value.
    static func fingerprint(_ config: ScriptConfig) -> String {
        let canonical = [
            config.source ?? "",
            config.setup ?? "",
            config.run ?? "",
            config.teardown ?? "",
        ].joined(separator: "\u{1}")
        let digest = SHA256.hash(data: Data(canonical.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Whether the commands in this config may run for this project.
    /// A config that carries no commands has nothing to approve.
    static func isApproved(_ config: ScriptConfig, for projectDirectory: String) -> Bool {
        guard config.hasAnyScript else { return true }
        return approvals()[projectDirectory] == fingerprint(config)
    }

    static func approve(_ config: ScriptConfig, for projectDirectory: String) {
        var current = approvals()
        current[projectDirectory] = fingerprint(config)
        save(current)
    }

    static func revoke(for projectDirectory: String) {
        var current = approvals()
        guard current.removeValue(forKey: projectDirectory) != nil else { return }
        save(current)
    }

    // MARK: - Storage

    private static func approvals() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func save(_ approvals: [String: String]) {
        guard let data = try? JSONEncoder().encode(approvals) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
