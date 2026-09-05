// ABOUTME: Shared run-state types for ff-run and the app-side port monitor.
// ABOUTME: Encodes detected localhost ports, selection rules, and state-file persistence.

import Foundation
import Darwin

enum RunStateStatus: String, Codable, Sendable {
    case starting
    case running
    case stopped
    case crashed
}

struct RunStateSnapshot: Codable, Sendable {
    let pid: Int32
    let status: RunStateStatus
    let detectedPorts: [Int]
    let selectedPort: Int?
    let startedAt: Date
    /// The container's run generation that wrote this file. `nil` means the
    /// file was written by an older build without generation tracking.
    /// Lets stop/start sequences tell a fresh server's state apart from the
    /// previous server's teardown write racing on the same file path.
    let generation: Int?
}

struct PortSelectionResult: Sendable {
    let detectedPorts: [Int]
    let selectedPort: Int?
}

struct PortSelectionTracker: Sendable {
    let expectedPort: Int?
    private var lastCandidate: Int?
    private var candidateMatches = 0
    private(set) var selectedPort: Int?

    init(expectedPort: Int?) {
        self.expectedPort = expectedPort
    }

    mutating func update(listeningPorts: Set<Int>) -> PortSelectionResult {
        let currentPorts = Set(listeningPorts.filter { $0 > 0 })

        if let selectedPort, !currentPorts.contains(selectedPort) {
            self.selectedPort = nil
        }

        let candidate = candidatePort(currentPorts: currentPorts)

        if self.selectedPort == nil,
           let candidate {
            if candidate == lastCandidate {
                candidateMatches += 1
            } else {
                lastCandidate = candidate
                candidateMatches = 1
            }
            if candidateMatches >= 2 {
                selectedPort = candidate
            }
        } else if self.selectedPort == nil {
            lastCandidate = nil
            candidateMatches = 0
        }

        return PortSelectionResult(
            detectedPorts: orderedPorts(currentPorts, preferredPort: selectedPort ?? candidate),
            selectedPort: selectedPort
        )
    }

    private func candidatePort(currentPorts: Set<Int>) -> Int? {
        if currentPorts.count == 1, let onlyPort = currentPorts.first {
            return onlyPort
        }
        if currentPorts.count > 1,
           let expectedPort,
           currentPorts.contains(expectedPort) {
            return expectedPort
        }
        return nil
    }

    private func orderedPorts(_ currentPorts: Set<Int>, preferredPort: Int?) -> [Int] {
        let sortedPorts = currentPorts.sorted()
        guard let preferredPort,
              currentPorts.contains(preferredPort),
              currentPorts.count > 1 else {
            return sortedPorts
        }

        return [preferredPort] + sortedPorts.filter { $0 != preferredPort }
    }
}

enum RunStateStore {
    static var directoryURL: URL {
        AppConstants.cacheDirectory.appendingPathComponent("run-state", isDirectory: true)
    }

    static func fileURL(for workstreamID: UUID) -> URL {
        directoryURL.appendingPathComponent("\(workstreamID.uuidString.lowercased()).json")
    }

    static func load(for workstreamID: UUID) -> RunStateSnapshot? {
        load(from: fileURL(for: workstreamID))
    }

    static func loadValidated(for workstreamID: UUID) -> RunStateSnapshot? {
        guard let state = load(for: workstreamID),
              state.status != .stopped, state.status != .crashed,
              isProcessRunning(pid: state.pid) else {
            return nil
        }
        return state
    }

