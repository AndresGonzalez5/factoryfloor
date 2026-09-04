// ABOUTME: HTTP server that receives Claude Code hook events via POST requests.
// ABOUTME: Listens on localhost with an OS-assigned port and writes port to cache file.

import Foundation
import Network
import os

private let logger = Logger(subsystem: "factoryfloor", category: "hook-receiver")

/// Receives Claude Code hook events over HTTP on a local NWListener.
///
/// The listener binds to 127.0.0.1 on an OS-assigned port, writes the port
/// number to `~/Library/Caches/factoryfloor/hook-port`, and routes incoming
/// hook events to the `onEvent` callback.
///
/// Thread safety: all mutable state is accessed on `self.queue`.
final class HookEventReceiver: @unchecked Sendable {

    static let shared = HookEventReceiver()

    /// Called on the main queue with (projectDir, event).
    var onEvent: ((String, AgentEvent) -> Void)?

    private let queue = DispatchQueue(label: "factoryfloor.hook-receiver", qos: .utility)
    private var listener: NWListener?
    private var connections: [NWConnection] = []

    /// Per-project state for tracking subagent palettes.
    private struct ProjectState {
        var nextPalette: Int = 1 // 0 is reserved for main
        var knownAgents: Set<String> = []
    }

    private var projectState: [String: ProjectState] = [:] // keyed by projectDir

    private init() {}

    // MARK: - Lifecycle

    func start() {
        queue.async { [weak self] in
            self?.setupListener()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.listener?.cancel()
            self.listener = nil
            for conn in self.connections {
                conn.cancel()
            }
            self.connections.removeAll()
            self.removePortFile()
        }
    }

    // MARK: - Listener Setup

