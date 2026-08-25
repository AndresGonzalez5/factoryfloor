// ABOUTME: Loads agent avatar images for the sidebar roster.
// ABOUTME: Prefers numbered per-type sprite sets (avatar_<type>_<k>.png) that
// ABOUTME: cycle across concurrent same-type agents, with single-file, palette
// ABOUTME: slot, and legacy sheet fallbacks.

import AppKit

/// Provides a small square portrait for each agent run.
///
/// Asset resolution order (all in `Resources/AgentSprites/`):
/// 1. **Numbered per-type set** — `avatar_<type>_1.png`, `avatar_<type>_2.png`,
///    … The run's variant index (assigned by the tracker as the lowest index
///    not held by a live same-type run) selects `set[variant % count]`, so
///    concurrent same-type agents get distinct characters and cycle only when
///    over capacity. `<type>` is the agent type normalized to lowercase
///    alphanumerics ("general-purpose" → "generalpurpose").
/// 2. **Single type portrait** — `avatar_<type>.png` (types without variants).
/// 3. **Palette slot** — `avatar_<n>.png` (0-5).
///
/// Portraits are 64×64 pixels sized to 32pt; views render them with
/// `.resizable()` + `.interpolation(.none)` to keep pixels crisp. Types with
/// no art at all return nil — views substitute a neutral SF Symbol placeholder.
@MainActor
final class AgentSpriteStore {

    static let shared = AgentSpriteStore()

    /// Number of distinct palettes (0 is the main agent).
    static let paletteCount = 6

    /// Sprite-set aliases: agent type names without their own sprite files
    /// reuse an existing set. OpenCode ships `build`/`plan` primaries and
    /// `general`/`explore`/`scout` subagents; Claude Code uses
    /// `explore`/`general-purpose`/`plan`. A type's own art always wins —
    /// aliases only fill gaps (drop `avatar_<type>_1.png` to override).
    private static let typeAliases: [String: String] = [
        "build": "claude",
        "code": "claude",
        "general": "generalpurpose",
        "ask": "explore",
        "scout": "explore",
    ]

    /// Point size the avatars are normalized to.
    static let pointSize = CGSize(width: 32, height: 32)

    /// Maps a normalized type key to its numbered sprite file names, sorted by index.
    private var typeSets: [String: [String]]?
    private var cache: [String: NSImage?] = [:]

    private init() {}

    /// Returns the portrait for an agent run, or nil when no asset could be loaded.
    func avatar(name: String?, palette: Int, variant: Int = 0) -> NSImage? {
        let slot = ((palette % Self.paletteCount) + Self.paletteCount) % Self.paletteCount

        if let name, !name.isEmpty {
            let normalized = Self.normalizeTypeName(name)
            for key in Self.resolutionKeys(for: normalized) {
                if let file = spriteFile(for: key, variant: variant),
                   let image = cachedLookup("file:\(file)", resource: file)
                {
                    return image
                }
                if let image = cachedLookup("type:\(key)", resource: "avatar_\(key)") {
                    return image
                }
            }
        }
        if let image = cachedLookup("slot:\(slot)", resource: "avatar_\(slot)") {
            return image
        }
        return nil
    }

    /// Keys to try for a normalized type name, in order: the type itself
    /// first (so dedicated art overrides aliases), then its alias, if any.
    static func resolutionKeys(for normalizedType: String) -> [String] {
        guard !normalizedType.isEmpty else { return [] }
        var keys = [normalizedType]
        if let alias = typeAliases[normalizedType], alias != normalizedType {
            keys.append(alias)
        }
        return keys
    }

    // MARK: - Sprite Sets

    /// Picks the sprite file for a type and variant: `set[variant % count]`
    /// when the type has a numbered set, nil otherwise.
    func spriteFile(for typeKey: String, variant: Int) -> String? {
        let set = typeSet(for: typeKey)
        guard !set.isEmpty else { return nil }
        return set[Self.spriteVariantIndex(variant: variant, count: set.count)]
    }

    /// Variant index wrapped into the available sprite count.
    static func spriteVariantIndex(variant: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((variant % count) + count) % count
    }

    /// Enumerates `avatar_<type>_<k>.png` resources once, building a
    /// type → sorted file names map. Numbering is 1-based.
    private func typeSet(for typeKey: String) -> [String] {
        if let sets = typeSets { return sets[typeKey] ?? [] }

        let urls = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "AgentSprites") ?? []
        var sets: [String: [(index: Int, file: String)]] = [:]
        let prefix = "avatar_"
        for url in urls {
            let base = url.deletingPathExtension().lastPathComponent
            guard base.hasPrefix(prefix) else { continue }
            let remainder = base.dropFirst(prefix.count)
            guard let underscore = remainder.lastIndex(of: "_") else { continue }
            let typeKey = String(remainder[..<underscore])
            guard let index = Int(remainder[remainder.index(after: underscore)...]), index >= 1 else { continue }
            sets[typeKey, default: []].append((index, base))
        }
        let mapped = sets.mapValues { $0.sorted { ($0.index, $0.file) < ($1.index, $1.file) }.map(\.file) }
        typeSets = mapped
        return mapped[typeKey] ?? []
    }

    // MARK: - Lookup

    private func cachedLookup(_ cacheKey: String, resource: String) -> NSImage? {
        if let cached = cache[cacheKey] { return cached }
        let image = bundleImage(named: resource)
        cache[cacheKey] = image
        return image
    }

    /// Lowercased alphanumeric key for an agent type name.
    static func normalizeTypeName(_ name: String) -> String {
        name.lowercased().unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
    }

    // MARK: - Loading

    private func bundleImage(named resource: String) -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: resource,
            withExtension: "png",
            subdirectory: "AgentSprites"
        ) else { return nil }
        guard var image = NSImage(contentsOf: url) else { return nil }
        image.size = Self.pointSize
        return image
    }
}
