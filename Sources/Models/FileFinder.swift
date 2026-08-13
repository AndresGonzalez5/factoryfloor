// ABOUTME: Recursive file scanning and fuzzy matching for the editor's quick-open file finder.
// ABOUTME: Name/path are pre-folded into Unicode scalar arrays at scan time; matching uses
// ABOUTME: unchecked pointer loops and a per-entry character bitmask so it barely costs
// ABOUTME: anything even in unoptimized debug builds, on every keystroke.

import Foundation

enum FileFinder {
    /// A scanned file. Name and full path are pre-folded (case/diacritic-insensitive)
    /// into scalar arrays once at scan time; matching only does plain array comparisons.
    struct Entry {
        let path: String
        let nameScalars: [Unicode.Scalar]
        let pathScalars: [Unicode.Scalar]
        /// Bitmask of the characters present in the folded name+path. Lets the
        /// matcher skip non-candidates with a single bitwise AND before scoring.
        let mask: UInt64

        init(path: String) {
            self.path = path
            let name = (path as NSString).lastPathComponent
            nameScalars = Array(name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).unicodeScalars)
            pathScalars = Array(path.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).unicodeScalars)
            var m: UInt64 = 0
            for sc in nameScalars { m |= FileFinder.maskBit(for: sc) }
            for sc in pathScalars { m |= FileFinder.maskBit(for: sc) }
            mask = m
        }
    }

    /// Directories that are essentially never useful to open in a text editor.
    /// Keeps scanning fast for node/venv/build-based worktrees.
    private static let skippedDirectories: Set<String> = [
        ".git",
        "node_modules",
        "Pods",
        ".venv",
        "venv",
        "dist",
        "build",
        ".build",
        "DerivedData",
        "coverage",
    ]

    /// Recursively list every file under `root` as a path relative to `root`.
    /// Subdirectories in `skippedDirectories` are not descended into.
    static func scanFiles(at rootPath: String) -> [Entry] {
        let fm = FileManager.default
        // Canonicalize so the prefix strip matches regardless of symlink aliases
        // (the enumerator yields /private/var/... while callers pass /var/...).
        let rootCanonical = URL(fileURLWithPath: rootPath).resolvingSymlinksInPath().path
        let rootPrefix = rootCanonical + "/"
        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: rootPath),
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) else { return [] }

        var entries: [Entry] = []
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey]) else {
                continue
            }
            if values.isDirectory == true {
                if skippedDirectories.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }
            let canonicalPath = url.resolvingSymlinksInPath().path
            guard values.isRegularFile == true, canonicalPath.hasPrefix(rootPrefix) else { continue }
            let relativePath = String(canonicalPath.dropFirst(rootPrefix.count))
            if !relativePath.isEmpty {
                entries.append(Entry(path: relativePath))
            }
        }
        return entries
    }

    /// Returns up to `limit` paths matching `query`, best match first.
    /// Uses bounded top-K selection instead of a full sort, so it is fast enough
    /// to run on every keystroke without blocking the main thread.
    static func results(matching rawQuery: String, in entries: [Entry], limit: Int = 50) -> [String] {
        let queryScalars = Array(rawQuery.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).unicodeScalars)
        guard !queryScalars.isEmpty else { return [] }
        // Non-foldable query scalars are still compared during scoring; they must
        // not force every candidate to also contain such a scalar, so strip that
        // bit from the prefilter mask only. Separators are handled equivalently
        // (a query separator matches any target separator), so the query's own
        // separator bits are not required — instead the target must contain at
        // least one separator when the query does.
        let queryMaskFull = Self.mask(for: queryScalars) & ~(1 << 40)
        let queryHasSeparator = (queryMaskFull & Self.separatorBits) != 0
        let queryMask = queryMaskFull & ~Self.separatorBits

        var best: [(path: String, score: Int)] = []
        best.reserveCapacity(limit)
        for entry in entries {
            // Cheap rejection: every query character must be present somewhere
            // in the folded name+path before we pay for a full comparison.
            guard (entry.mask & queryMask) == queryMask else { continue }
            guard !queryHasSeparator || (entry.mask & Self.separatorBits) != 0 else { continue }
            guard let score = Self.score(query: queryScalars, entry: entry) else { continue }
            if best.count < limit {
                let index = best.firstIndex { $0.score < score } ?? best.count
                best.insert((entry.path, score), at: index)
            } else if score > best[best.count - 1].score {
                let index = best.firstIndex { $0.score < score } ?? best.count - 1
                best.insert((entry.path, score), at: index)
                best.removeLast()
            }
        }

        return best
            .sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                if lhs.path.count != rhs.path.count { return lhs.path.count < rhs.path.count }
                return lhs.path.localizedCaseInsensitiveCompare(rhs.path) == .orderedAscending
            }
            .map(\.path)
    }

    /// Fuzzy-match `query` against `path`, returning a score (higher is better) or nil on no match.
    static func score(query: String, path: String) -> Int? {
        let scalars = Array(query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current).unicodeScalars)
        guard !scalars.isEmpty else { return nil }
        return score(query: scalars, entry: Entry(path: path))
    }

    private static func score(query: [Unicode.Scalar], entry: Entry) -> Int? {
        // Contiguous match at the start of the basename is the strongest signal.
        if let offset = findContiguous(query, in: entry.nameScalars) {
            return 10_000 - offset * 500 - max(0, entry.nameScalars.count - query.count)
        }

        // Contiguous match anywhere in the path.
        if let offset = findContiguous(query, in: entry.pathScalars) {
            return 5_000 - offset * 100 - max(0, entry.pathScalars.count - query.count)
        }

        // Characters in order but not contiguous — VS Code style subsequence matching.
        // A match inside the basename outranks a scattered match in the full path.
        if let base = subsequence(query, in: entry.nameScalars) {
            return 3_000 - base.gapPenalty * 50 - base.lastOffset / 2
        }
        if let base = subsequence(query, in: entry.pathScalars) {
            return 2_000 - base.gapPenalty * 50 - base.lastOffset / 2
        }
        return nil
    }

    /// First index where `query` appears contiguously inside `target`, or nil.
    /// Query separators (space/dash/underscore/dot) also match any target
    /// separator, so "use toast" finds "use-toast.tsx" and "use_toast.ts".
    private static func findContiguous(_ query: [Unicode.Scalar], in target: [Unicode.Scalar]) -> Int? {
        guard target.count >= query.count else { return nil }
        var result: Int?
        query.withUnsafeBufferPointer { qBuffer in
            target.withUnsafeBufferPointer { tBuffer in
                guard let q = qBuffer.baseAddress, let t = tBuffer.baseAddress else { return }
                let qCount = query.count
                let tCount = target.count
                var start = 0
                let lastStart = tCount - qCount
                outer: while start <= lastStart {
                    var i = 0
                    while i < qCount {
                        let qChar = q[i]
                        let tChar = t[start + i]
                        if qChar != tChar && !(isSeparator(qChar) && isSeparator(tChar)) {
                            start += 1
                            continue outer
                        }
                        i += 1
                    }
                    result = start
                    return
                }
            }
        }
        return result
    }

    /// Position of the first `query` character subsequence inside `target`, or nil.
    private static func subsequence(_ query: [Unicode.Scalar], in target: [Unicode.Scalar]) -> (gapPenalty: Int, lastOffset: Int)? {
        var result: (gapPenalty: Int, lastOffset: Int)?
        query.withUnsafeBufferPointer { qBuffer in
            target.withUnsafeBufferPointer { tBuffer in
                guard let q = qBuffer.baseAddress, let t = tBuffer.baseAddress else { return }
                let qCount = query.count
                let tCount = target.count
                var queryIndex = 0
                var previousMatchOffset = -1
                var gapPenalty = 0
                var lastMatchOffset = 0
                var offset = 0
                while offset < tCount {
                    if t[offset] == q[queryIndex] {
                        if previousMatchOffset >= 0, offset - previousMatchOffset > 1 {
                            gapPenalty += offset - previousMatchOffset - 1
                        }
                        previousMatchOffset = offset
                        lastMatchOffset = offset
                        queryIndex += 1
                        if queryIndex == qCount {
                            result = (gapPenalty, lastMatchOffset)
                            return
                        }
                    }
                    offset += 1
                }
            }
        }
        return result
    }

    private static func isSeparator(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x20, 0x2D, 0x5F, 0x2E, 0x2F: return true // space - _ . /
        default: return false
        }
    }

    private static let separatorBits: UInt64 =
        (1 << 36) | (1 << 37) | (1 << 38) | (1 << 39)

    private static func maskBit(for scalar: Unicode.Scalar) -> UInt64 {
        let v = scalar.value
        switch v {
        case 0x61...0x7A: return 1 << UInt64(v - 0x61)
        case 0x30...0x39: return 1 << (26 + UInt64(v - 0x30))
        case 0x20: return 1 << 36
        case 0x2D: return 1 << 37
        case 0x5F: return 1 << 38
        case 0x2E: return 1 << 39
        default: return 1 << 40
        }
    }

    private static func mask(for scalars: [Unicode.Scalar]) -> UInt64 {
        var m: UInt64 = 0
        for scalar in scalars {
            m |= maskBit(for: scalar)
        }
        return m
    }
}