    private func setupListener() {
        do {
            let params = NWParameters.tcp
            params.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .any)
            let newListener = try NWListener(using: params)

            newListener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    if let port = newListener.port {
                        logger.info("Hook receiver listening on port \(port.rawValue)")
                        self?.writePortFile(port: port.rawValue)
                    }
                case let .failed(error):
                    logger.error("Hook receiver failed: \(error.localizedDescription)")
                    newListener.cancel()
                case .cancelled:
                    logger.info("Hook receiver cancelled")
                default:
                    break
                }
            }

            newListener.newConnectionHandler = { [weak self] connection in
                self?.queue.async {
                    self?.handleConnection(connection)
                }
            }

            listener = newListener
            newListener.start(queue: queue)
        } catch {
            logger.error("Failed to create hook listener: \(error.localizedDescription)")
        }
    }

    // MARK: - Connection Handling

    private func handleConnection(_ connection: NWConnection) {
        connections.append(connection)

        connection.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                self?.removeConnection(connection)
            }
        }

        connection.start(queue: queue)
        receiveData(on: connection, buffer: Data())
    }

    private func receiveData(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            var accumulated = buffer
            if let data {
                accumulated.append(data)
            }

            if isComplete || error != nil {
                // We have all the data — process it
                self.processHTTPRequest(accumulated, on: connection)
                return
            }

            // Check if we have the full HTTP body yet
            if let headerEnd = self.findHeaderEnd(in: accumulated) {
                let headerData = accumulated[..<headerEnd]
                let bodyStart = headerEnd
                if let contentLength = self.parseContentLength(from: headerData),
                   accumulated.count >= bodyStart + contentLength {
                    // Full request received
                    self.processHTTPRequest(accumulated, on: connection)
                    return
                }
            }

            // Need more data
            self.receiveData(on: connection, buffer: accumulated)
        }
    }

    private func findHeaderEnd(in data: Data) -> Int? {
        let separator: [UInt8] = [0x0D, 0x0A, 0x0D, 0x0A] // \r\n\r\n
        let bytes = Array(data)
        guard bytes.count >= 4 else { return nil }
        for i in 0 ... (bytes.count - 4) {
            if bytes[i] == separator[0] && bytes[i + 1] == separator[1]
                && bytes[i + 2] == separator[2] && bytes[i + 3] == separator[3]
            {
                return i + 4
            }
        }
        return nil
    }

    private func parseContentLength(from headerData: Data) -> Int? {
        guard let headerString = String(data: headerData, encoding: .utf8)?.lowercased() else { return nil }
        for line in headerString.components(separatedBy: "\r\n") {
            if line.hasPrefix("content-length:") {
                let value = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
                return Int(value)
            }
        }
        return nil
    }

    // MARK: - HTTP Request Processing

    private func processHTTPRequest(_ data: Data, on connection: NWConnection) {
        defer { removeConnection(connection) }

        // Extract JSON body after \r\n\r\n
        guard let headerEnd = findHeaderEnd(in: data) else {
            sendResponse(on: connection, status: "400 Bad Request", body: "{\"error\":\"no headers\"}")
            return
        }

        let bodyData = data[headerEnd...]
        guard !bodyData.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        else {
            sendResponse(on: connection, status: "400 Bad Request", body: "{\"error\":\"invalid json\"}")
            return
        }

        // The ff-hook script wraps the Claude Code input as:
        //   { "event_input": { ... }, "project_dir": "..." }
        // The Factory Floor opencode plugin posts the same envelope plus
        //   "source": "opencode" with pre-digested event_input payloads.
        guard let projectDir = json["project_dir"] as? String else {
            logger.warning("Hook event missing project_dir")
            sendResponse(on: connection, status: "200 OK", body: "{\"ok\":true}")
            return
        }

        guard let eventInput = json["event_input"] as? [String: Any] else {
            logger.warning("Hook event missing event_input")
            sendResponse(on: connection, status: "200 OK", body: "{\"ok\":true}")
            return
        }

        let source = json["source"] as? String
        let events: [AgentEvent]
        if source == "opencode" {
            let kind = eventInput["kind"] as? String ?? ""
            logger.info("OpenCode event received: \(kind, privacy: .public) for project: \(projectDir, privacy: .public)")
            events = mapOpencodeEvent(eventInput: eventInput, projectDir: projectDir)
        } else {
            let hookEventName = eventInput["hook_event_name"] as? String ?? ""
            logger.info("Hook event received: \(hookEventName, privacy: .public) for project: \(projectDir, privacy: .public)")
            events = mapHookEvent(hookEventName: hookEventName, eventInput: eventInput, projectDir: projectDir)
        }
        if !events.isEmpty {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                for event in events {
                    self.onEvent?(projectDir, event)
                }
            }
        }

        sendResponse(on: connection, status: "200 OK", body: "{\"ok\":true}")
    }

    // MARK: - Event Mapping

    /// Determines the agent ID from the event input JSON.
    /// Uses "main" if no `agent_id` field is present.
    private func agentId(from eventInput: [String: Any]) -> String {
        (eventInput["agent_id"] as? String) ?? "main"
    }

    /// Returns true if the given agent ID represents a subagent (not the main agent).
    private func isSubagent(_ agentId: String) -> Bool {
        !agentId.isEmpty && agentId != "main"
    }

    /// Assigns a roster palette slot for an agent within a project.
    /// Must be called on `self.queue`.
    private func assignPalette(projectDir: String, agentId: String) -> Int {
        var state = projectState[projectDir] ?? ProjectState()
        let palette = state.nextPalette % 6
        if !state.knownAgents.contains(agentId) {
            state.nextPalette += 1
            state.knownAgents.insert(agentId)
        }
        projectState[projectDir] = state
        return palette
    }

    /// Maps a tool name (and, when available, its input) to a short human-readable
    /// activity description for the sidebar roster, e.g. "Editing Foo.swift".
    static func activityDescription(toolName: String, toolInput: [String: Any]?) -> String? {
        let filePath = (toolInput?["file_path"] as? String) ?? (toolInput?["notebook_path"] as? String)
        let baseName = filePath.map { URL(fileURLWithPath: $0).lastPathComponent }

        // Claude Code tools are PascalCase ("Edit"); OpenCode tools are
        // lowercase ("edit"). Match case-insensitively so both harnesses share one table.
        switch toolName.lowercased() {
        case "edit", "write", "multiedit", "notebookedit", "patch":
            if let baseName {
                return String(format: NSLocalizedString("Editing %@", comment: "Agent is modifying a file"), baseName)
            }
            return NSLocalizedString("Editing", comment: "Agent is modifying a file")
        case "read":
            if let baseName {
                return String(format: NSLocalizedString("Reading %@", comment: "Agent is reading a file"), baseName)
            }
            return NSLocalizedString("Reading", comment: "Agent is reading a file")
        case "grep", "glob":
            return NSLocalizedString("Searching", comment: "Agent is searching the codebase")
        case "bash":
            return NSLocalizedString("Running command", comment: "Agent is running a shell command")
        case "webfetch", "websearch":
            return NSLocalizedString("Browsing", comment: "Agent is fetching web content")
        case "todowrite", "todoread":
            return NSLocalizedString("Planning", comment: "Agent is updating its task plan")
        case "question":
            // OpenCode's built-in question tool: the agent is blocked asking
            // the user something. Never surface the raw tool name (see
            // tool_start mapping, which raises permissionRequired alongside).
            return NSLocalizedString("Asking question", comment: "Agent is asking the user a question")
        case "task":
            return NSLocalizedString("Delegating", comment: "Agent is delegating to a subagent")
        default:
            // Custom/MCP tools surface verbatim so the row always says
            // something specific about what's running.
            return toolName.isEmpty ? nil : toolName
        }
    }

    /// Trims and caps an OpenCode subtask description so oversized prompts
    /// don't bloat payloads or roster rows. Returns nil when empty.
    static func cappedTaskDescription(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(120))
    }

    /// Maps a Claude Code hook event to zero or more `AgentEvent` values.
    /// Must be called on `self.queue`.
    private func mapHookEvent(hookEventName: String, eventInput: [String: Any], projectDir: String) -> [AgentEvent] {
        // Every Claude Code hook payload carries the session transcript path;
        // attach it so the tracker can read context-window usage from its tail.
        let transcriptPath = eventInput["transcript_path"] as? String
        let events = baseHookEvents(hookEventName: hookEventName, eventInput: eventInput, projectDir: projectDir)
        guard let transcriptPath else { return events }
        return events.map { event in
            var event = event
            event.transcriptPath = transcriptPath
            return event
        }
    }

    private func baseHookEvents(hookEventName: String, eventInput: [String: Any], projectDir: String) -> [AgentEvent] {
        switch hookEventName {
        case "PreToolUse":
            let toolName = eventInput["tool_name"] as? String ?? "unknown"
            // Skip internal/meta tools
            guard !toolName.hasPrefix("mcp__") && toolName != "Skill" && toolName != "ToolSearch" else {
                return []
            }
            let aid = agentId(from: eventInput)
            let activity = Self.activityDescription(toolName: toolName, toolInput: eventInput["tool_input"] as? [String: Any])
            logger.info("Hook PreToolUse: \(toolName, privacy: .public) agent=\(aid, privacy: .public)")
            return [AgentEvent.toolStart(agentId: aid, tool: toolName, activity: activity)]

        case "PostToolUse":
            let aid = agentId(from: eventInput)
            logger.info("Hook PostToolUse: agent=\(aid, privacy: .public)")
            return [AgentEvent.toolDone(agentId: aid)]

        case "Stop":
            logger.info("Hook Stop: main agent goes idle")
            return [AgentEvent.idle(agentId: "main")]

        case "UserPromptSubmit":
            logger.info("Hook UserPromptSubmit: main agent waiting")
            return [AgentEvent.waiting(agentId: "main")]

        case "SubagentStart":
            let aid = agentId(from: eventInput)
            guard isSubagent(aid) else { return [] }
            let agentType = eventInput["agent_type"] as? String ?? "Sub-agent"
            let name = String(agentType.prefix(20))
            let palette = assignPalette(projectDir: projectDir, agentId: aid)

            logger.info("Hook SubagentStart: \(aid, privacy: .public) name=\(name, privacy: .public) palette=\(palette)")
            return [AgentEvent.created(agentId: aid, name: name, palette: palette, parentAgentId: "main")]

        case "SubagentStop":
            let aid = agentId(from: eventInput)
            guard isSubagent(aid) else { return [] }
            logger.info("Hook SubagentStop: \(aid, privacy: .public)")
            return [AgentEvent.removed(agentId: aid)]

        case "Notification":
            // Claude Code emits Notification for permission prompts and idle
            // reminders. The message field is the only signal we have; over-
            // reporting permission is preferable to under-reporting.
            let message = (eventInput["message"] as? String) ?? ""
            let lower = message.lowercased()
            let isPermission = lower.contains("permission") || lower.contains("approval")
            let status = isPermission ? "permissionRequired" : "idleNotification"
            logger.info("Hook Notification: status=\(status, privacy: .public)")
            return [AgentEvent.status(agentId: "main", status: status)]

        default:
            logger.debug("Unhandled hook event: \(hookEventName, privacy: .public)")
            return []
        }
    }

    // MARK: - OpenCode Mapping

    /// Maps a Factory Floor opencode plugin payload to zero or more `AgentEvent`s.
    /// Payload shape: `{ kind, agent_id, name?, tool?, file_path?, session_id?,
    /// previous_session_id?, parent_session_id? }`.
    /// Must be called on `self.queue`.
    private func mapOpencodeEvent(eventInput: [String: Any], projectDir: String) -> [AgentEvent] {
        let kind = eventInput["kind"] as? String ?? ""
        let aid = eventInput["agent_id"] as? String ?? "main"
        let name = eventInput["name"] as? String
        let sessionID = eventInput["session_id"] as? String

        switch kind {
        case "tool_start":
            let toolName = eventInput["tool"] as? String ?? "unknown"
            var toolInput: [String: Any]?
            if let filePath = eventInput["file_path"] as? String {
                toolInput = ["file_path": filePath]
            }
            let activity = Self.activityDescription(toolName: toolName, toolInput: toolInput)
            var event = AgentEvent.toolStart(agentId: aid, tool: toolName, activity: activity, sessionID: sessionID)
            event.name = name
            // The `question` tool blocks on the user's answer without ending
            // the session and without a dedicated bus event (the plugin also
            // sends permission_required for it, but belt-and-braces here
            // covers older plugin versions that only sent tool_start).
            // Tool event first, status second: the tracker clears permission
            // on tool activity, so status must win the ordering.
            if toolName.lowercased() == "question" {
                let status = AgentEvent.status(agentId: aid, status: "permissionRequired", sessionID: sessionID)
                return [event, status]
            }
            return [event]

        case "tool_done":
            var event = AgentEvent.toolDone(agentId: aid, sessionID: sessionID)
            event.name = name
            return [event]

        case "working":
            // Heartbeat while streaming a response — keeps the run alive
            // without changing its activity description.
            var event = AgentEvent.toolStart(agentId: aid, tool: "respond", sessionID: sessionID)
            event.name = name
            return [event]

        case "waiting":
            var event = AgentEvent.waiting(agentId: aid, sessionID: sessionID)
            event.name = name
            return [event]

        case "agent_info":
            // Attribute refresh (display name, model, context) — no state change.
            // Prefer the plugin-computed total; older plugins may send the raw
            // token dict instead, so fall back to summing it.
            let model = eventInput["model"] as? String
            var contextUsed: Int?
            if let reported = eventInput["context_used"] as? Int {
                contextUsed = reported > 0 ? reported : nil
            } else if let tokens = eventInput["tokens"] as? [String: Any] {
                let used = TranscriptContextReader.usedTokens(fromOpencodeTokens: tokens)
                contextUsed = used > 0 ? used : nil
            }
            return [AgentEvent.info(agentId: aid, name: name, model: model, contextUsedTokens: contextUsed, sessionID: sessionID)]

        case "idle":
            return [AgentEvent.idle(agentId: aid, sessionID: sessionID)]

        case "permission_required":
            // Permission and question prompts both block on user input;
            // they surface identically as row-level attention. Attribute to
            // the requesting agent when the plugin reports one; the tracker
            // only raises row-level attention for the main agent.
            return [AgentEvent.status(agentId: aid, status: "permissionRequired", sessionID: sessionID)]

        case "session_switched":
            // A new top-level session replaced the worktree's tracked
            // conversation: reset roster and context snapshot to it.
            guard let newID = sessionID, !newID.isEmpty else { return [] }
            logger.info("OpenCode session switched to \(newID, privacy: .public)")
            return [AgentEvent.sessionSwitched(sessionID: newID)]

        case "session_created":
            guard let sessionID = eventInput["session_id"] as? String, !sessionID.isEmpty,
                  let parentID = eventInput["parent_session_id"] as? String, !parentID.isEmpty,
                  isSubagent(sessionID)
            else { return [] }
            let agentType = (eventInput["agent_type"] as? String) ?? "Sub-agent"
            let subName = String(agentType.prefix(20))
            let taskDescription = Self.cappedTaskDescription(eventInput["description"] as? String)
            let palette = assignPalette(projectDir: projectDir, agentId: sessionID)
            if let taskDescription {
                logger.info("OpenCode subagent: \(sessionID, privacy: .public) name=\(subName, privacy: .public) desc=\(taskDescription, privacy: .public) palette=\(palette)")
            } else {
                logger.info("OpenCode subagent: \(sessionID, privacy: .public) name=\(subName, privacy: .public) palette=\(palette) (no description)")
            }
            return [AgentEvent.created(agentId: sessionID, name: subName, palette: palette, parentAgentId: "main", taskDescription: taskDescription)]

        default:
            logger.debug("Unhandled opencode event: \(kind, privacy: .public)")
            return []
        }
    }

    private func sendResponse(on connection: NWConnection, status: String, body: String) {
        let response = "HTTP/1.1 \(status)\r\nContent-Type: application/json\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
        let responseData = Data(response.utf8)
        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func removeConnection(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }
    }

    // MARK: - Port File

    private var portFilePath: String {
        let cacheDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/factoryfloor")
        return cacheDir.appendingPathComponent("hook-port").path
    }

    private func writePortFile(port: UInt16) {
        let cacheDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/factoryfloor")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let portString = String(port)
        try? portString.write(toFile: portFilePath, atomically: true, encoding: .utf8)
        logger.info("Wrote port \(port) to \(self.portFilePath)")
    }

    private func removePortFile() {
        try? FileManager.default.removeItem(atPath: portFilePath)
    }
}
