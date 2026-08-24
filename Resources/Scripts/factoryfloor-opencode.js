// ABOUTME: OpenCode plugin auto-installed by VibeFloor.
// ABOUTME: Forwards agent events to the app's local HTTP receiver, tracks the
// ABOUTME: current session id for resume, and appends Factory Floor system
// ABOUTME: instructions from .factoryfloor-state/instructions.md to each turn.

import { readFileSync, writeFileSync, mkdirSync } from "node:fs"

const PORT_FILE = `${process.env.HOME}/Library/Caches/factoryfloor/hook-port`
const STATE_DIR = ".factoryfloor-state"
const SESSION_FILE = `${STATE_DIR}/opencode-session`
const INSTRUCTIONS_FILE = `${STATE_DIR}/instructions.md`

let cachedPort = null

function readPort() {
  if (cachedPort) return cachedPort
  try {
    const value = readFileSync(PORT_FILE, "utf8").trim()
    if (value) cachedPort = value
  } catch {}
  return cachedPort
}

export const FactoryFloorPlugin = async ({ project, client, $, directory, worktree }) => {
  const root = worktree || directory || process.cwd()

  let currentSession = null
  try {
    const saved = readFileSync(`${root}/${SESSION_FILE}`, "utf8").trim()
    if (saved) currentSession = saved
  } catch {}

  function adoptSession(id) {
    if (!id || typeof id !== "string") return
    if (currentSession === id) return
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

  async function send(payload) {
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

  return {
    event: async ({ event }) => {
      const type = event?.type
      const properties = event?.properties || {}

      switch (type) {
        case "tool.execute.before": {
          const { tool, filePath } = extractToolInfo(properties)
          const sessionID = extractSessionID(properties)
          await send({
            kind: "tool_start",
            tool,
            file_path: filePath || undefined,
            agent_id: agentIdFor(sessionID),
            name: "OpenCode",
          })
          break
        }
        case "tool.execute.after": {
          const sessionID = extractSessionID(properties)
          await send({
            kind: "tool_done",
            tool: properties.tool || "unknown",
            agent_id: agentIdFor(sessionID),
            name: "OpenCode",
          })
          break
        }
        case "message.updated":
        case "message.part.updated": {
          const role =
            properties.info?.role || properties.part?.role || properties.message?.role || null
          if (role && role !== "assistant") break
          const sessionID = extractSessionID(properties)
          await send({ kind: "working", agent_id: agentIdFor(sessionID), name: "OpenCode" })
          break
        }
        case "permission.asked": {
          await send({ kind: "permission_required" })
          break
        }
        case "permission.replied": {
          const sessionID = extractSessionID(properties)
          await send({ kind: "working", agent_id: agentIdFor(sessionID), name: "OpenCode" })
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
            await send({
              kind: "session_created",
              session_id: info.parentID && id !== info.parentID ? id : null,
              parent_session_id: info.parentID,
              agent_type: info.agent || "Sub-agent",
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

      await send({ kind: "waiting", agent_id: "main", name: "OpenCode" })

      try {
        const content = readFileSync(`${root}/${INSTRUCTIONS_FILE}`, "utf8").trim()
        if (content) {
          output.message.system = [output.message.system, content].filter(Boolean).join("\n\n")
        }
      } catch {}
    },
  }
}
