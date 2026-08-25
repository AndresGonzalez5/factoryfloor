// ABOUTME: Spawns one-shot coding-agent subprocesses or git/gh commands for quick actions.
// ABOUTME: Forks from the active session for context-aware tasks like PR creation.

import Foundation
import os

private let logger = Logger(subsystem: "factoryfloor", category: "quick-action")

enum QuickAction: String, CaseIterable, Identifiable {
    case commit
    case push
    case createPR
    case closePR

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .commit: return NSLocalizedString("Commit", comment: "")
        case .push: return NSLocalizedString("Push", comment: "")
        case .createPR: return NSLocalizedString("Create PR", comment: "")
        case .closePR: return NSLocalizedString("Close PR", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .commit: return "checkmark.circle"
        case .push: return "arrow.up"
        case .createPR: return "arrow.triangle.pull"
        case .closePR: return "xmark.circle"
        }
    }

    /// Whether this action requires claude -p (vs direct git/gh command).
    var usesLLM: Bool {
        switch self {
        case .commit, .createPR: return true
        case .push, .closePR: return false
        }
    }

    var requiresGitHubRemote: Bool {
        switch self {
        case .createPR, .closePR: return true
        case .commit, .push: return false
        }
    }

    var prompt: String? {
        switch self {
        case .commit:
            return "Stage and commit all changes in the working tree with a good commit message based on the changes. Do not push."
        case .createPR:
            return "Create a pull request for the current changes. Write a clear title and description based on what we've been working on."
        case .push, .closePR:
            return nil
        }
    }
}

enum QuickActionState: Equatable {
    case idle
    case running(QuickAction)
    case succeeded(QuickAction)
    case failed(QuickAction)
}

struct QuickActionLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let action: QuickAction
    let command: String
    var output: String
    var exitCode: Int32?
    /// Human-readable result extracted from the harness output (assistant
    /// text), shown instead of the raw stream.
    var summary: String?
    /// Link extracted from the result (e.g. the created PR URL).
    var artifactURL: String?
}

/// Thread-safe accumulator for streamed command output.
private final class OutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }
}

/// Thread-safe rate limiter for streaming UI updates.
private final class StreamThrottle: @unchecked Sendable {
    private let lock = NSLock()
    private var last = Date.distantPast
    private let minInterval: TimeInterval

    init(minInterval: TimeInterval) {
        self.minInterval = minInterval
    }

    /// Returns true at most once per `minInterval`.
    func shouldEmit() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let now = Date()
        guard now.timeIntervalSince(last) >= minInterval else { return false }
        last = now
        return true
    }
}

@MainActor
final class QuickActionRunner: ObservableObject {
    @Published var state: QuickActionState = .idle
    @Published var log: [QuickActionLogEntry] = []
    var onSuccess: ((QuickAction) -> Void)?
    private var runningProcess: Process?
    private var dismissWork: DispatchWorkItem?
    /// Worktree sentinel file written while an OpenCode quick action runs so
    /// the plugin ignores that subprocess (prevents session hijacking).
    private var sentinelPath: String?

    func run(
        action: QuickAction,
        harness: CodingHarness = .claudeCode,
        agentPath: String?,
        ghPath: String?,
        workingDirectory: String,
        branchName: String? = nil
    ) {
        guard case .idle = state else { return }

        state = .running(action)
        dismissWork?.cancel()

        switch action {
        case .commit, .createPR:
            guard let agentPath else { return }
            switch harness {
            case .claudeCode:
                runClaudeAction(action: action, claudePath: agentPath, workingDirectory: workingDirectory)
            case .opencode:
                runOpencodeAction(action: action, opencodePath: agentPath, workingDirectory: workingDirectory)
            }
        case .push:
            runPush(workingDirectory: workingDirectory)
        case .closePR:
            guard let ghPath, let branchName else { return }
            runClosePR(ghPath: ghPath, branchName: branchName, workingDirectory: workingDirectory)
        }
    }

    private func runClaudeAction(action: QuickAction, claudePath: String, workingDirectory: String) {
        guard let prompt = action.prompt else { return }

        var args: [String] = []
        args.append(claudePath)
        args.append("-p")
        args.append(CommandBuilder.shellQuote(prompt))
        args.append("--output-format")
        args.append("json")
        args.append("--continue")
        args.append("--fork-session")
        args.append("--no-session-persistence")
        args.append("--dangerously-skip-permissions")

        let innerCommand = args.joined(separator: " ")
        let shell = CommandBuilder.userShell
        runShellCommand(action: action, shell: shell, arguments: ["-lic", innerCommand], workingDirectory: workingDirectory, parseJSON: true)
    }

