// ABOUTME: OpenCode plugin auto-installed by VibeFloor.
// ABOUTME: Forwards agent events to the app's local HTTP receiver, tracks the
// ABOUTME: current session id for resume, and appends Factory Floor system
// ABOUTME: instructions from .factoryfloor-state/instructions.md to each turn.

import { readFileSync, writeFileSync, mkdirSync } from "node:fs"

const PORT_FILE = `${process.env.HOME}/Library/Caches/factoryfloor/hook-port`
const STATE_DIR = ".factoryfloor-state"
const SESSION_FILE = `${STATE_DIR}/opencode-session`
const INSTRUCTIONS_FILE = `${STATE_DIR}/instructions.md`
// Written by the app while a quick-action subprocess runs; while present we
// must not adopt forked session ids (they would hijack the interactive
// session's resume pointer) or forward roster/status events for them.
const QUICKACTION_SENTINEL = `${STATE_DIR}/opencode-quickaction`
// Sentinel files older than this are stale (app crashed mid-run) and ignored.
const SENTINEL_MAX_AGE_MS = 30 * 60 * 1000
// Subtask descriptions are capped so oversized prompts don't bloat payloads.
// Keep in sync with HookEventReceiver.cappedTaskDescription prefix(120).
const DESCRIPTION_MAX_LENGTH = 120
const FALLBACK_AGENT_NAME = "Sub-agent"
// How often to re-read the sentinel file from disk.
const SENTINEL_POLL_MS = 2000

let cachedPort = null
// Re-read the port file periodically: the app picks a fresh port on every
// launch, and a plugin instance can easily outlive one (auto-update, relaunch).
const PORT_TTL_MS = 5000
let cachedPortAt = 0

function readPort() {
  const now = Date.now()
  if (cachedPort && now - cachedPortAt < PORT_TTL_MS) return cachedPort
  try {
    const value = readFileSync(PORT_FILE, "utf8").trim()
    if (value) {
      cachedPort = value
      cachedPortAt = now
      return value
    }
  } catch {}
  // File unreadable (app restarting?) — keep serving the last known port.
  return cachedPort
}

