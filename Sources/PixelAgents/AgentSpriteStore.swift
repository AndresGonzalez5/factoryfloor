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
/// 4. **Legacy sheets** — `char_<n>.png` 112×96 sprite sheets; the head of the
///    front-facing idle frame (frame 1) is cropped.
///
/// Portraits are 32×32 pixels sized to 16pt; views render them with
/// `.resizable()` + `.interpolation(.none)` to keep pixels crisp.
@MainActor
final class AgentSpriteStore {

    static let shared = AgentSpriteStore()

    /// Number of distinct palettes (0 is the main agent).
    static let paletteCount = 6

    /// Point size the avatars are normalized to.
    static let pointSize = CGSize(width: 16, height: 16)

    /// Maps a normalized type key to its numbered sprite file names, sorted by index.
    private var typeSets: [String: [String]]?
    private var cache: [String: NSImage?] = [:]

    private init() {}

    /// Returns the portrait for an agent run, or nil when no asset could be loaded.
    func avatar(name: String?, palette: Int, variant: Int = 0) -> NSImage? {
        let slot = ((palette % Self.paletteCount) + Self.paletteCount) % Self.paletteCount

        if let name, !name.isEmpty {
            let key = Self.normalizeTypeName(name)
            if !key.isEmpty {
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
        return legacyHeadCrop(slot: slot)
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

    /// Crops the top half (the head) of the front-facing idle frame from a
    /// legacy character sheet. Sheet layout: 16×32 frames in 7 columns; frame
    /// 1 sits at x=16..32 on row 0 (front-facing).
    private func legacyHeadCrop(slot: Int) -> NSImage? {
        if let cached = cache["legacy:\(slot)"] { return cached }
        let image = bundleImage(named: "char_\(slot)").flatMap { headCrop(from: $0) }
        cache["legacy:\(slot)"] = image
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

    private func headCrop(from sheet: NSImage) -> NSImage? {
        var rect = CGRect(x: 0, y: 0, width: sheet.size.width, height: sheet.size.height)
        guard let cgImage = sheet.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            return nil
        }
        let frameX = 16
        let crop = CGRect(x: frameX, y: 0, width: 16, height: 16)
        guard frameX + 16 <= cgImage.width,
              let cropped = cgImage.cropping(to: crop)
        else { return nil }
        return NSImage(cgImage: cropped, size: Self.pointSize)
    }
}