    private func runOpencodeAction(action: QuickAction, opencodePath: String, workingDirectory: String) {
        guard let prompt = action.prompt else { return }

        // Continue the workstream's tracked session in forked form so quick
        // actions never pollute the interactive conversation. Prefer the
        // explicit session id the plugin recorded (deterministic) over
        // --continue, which silently follows the directory's newest session.
        var args: [String] = []
        args.append(opencodePath)
        args.append("run")
        if let sessionID = Self.trackedSessionID(in: workingDirectory) {
            args.append("--session")
            args.append(CommandBuilder.shellQuote(sessionID))
            args.append("--fork")
        } else {
            args.append("--continue")
            args.append("--fork")
        }
        args.append("--auto")
        args.append("--format")
        args.append("json")
        args.append(CommandBuilder.shellQuote(prompt))

        let innerCommand = args.joined(separator: " ")
        let shell = CommandBuilder.userShell
        Self.writeSentinel(workingDirectory: workingDirectory)
        sentinelPath = Self.sentinelPath(workingDirectory: workingDirectory)
        runShellCommand(
            action: action, shell: shell, arguments: ["-lic", innerCommand],
            workingDirectory: workingDirectory, parseJSON: false,
            liveUpdate: { [weak self] outputText in
                DispatchQueue.main.async {
                    self?.updateOpencodeLiveSummary(entryText: outputText)
                }
            }
        )
    }

    /// The plugin-recorded session id for the worktree, if any.
    private nonisolated static func trackedSessionID(in directory: String) -> String? {
        let url = URL(fileURLWithPath: directory)
            .appendingPathComponent(".factoryfloor-state/opencode-session")
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - OpenCode quick-action sentinel

    private nonisolated static func sentinelPath(workingDirectory dir: String) -> String {
        URL(fileURLWithPath: dir)
            .appendingPathComponent(".factoryfloor-state/opencode-quickaction").path
    }

    private nonisolated static func writeSentinel(workingDirectory dir: String) {
        let path = sentinelPath(workingDirectory: dir)
        let stateDir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)
        let ms = Int64(Date().timeIntervalSince1970 * 1000)
        try? "\(ms)".write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func removeSentinel() {
        guard let path = sentinelPath else { return }
        try? FileManager.default.removeItem(atPath: path)
        sentinelPath = nil
    }

    // MARK: - OpenCode stream parsing

    /// Live summary refresh while the JSONL event stream is arriving.
    private func updateOpencodeLiveSummary(entryText rawOutput: String) {
        guard case .running = state else { return }
        let parsed = Self.parseOpencodeStream(rawOutput)
        guard let idx = log.indices.last else { return }
        log[idx].summary = parsed.summary ?? log[idx].summary
    }

    /// Parses an `opencode run --format json` JSONL stream into a
    /// human-readable result: the final assistant text plus any GitHub PR URL.
    ///
    /// Each line is `{ type, timestamp, sessionID, ... }`. Assistant text
    /// arrives via `message.updated` (`info.role == "assistant"`, `info.id`)
    /// and `message.part.updated` (`part.type == "text"`). Unknown shapes are
    /// tolerated so newer/older CLI versions degrade gracefully.
    nonisolated static func parseOpencodeStream(_ text: String) -> (summary: String?, pullRequestURL: String?) {
        var assistantMessages = Set<String>()
        var partsByID: [String: String] = [:]
        var partOrder: [String] = []

        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let data = String(line).data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }
            let props = json["properties"] as? [String: Any]

            if json["type"] as? String == "message.updated" {
                let info = (json["info"] as? [String: Any]) ?? (props?["info"] as? [String: Any])
                if let info,
                   (info["role"] as? String) == "assistant",
                   let messageID = info["id"] as? String
                {
                    assistantMessages.insert(messageID)
                }
            }

            for container in [json, props].compactMap({ $0 }) {
                guard let part = container["part"] as? [String: Any],
                      (part["type"] as? String) == "text",
                      let body = part["text"] as? String,
                      !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { continue }
                // When we know which messages are assistant messages, only
                // accept parts belonging to them; otherwise accept all.
                if let messageID = part["messageID"] as? String, !assistantMessages.isEmpty,
                   !assistantMessages.contains(messageID)
                {
                    continue
                }
                let id = (part["id"] as? String) ?? "part-\(partOrder.count)"
                if partsByID[id] == nil {
                    partOrder.append(id)
                }
                partsByID[id] = body
            }
        }

