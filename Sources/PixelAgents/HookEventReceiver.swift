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

        let hookEventName = eventInput["hook_event_name"] as? String ?? ""
        logger.info("Hook event received: \(hookEventName, privacy: .public) for project: \(projectDir, privacy: .public)")

        let events = mapHookEvent(hookEventName: hookEventName, eventInput: eventInput, projectDir: projectDir)
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

    /// Maps a Claude Code hook event to zero or more `AgentEvent` values.
    /// Must be called on `self.queue`.
    private func mapHookEvent(hookEventName: String, eventInput: [String: Any], projectDir: String) -> [AgentEvent] {
        switch hookEventName {
        case "PreToolUse":
            let toolName = eventInput["tool_name"] as? String ?? "unknown"
            // Skip internal/meta tools
            guard !toolName.hasPrefix("mcp__") && toolName != "Skill" && toolName != "ToolSearch" else {
                return []
            }
            let aid = agentId(from: eventInput)
            logger.info("Hook PreToolUse: \(toolName, privacy: .public) agent=\(aid, privacy: .public)")
            return [AgentEvent.toolStart(agentId: aid, tool: toolName)]

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

            // Assign palette from per-project state
            var state = projectState[projectDir] ?? ProjectState()
            let palette: Int
            if state.knownAgents.contains(aid) {
                palette = state.nextPalette - 1 // already assigned, but we don't track — just use next
            } else {
                palette = state.nextPalette % 6
                state.nextPalette += 1
                state.knownAgents.insert(aid)
                projectState[projectDir] = state
            }

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
