// ABOUTME: Persists per-workstream Changes-tab review state (viewed marks, collapsed files).
// ABOUTME: Viewed marks auto-clear when a file's content version moves (GitHub-style invalidate-on-modify).

import Foundation

/// Persists Changes-tab review state in UserDefaults, keyed by workstream +
/// diff mode. All functions are synchronous and safe to call off the main
/// thread (UserDefaults is thread-safe); values are small string sets.
///
/// Viewed semantics (GitHub-like): marking a file viewed stores a content
/// version stamp alongside the base ref. On the next load, `pruneViewed`
/// drops every mark whose base moved or whose current version differs —
/// covering both new commits (base side) and uncommitted edits (worktree
/// side). Files without readable content (binary/deferred placeholders) use
/// a weak `"<changedLines>:<sizeHint>"` stamp instead of a content hash.
enum ChangesViewStateStore {
    // MARK: - Viewed

    private struct ViewedEntry: Codable {
        /// Content version stamp at mark time (strong hash or weak stamp).
        var version: String
        /// Base ref (merge-base SHA / "HEAD") the mark was made against.
        var base: String
    }

    private static func viewedKey(workstreamID: UUID, mode: String) -> String {
        "factoryfloor.changesViewed.\(workstreamID.uuidString).\(mode)"
    }

    private static func loadViewed(workstreamID: UUID, mode: String) -> [String: ViewedEntry] {
        guard let data = UserDefaults.standard.data(forKey: viewedKey(workstreamID: workstreamID, mode: mode)),
              let decoded = try? JSONDecoder().decode([String: ViewedEntry].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func saveViewed(_ map: [String: ViewedEntry], workstreamID: UUID, mode: String) {
        if map.isEmpty {
            UserDefaults.standard.removeObject(forKey: viewedKey(workstreamID: workstreamID, mode: mode))
        } else if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: viewedKey(workstreamID: workstreamID, mode: mode))
        }
    }

    /// Record or clear a viewed mark. `version` should be the file's current
    /// content stamp (see `ChangesView.contentVersion` or `weakVersion`).
    static func setViewed(
        _ viewed: Bool,
        workstreamID: UUID,
        mode: String,
        base: String,
        path: String,
        version: String
    ) {
        var map = loadViewed(workstreamID: workstreamID, mode: mode)
        if viewed {
            map[path] = ViewedEntry(version: version, base: base)
        } else {
            map.removeValue(forKey: path)
        }
        saveViewed(map, workstreamID: workstreamID, mode: mode)
    }

    /// Drop stale marks and return the surviving viewed paths. A mark survives
    /// only when its base matches AND its version matches `currentVersions`.
    /// Paths absent from `currentVersions` (file no longer changed) are dropped.
    /// - Parameters:
    ///   - currentVersions: path → current stamp (strong hash for loaded
    ///     content, `weakVersion` for placeholders).
    @discardableResult
    static func pruneViewed(
        workstreamID: UUID,
        mode: String,
        base: String,
        currentVersions: [String: String]
    ) -> Set<String> {
        let map = loadViewed(workstreamID: workstreamID, mode: mode)
        guard !map.isEmpty else { return [] }
        var kept: [String: ViewedEntry] = [:]
        for (path, entry) in map {
            guard entry.base == base,
                  let current = currentVersions[path],
                  current == entry.version
            else { continue }
            kept[path] = entry
        }
        if kept.count != map.count {
            saveViewed(kept, workstreamID: workstreamID, mode: mode)
        }
        return Set(kept.keys)
    }

    /// Weak version stamp for files whose content isn't loaded (binary and
    /// deferred placeholders): invalidates the viewed mark when the file's
    /// change size moves, which any edit does.
    static func weakVersion(changedLines: Int, sizeHint: Int) -> String {
        "weak:\(changedLines):\(sizeHint)"
    }

    /// Validate one viewed mark against a freshly loaded version (used when a
    /// deferred file's content arrives after the list-level prune). Clears
    /// stale marks. Returns whether the path counts as viewed now.
    @discardableResult
    static func validateViewed(
        workstreamID: UUID,
        mode: String,
        base: String,
        path: String,
        version: String
    ) -> Bool {
        var map = loadViewed(workstreamID: workstreamID, mode: mode)
        guard let entry = map[path] else { return false }
        guard entry.base == base, entry.version == version else {
            map.removeValue(forKey: path)
            saveViewed(map, workstreamID: workstreamID, mode: mode)
            return false
        }
        return true
    }

    /// Current stored version for one path, if marked viewed.
    static func storedVersion(workstreamID: UUID, mode: String, path: String) -> String? {
        loadViewed(workstreamID: workstreamID, mode: mode)[path]?.version
    }

    // MARK: - Collapsed

    private static func collapsedKey(workstreamID: UUID, mode: String) -> String {
        "factoryfloor.changesCollapsed.\(workstreamID.uuidString).\(mode)"
    }

    /// Persistently collapsed file sections (relative paths).
    static func collapsedSet(workstreamID: UUID, mode: String) -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: collapsedKey(workstreamID: workstreamID, mode: mode)) ?? [])
    }

    static func setCollapsed(_ collapsed: Bool, workstreamID: UUID, mode: String, path: String) {
        var set = collapsedSet(workstreamID: workstreamID, mode: mode)
        if collapsed { set.insert(path) } else { set.remove(path) }
        UserDefaults.standard.set(Array(set), forKey: collapsedKey(workstreamID: workstreamID, mode: mode))
    }

    static func setAllCollapsed(_ collapsed: Bool, workstreamID: UUID, mode: String, paths: [String]) {
        if collapsed {
            UserDefaults.standard.set(
                Array(collapsedSet(workstreamID: workstreamID, mode: mode).union(paths)),
                forKey: collapsedKey(workstreamID: workstreamID, mode: mode)
            )
        } else {
            UserDefaults.standard.set(
                Array(collapsedSet(workstreamID: workstreamID, mode: mode).subtracting(paths)),
                forKey: collapsedKey(workstreamID: workstreamID, mode: mode)
            )
        }
    }
}