        // The last assistant text block is the actionable answer ("Committed
        // abc1234…", "Created #14 …"); earlier blocks are narration.
        let summary = partOrder.last.flatMap { partsByID[$0] }
        let scanned = [summary, text].compactMap { $0 }.joined(separator: "\n")
        return (summary, Self.firstPullRequestURL(in: scanned))
    }

    private nonisolated static func firstPullRequestURL(in text: String) -> String? {
        let pattern = #"https://github\.com/[A-Za-z0-9_.\-]+/[A-Za-z0-9_.\-]+/(?:pull|issues)/\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let urlRange = Range(match.range, in: text)
        else { return nil }
        return String(text[urlRange])
    }

    private func runPush(workingDirectory: String) {
        let dir = workingDirectory
        let actionRaw = QuickAction.push.rawValue
        let command = "git push -u origin HEAD"

        appendLog(action: .push, command: command)
        logger.info("Quick action \(actionRaw) starting in \(dir)")

        Task.detached {
            let result = GitOperations.pushCurrentBranch(at: dir)
            await MainActor.run {
                self.updateLog(output: result.output, exitCode: result.success ? 0 : 1)
                self.runningProcess = nil
                self.state = result.success ? .succeeded(.push) : .failed(.push)
                if result.success {
                    self.onSuccess?(.push)
                }
                self.scheduleDismiss()
            }
        }
    }

    private func runClosePR(ghPath: String, branchName: String, workingDirectory: String) {
        let command = "\(ghPath) pr close \(branchName) --comment 'Closed from Factory Floor'"

        appendLog(action: .closePR, command: command)
        logger.info("Quick action closePR starting in \(workingDirectory)")

        let dir = workingDirectory
        let path = ghPath
        let branch = branchName
        Task.detached {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = ["pr", "close", branch, "--comment", "Closed from Factory Floor"]
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
            process.standardOutput = pipe
            process.standardError = pipe
            let success: Bool
            let output: String
            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                output = String(data: data, encoding: .utf8) ?? ""
                success = process.terminationStatus == 0
            } catch {
                output = "Failed to launch: \(error.localizedDescription)"
                success = false
            }
            await MainActor.run {
                self.updateLog(output: output, exitCode: success ? 0 : 1)
                self.runningProcess = nil
                self.state = success ? .succeeded(.closePR) : .failed(.closePR)
                if success {
                    self.onSuccess?(.closePR)
                }
                self.scheduleDismiss()
            }
        }
    }

    private func runShellCommand(
        action: QuickAction,
        shell: String,
        arguments: [String],
        workingDirectory: String,
        parseJSON: Bool,
        liveUpdate: (@Sendable (String) -> Void)? = nil
    ) {
        let fullCommand = "\(shell) \(arguments.joined(separator: " "))"
        let entryID = appendLog(action: action, command: fullCommand)
        let actionRaw = action.rawValue
        let dir = workingDirectory

        logger.info("Quick action \(actionRaw) starting in \(dir)")
        logger.info("Command: \(fullCommand)")

        Task.detached {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: shell)
            process.arguments = arguments
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
            process.standardOutput = pipe
            process.standardError = pipe

            // Streams output as it arrives so summaries update live.
            let buffer = OutputBuffer()
            let throttle = StreamThrottle(minInterval: 0.3)
            if let liveUpdate {
                pipe.fileHandleForReading.readabilityHandler = { handle in
                    let chunk = handle.availableData
                    guard !chunk.isEmpty else { return }
                    buffer.append(chunk)
                    // Throttle UI refreshes; publishing every chunk would
                    // churn the log view.
                    guard throttle.shouldEmit() else { return }
                    liveUpdate(buffer.text)
                }
            }

            let success: Bool
            let output: String
            do {
                try process.run()
                await MainActor.run { self.runningProcess = process }
                process.waitUntilExit()
                if let liveUpdate {
                    pipe.fileHandleForReading.readabilityHandler = nil
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                buffer.append(data)
                output = buffer.text
                if parseJSON {
                    success = Self.parseSuccess(output: output, exitCode: process.terminationStatus)
                } else {
                    success = process.terminationStatus == 0
                }
            } catch {
                if let liveUpdate {
                    pipe.fileHandleForReading.readabilityHandler = nil
                }
                output = "Failed to launch: \(error.localizedDescription)"
                success = false
            }

            let exitCode = process.terminationStatus
            await MainActor.run {
                if let idx = self.log.firstIndex(where: { $0.id == entryID }) {
                    self.log[idx].output = output
                    self.log[idx].exitCode = exitCode
                    if !parseJSON, exitCode == 0 || !output.isEmpty {
                        let parsed = Self.parseOpencodeStream(output)
                        self.log[idx].summary = parsed.summary
                        self.log[idx].artifactURL = parsed.pullRequestURL
                    }
                }
                self.removeSentinel()
                self.runningProcess = nil
                self.state = success ? .succeeded(action) : .failed(action)
                if success {
                    self.onSuccess?(action)
                }
                self.scheduleDismiss()
            }
        }
    }

    @discardableResult
    private func appendLog(action: QuickAction, command: String) -> UUID {
        let entry = QuickActionLogEntry(
            timestamp: Date(),
            action: action,
            command: command,
            output: ""
        )
        log.append(entry)
        return entry.id
    }

    private func updateLog(output: String, exitCode: Int32) {
        guard let idx = log.indices.last else { return }
        log[idx].output = output
        log[idx].exitCode = exitCode
    }

    func cancel() {
        runningProcess?.terminate()
        runningProcess = nil
        removeSentinel()
        state = .idle
    }

    func clearLog() {
        log.removeAll()
    }

    private nonisolated static func parseSuccess(output: String, exitCode: Int32) -> Bool {
        guard exitCode == 0 else { return false }
        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return true
        }
        let isError = json["is_error"] as? Bool ?? false
        return !isError
    }

    private func scheduleDismiss() {
        dismissWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.state = .idle
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }
}