export const FactoryFloorPlugin = async ({ project, client, $, directory, worktree }) => {
  const root = worktree || directory || process.cwd()

  let currentSession = null
  try {
    const saved = readFileSync(`${root}/${SESSION_FILE}`, "utf8").trim()
    if (saved) currentSession = saved
  } catch {}

  // childSessionID -> display name ("build", "plan", "general", custom agents)
  const children = new Map()
  // Child sessions whose subtask description has already been forwarded; the
  // subtask part re-fires as it updates, so guard against duplicate posts.
  const describedChildren = new Set()
  // Pending descriptions keyed by child session ID, populated from subtask
  // parts or task-tool calls when currentSession is not yet known.
  const pendingDescriptions = new Map()
  // FIFO queue of task-tool descriptions awaiting their child session.
  const pendingTaskQueue = []
  // Dedup guard for assistant info events: agent_id -> "name|model|contextUsed"
  const lastInfo = new Map()

  function cappedDescription(raw) {
    if (typeof raw !== "string") return ""
    const trimmed = raw.trim()
    if (!trimmed) return ""
    return trimmed.slice(0, DESCRIPTION_MAX_LENGTH)
  }

  function queueTaskDescription(raw) {
    const capped = cappedDescription(raw)
    if (!capped) return
    pendingTaskQueue.push(capped)
    if (pendingTaskQueue.length > 10) pendingTaskQueue.shift()
  }

  let sentinelCache = { value: false, at: 0 }

  function quickActionActive() {
    const now = Date.now()
    if (now - sentinelCache.at < SENTINEL_POLL_MS) return sentinelCache.value
    let active = false
    try {
      const raw = readFileSync(`${root}/${QUICKACTION_SENTINEL}`, "utf8").trim()
      const ts = Number(raw)
      active = raw.length === 0 || (!Number.isNaN(ts) && now - ts < SENTINEL_MAX_AGE_MS)
    } catch {}
    sentinelCache = { value: active, at: now }
    return active
  }

  function adoptSession(id) {
    if (!id || typeof id !== "string") return
    if (currentSession === id) return
    // Quick actions run in the same worktree; never repoint the resume
    // pointer at their forked sessions.
    if (quickActionActive()) return
    currentSession = id
    try {
      mkdirSync(`${root}/${STATE_DIR}`, { recursive: true })
      writeFileSync(`${root}/${SESSION_FILE}`, id)
    } catch {}
  }

  function isChild(sessionID) {
    return !!sessionID && !!currentSession && sessionID !== currentSession
  }

  function agentIdFor(sessionID) {
    return isChild(sessionID) ? sessionID : "main"
  }

  function displayNameFor(sessionID) {
    if (isChild(sessionID)) {
      const known = children.get(sessionID)
      if (known) return known
      if (sessionID) children.set(sessionID, FALLBACK_AGENT_NAME)
      return FALLBACK_AGENT_NAME
    }
    return "OpenCode"
  }

  async function send(payload) {
    if (quickActionActive()) return
    const port = readPort()
    if (!port) return
    try {
      await fetch(`http://127.0.0.1:${port}/hook`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          source: "opencode",
          event_input: payload,
          project_dir: root,
        }),
        signal: AbortSignal.timeout(1000),
      })
    } catch {}
  }

  function extractSessionID(properties) {
    const p = properties || {}
    return (
      p.sessionID ||
      p.info?.sessionID ||
      p.info?.id ||
      p.part?.sessionID ||
      p.message?.sessionID ||
      null
    )
  }

  function extractToolInfo(properties) {
    const p = properties || {}
    const tool =
      p.tool ||
      p.toolName ||
      p.call?.tool ||
      p.call?.toolName ||
      p.part?.tool ||
      "unknown"
    const args = p.args || p.call?.arguments || p.call?.args || p.input || {}
    const filePath =
      args.filePath || args.file_path || args.path || args.notebook_path || args.notebookPath || null
    return { tool, filePath }
  }

  /// Registers a child session so later events carry its real agent name.
  function registerChild(sessionID, agentName) {
    if (!sessionID || !agentName) return false
    children.set(sessionID, agentName)
    return true
  }

  return {
    event: async ({ event }) => {
      const type = event?.type
      const properties = event?.properties || {}

      switch (type) {
        case "tool.execute.before": {
          const { tool, filePath } = extractToolInfo(properties)
          const sessionID = extractSessionID(properties)
          // Capture task-tool descriptions for fallback when subtask parts
          // arrive without a description or before currentSession is known.
          if (tool === "task") {
            const rawArgs = properties.args || properties.call?.arguments || properties.input || {}
            const taskDesc =
              rawArgs.description || rawArgs.Description || rawArgs.desc || null
            queueTaskDescription(taskDesc)
          }
          await send({
            kind: "tool_start",
            tool,
            file_path: filePath || undefined,
            agent_id: agentIdFor(sessionID),
            name: displayNameFor(sessionID),
          })
          break
        }
        case "tool.execute.after": {
          const sessionID = extractSessionID(properties)
          await send({
            kind: "tool_done",
            tool: properties.tool || "unknown",
            agent_id: agentIdFor(sessionID),
            name: displayNameFor(sessionID),
          })
          break
        }
        case "message.updated": {
          const info = properties.info || {}
          if (info.role === "assistant") {
            const sessionID = extractSessionID(properties)
            const aid = agentIdFor(sessionID)
            const name = displayNameFor(sessionID)
            const model = info.modelID || ""
            // Assistant info carries cumulative token counts; sum the
            // context-relevant sides defensively (fields are all optional).
            const tokens = info.tokens
            let contextUsed = 0
            if (tokens && typeof tokens === "object") {
              const cache = tokens.cache || {}
              contextUsed = (tokens.input || 0) + (cache.read || 0) + (cache.write || 0)
            }
            // Context grows across a turn; keep it in the fingerprint so
            // refreshed totals flow through despite identical name/model.
            const fingerprint = `${name}|${model}|${contextUsed}`
            if (lastInfo.get(aid) !== fingerprint) {
              lastInfo.set(aid, fingerprint)
              await send({
                kind: "agent_info",
                agent_id: aid,
                name,
                model: model || undefined,
                ...(contextUsed > 0 ? { context_used: contextUsed } : {}),
              })
            }
          }
          break
        }
        case "message.part.updated": {
          const part = properties.part || {}
          if (part.type === "subtask") {
            // Delegation signal: register the child before its first tool call
            // so the roster shows the real agent name immediately. The part
            // also carries the short task description shown in the TUI header
            // ("Explore Task — Map people/task completion code"); forward it
            // so the sidebar can render it as a subtitle. Registration is
            // unconditional: a child whose first event was a tool_start is
            // stuck with the "Sub-agent" fallback until the real name lands.
            const childID = part.sessionID || null
            const agentName = part.agent || FALLBACK_AGENT_NAME
            const rawDesc = cappedDescription(part.description)
            // If the part's description is empty, try the pending task queue
            // (task tool calls often precede the subtask part).
            let description = rawDesc
            if (!description && pendingTaskQueue.length > 0) {
              description = pendingTaskQueue[0]
            }
            // Always remember the description for the session.created fallback
            // path, even when we cannot send yet (e.g. currentSession unknown).
            if (childID && description) pendingDescriptions.set(childID, description)
            if (childID && currentSession && childID !== currentSession) {
              const isNew = !children.has(childID)
              if (isNew || (description && !describedChildren.has(childID))) {
                registerChild(childID, agentName)
                if (description) {
                  describedChildren.add(childID)
                  // Consume the pending task queue entry we used
                  if (pendingTaskQueue.length > 0 && pendingTaskQueue[0] === description) pendingTaskQueue.shift()
                }
                await send({
                  kind: "session_created",
                  session_id: childID,
                  parent_session_id: currentSession,
                  agent_type: agentName,
                  ...(description ? { description } : {}),
                })
              }
            }
            break
          }
          const role = properties.info?.role || part.role || properties.message?.role || null
          if (role && role !== "assistant") break
          const sessionID = extractSessionID(properties)
          await send({
            kind: "working",
            agent_id: agentIdFor(sessionID),
            name: displayNameFor(sessionID),
          })
          break
        }
        case "permission.asked": {
          await send({ kind: "permission_required" })
          break
        }
        case "permission.replied": {
          const sessionID = extractSessionID(properties)
          await send({
            kind: "working",
            agent_id: agentIdFor(sessionID),
            name: displayNameFor(sessionID),
          })
          break
        }
        case "question.asked": {
          // The question tool blocks mid-turn without ending the session;
          // without this signal the row would keep pulsing "Working".
          await send({ kind: "permission_required" })
          break
        }
        case "question.replied":
        case "question.rejected": {
          const sessionID = extractSessionID(properties)
          await send({
            kind: "working",
            agent_id: agentIdFor(sessionID),
            name: displayNameFor(sessionID),
          })
          break
        }
        case "session.status": {
          const sessionID = extractSessionID(properties)
          const status = properties.status?.type || properties.status
          if (status === "busy" || status === "retry") {
            await send({
              kind: "working",
              agent_id: agentIdFor(sessionID),
              name: displayNameFor(sessionID),
            })
          } else if (status === "idle") {
            await send({ kind: "idle", agent_id: agentIdFor(sessionID) })
          }
          break
        }
        case "session.idle": {
          const sessionID = extractSessionID(properties)
          await send({ kind: "idle", agent_id: agentIdFor(sessionID) })
          break
        }
        case "session.created": {
          const info = properties.info || {}
          const id = info.id || properties.sessionID
          if (info.parentID) {
            const isChildSession = info.parentID && id !== info.parentID
            if (isChildSession) registerChild(id, info.agent || FALLBACK_AGENT_NAME)
            // Attach any pending description for this child (from subtask
            // part that arrived earlier, or from a task tool call).
            let desc = pendingDescriptions.get(id) || null
            if (!desc && pendingTaskQueue.length > 0) {
              desc = pendingTaskQueue[0]
            }
            if (desc && !describedChildren.has(id)) {
              describedChildren.add(id)
              pendingDescriptions.delete(id)
              if (pendingTaskQueue.length > 0 && pendingTaskQueue[0] === desc) pendingTaskQueue.shift()
            }
            await send({
              kind: "session_created",
              session_id: isChildSession ? id : null,
              parent_session_id: info.parentID,
              agent_type: info.agent || FALLBACK_AGENT_NAME,
              ...(desc ? { description: desc } : {}),
            })
          } else if (id) {
            adoptSession(id)
          }
          break
        }
        default:
          break
      }
    },

    "chat.message": async (input, output) => {
      const inputSession = input?.sessionID || output?.message?.sessionID
      if (!currentSession && inputSession) adoptSession(inputSession)

      if (!quickActionActive()) {
        await send({ kind: "waiting", agent_id: "main", name: "OpenCode" })
      }

      try {
        const content = readFileSync(`${root}/${INSTRUCTIONS_FILE}`, "utf8").trim()
        if (content) {
          output.message.system = [output.message.system, content].filter(Boolean).join("\n\n")
        }
      } catch {}
    },

    // Blocking permission hook — fires even when the permission.asked bus
    // event is unavailable in a given CLI version.
    "permission.ask": async () => {
      await send({ kind: "permission_required" })
    },

    // Tool execution HOOKS — OpenCode triggers these around every tool run;
    // tool.* events do NOT arrive through the `event:` bus callback in
    // current versions, so this is what powers the sidebar's activity text.
    // Fire-and-forget on purpose: these hooks run before/after real tool
    // work, so we must never add latency to them.
    "tool.execute.before": (input, output) => {
      const args = output?.args || {}
      const filePath =
        args.filePath || args.file_path || args.path || args.notebook_path || args.notebookPath || null
      if (input?.tool === "task") {
        const taskDesc = args.description || args.Description || args.desc || null
        queueTaskDescription(taskDesc)
      }
      void send({
        kind: "tool_start",
        tool: input?.tool || "unknown",
        file_path: filePath || undefined,
        agent_id: agentIdFor(input?.sessionID),
        name: displayNameFor(input?.sessionID),
      })
    },
    "tool.execute.after": (input) => {
      const sessionID = input?.sessionID
      void send({
        kind: "tool_done",
        tool: input?.tool || "unknown",
        agent_id: agentIdFor(sessionID),
        name: displayNameFor(sessionID),
      })
    },
  }
}
