// ABOUTME: Event types for the Swift-to-JS pixel agents bridge protocol.
// ABOUTME: Encoded as JSON and sent to the WKWebView via evaluateJavaScript.

import Foundation

struct AgentEvent: Codable, Sendable {
    let type: EventType
    let agentId: String
    var name: String?
    var palette: Int?
    var tool: String?
    /// Human-readable description of what the agent is doing right now
    /// (e.g. "Editing Foo.swift"), derived from the tool and its input.
    var activity: String?
    var status: String?
    var parentAgentId: String?
    /// Model identifier reported by the harness (e.g. "claude-sonnet-4-5").
    var model: String?
    /// Harness transcript location (Claude Code hook payloads); the tracker
    /// reads context-window usage from its tail.
    var transcriptPath: String?
    /// Tokens consumed so far in the session context, when the harness reports
    /// them directly (OpenCode agent_info payloads).
    var contextUsedTokens: Int?
    /// Model-derived context-window ceiling accompanying `contextUsedTokens`.
    var contextLimitTokens: Int?

    enum EventType: String, Codable, Sendable {
        case agentCreated
        case agentRemoved
        case agentStatus
        case agentToolStart
        case agentToolDone
        case agentIdle
        case agentWaiting
        case agentInfo
    }

    enum CodingKeys: String, CodingKey {
        case type
        case agentId
        case name
        case palette
        case tool
        case activity
        case status
        case parentAgentId
        case model
        case transcriptPath
        case contextUsedTokens
        case contextLimitTokens
    }

    // -- Factory methods --

    static func created(agentId: String, name: String, palette: Int, parentAgentId: String? = nil) -> AgentEvent {
        AgentEvent(type: .agentCreated, agentId: agentId, name: name, palette: palette, parentAgentId: parentAgentId)
    }

    static func removed(agentId: String) -> AgentEvent {
        AgentEvent(type: .agentRemoved, agentId: agentId)
    }

    static func status(agentId: String, status: String, transcriptPath: String? = nil) -> AgentEvent {
        AgentEvent(type: .agentStatus, agentId: agentId, status: status, transcriptPath: transcriptPath)
    }

    static func toolStart(agentId: String, tool: String, activity: String? = nil, transcriptPath: String? = nil) -> AgentEvent {
        AgentEvent(type: .agentToolStart, agentId: agentId, tool: tool, activity: activity, transcriptPath: transcriptPath)
    }

    static func toolDone(agentId: String, transcriptPath: String? = nil) -> AgentEvent {
        AgentEvent(type: .agentToolDone, agentId: agentId, transcriptPath: transcriptPath)
    }

    static func idle(agentId: String, transcriptPath: String? = nil) -> AgentEvent {
        AgentEvent(type: .agentIdle, agentId: agentId, transcriptPath: transcriptPath)
    }

    static func waiting(agentId: String, transcriptPath: String? = nil) -> AgentEvent {
        AgentEvent(type: .agentWaiting, agentId: agentId, transcriptPath: transcriptPath)
    }

    /// Attribute refresh for an existing roster run (display name, model,
    /// context-window figures).
    static func info(
        agentId: String,
        name: String?,
        model: String? = nil,
        contextUsedTokens: Int? = nil,
        transcriptPath: String? = nil
    ) -> AgentEvent {
        var event = AgentEvent(type: .agentInfo, agentId: agentId, transcriptPath: transcriptPath)
        event.name = name
        event.model = model
        event.contextUsedTokens = contextUsedTokens
        event.contextLimitTokens = ContextLimits.limitTokens(forModel: model)
        return event
    }
}