    static func load(from url: URL) -> RunStateSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(RunStateSnapshot.self, from: data)
    }

    static func write(_ state: RunStateSnapshot, for workstreamID: UUID) throws {
        let data = try encoder.encode(state)
        try FilePersistence.writeAtomically(data, to: fileURL(for: workstreamID))
    }

    static func remove(for workstreamID: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: workstreamID))
    }

    /// Remove the state file only if it still belongs to `generation`.
    /// A stop/start sequence bumps the generation before the old monitor
    /// notices its process died, so the old monitor's teardown must not
    /// delete the new server's fresh state. Returns true when the file is
    /// gone (or was already absent), false when a newer generation owns it.
    /// Files without a generation (written by older builds) are treated as
    /// stale and removed.
    @discardableResult
    static func removeIfGenerationMatches(_ generation: Int, for workstreamID: UUID) -> Bool {
        let url = fileURL(for: workstreamID)
        if let state = load(from: url), !isOwnedByGeneration(fileGeneration: state.generation, ownerGeneration: generation) {
            return false
        }
        try? FileManager.default.removeItem(at: url)
        return true
    }

    static func isProcessRunning(pid: Int32) -> Bool {
        guard pid > 0 else { return false }
        if kill(pid, 0) == 0 {
            return true
        }
        return errno == EPERM
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

/// Whether a state file written by `fileGeneration` may be removed by the
/// owner of `ownerGeneration`. Legacy files (`nil`) count as stale.
func isOwnedByGeneration(fileGeneration: Int?, ownerGeneration: Int) -> Bool {
    guard let fileGeneration else { return true }
    return fileGeneration == ownerGeneration
}

// MARK: - Run process tree killer

/// Best-effort teardown for dev-server process trees.
///
/// Closing a terminal surface (or killing its tmux session) kills the direct
/// child, but dev servers frequently spawn grandchildren (bundlers, file
/// watchers, daemonized workers) that survive and keep holding the port —
/// which is why ports kept creeping 8080 -> 8081. `killTree` signals the
/// whole tree rooted at the recorded `ff-run` command PID, leaves-first.
enum RunProcessKiller {
    /// Build a parent map via `ps`, then signal the tree. Synchronous and
    /// bounded (~1s): SIGTERM, short poll, then SIGKILL for survivors.
    static func killTree(root: Int32) {
        guard root > 0, RunStateStore.isProcessRunning(pid: root) else { return }
        let tree = descendants(of: root, parentMap: parentMap())
        let ordered = [root] + tree
        for pid in ordered {
            kill(pid, SIGTERM)
        }
        // Poll briefly so well-behaved servers release the port before the
        // caller starts a replacement; escalate only for stragglers.
        for _ in 0 ..< 10 {
            if !ordered.contains(where: { RunStateStore.isProcessRunning(pid: $0) }) { return }
            usleep(100_000)
        }
        for pid in ordered where RunStateStore.isProcessRunning(pid: pid) {
            kill(pid, SIGKILL)
        }
    }

    /// All PIDs in the subtree rooted at `root` (excluding `root` itself),
    /// deepest leaves first so children are signalled before their parents.
    static func descendants(of root: Int32, parentMap: [Int32: Int32]) -> [Int32] {
        var children: [Int32: [Int32]] = [:]
        for (pid, ppid) in parentMap {
            children[ppid, default: []].append(pid)
        }
        // Collect the reachable set iteratively, then order leaves-first by depth.
        var ordered: [Int32] = []
        var stack: [Int32] = children[root] ?? []
        while let pid = stack.popLast() {
            ordered.append(pid)
            stack.append(contentsOf: children[pid] ?? [])
        }
        // Sort leaves-first by depth in the tree.
        var depth: [Int32: Int] = [root: 0]
        var queue: [Int32] = [root]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for child in children[current] ?? [] where depth[child] == nil {
                depth[child] = (depth[current] ?? 0) + 1
                queue.append(child)
            }
        }
        return ordered.sorted { (depth[$0] ?? 0) > (depth[$1] ?? 0) }
    }

    /// pid -> ppid for all processes, parsed from `ps`.
    static func parentMap() -> [Int32: Int32] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-axo", "pid=,ppid="]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return [:]
        }
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return parseParentMap(output)
    }

    /// Pure parser for `ps -axo pid=,ppid=` output. Separated for tests.
    static func parseParentMap(_ output: String) -> [Int32: Int32] {
        var map: [Int32: Int32] = [:]
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count == 2, let pid = Int32(parts[0]), let ppid = Int32(parts[1]) else { continue }
            map[pid] = ppid
        }
        return map
    }
}
