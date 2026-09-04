# Agent Roster — Architecture

The sidebar shows live agent status per workstream: each row leads with the
main agent's pixel portrait inside a circular state ring — the portrait
carries the main agent's state, current activity, and context meter — and
while subagents are running, a compact roster of two-line mini cards under
the row shows who is doing what right now. The main agent is not listed in
the roster; everything it does is visible on the row itself.

## How it works

Claude Code fires **hooks** at lifecycle events (tool use, session stop,
subagent spawn). A shell script bundled in the app forwards these events to a
local HTTP listener in the Swift app, which routes them to the workstream's
roster in `WorkstreamAgentStateTracker`.

```
Claude Code hooks (settings.json)
  → ff-hook (shell script, reads stdin JSON + CLAUDE_PROJECT_DIR env var)
  → curl POST http://127.0.0.1:{port}/hook
  → HookEventReceiver (NWListener, Swift)
  → FF2App.onEvent → HookEventRouter (fan-out) + WorkstreamAgentStateTracker.handle
  → Sidebar: MainAgentPortrait state ring on the row + WorkstreamAgentRosterView cards
```

## Hook registration

On app launch, `HookInstaller` writes entries into `~/.claude/settings.json`
for these events:

| Hook Event | What it means | AgentEvent | Sidebar effect |
|---|---|---|---|
| `PreToolUse` | Agent is about to use a tool | `agentToolStart` (+ activity) | Run's activity text updates |
| `PostToolUse` | Tool execution finished | `agentToolDone` | Activity cleared |
| `Stop` | Main agent finished its turn | `agentIdle` | Main run ends: activity line and context meter leave the row; blue "finished" ring if unselected |
| `UserPromptSubmit` | User sent a message | `agentWaiting` | Main run starts (working ring on the row) |
| `SubagentStart` | Subagent spawned | `agentCreated` | New roster card for the subagent |
| `SubagentStop` | Subagent finished | `agentRemoved` | That roster card removed |
| `Notification` | Permission prompt / idle nudge | `agentStatus` | Orange permission ring + badge |

Each hook entry uses `type: "command"` pointing to the bundled `ff-hook` script.

Every payload also carries the session's `transcript_path`; the tracker reads
context-window usage from its tail (see [Context window usage](#context-window-usage)).

## Port discovery

The HTTP listener binds to `127.0.0.1` on a dynamic port (OS-assigned via port
0). The actual port is written to `~/Library/Caches/factoryfloor/hook-port`.
The `ff-hook` script reads this file to know where to POST. If the file doesn't
exist (app not running), the script exits silently.

## Multi-workstream routing

There is a **single** HTTP listener shared across all workstreams.
`FF2App` feeds every event through two consumers:

1. `WorkstreamAgentStateTracker.handle(projectDir:event:)` — resolves the
   payload's `project_dir` to a workstream UUID via `workstreamLookup`
   (rebuilt by `ContentView` whenever the project list changes) and updates
   that workstream's roster.
2. `HookEventRouter.route(projectDir:event:)` — fan-out for any additional
   registered handlers (none today; kept for future features).

Unknown `project_dir`s (Claude sessions outside tracked worktrees) are ignored.

Path normalization resolves symlinks and standardizes the path
(`WorkstreamAgentStateTracker.normalize`) so hook payloads and stored
worktree paths match.

## Key files

| File | Role |
|---|---|
| `Resources/Scripts/ff-hook` | Shell script invoked by Claude Code hooks. Reads stdin JSON, wraps with `CLAUDE_PROJECT_DIR`, POSTs to localhost. |
| `Sources/PixelAgents/HookEventReceiver.swift` | NWListener singleton. Parses HTTP POST, maps hook events to `AgentEvent`, derives activity strings from tool name + input, attaches `transcript_path` and OpenCode context figures. |
| `Sources/PixelAgents/HookEventRouter.swift` | Singleton registry routing events by normalized path. |
| `Sources/PixelAgents/HookInstaller.swift` | Idempotent install/uninstall of hook entries in `~/.claude/settings.json`. |
| `Sources/PixelAgents/AgentEvent.swift` | Event model: `agentCreated`, `agentRemoved`, `agentStatus`, `agentToolStart`, `agentToolDone`, `agentIdle`, `agentWaiting`, `agentInfo`, `agentSessionSwitched` (new top-level harness session in the same worktree → reset). |
| `Sources/PixelAgents/TranscriptContextReader.swift` | Extracts context-window usage from Claude Code transcript tails and OpenCode token payloads. |
| `Sources/PixelAgents/ContextLimits.swift` | Maps model IDs to context-window limits (200k default, 1M extended). |
| `Sources/PixelAgents/AgentSpriteStore.swift` | Loads agent portraits for the roster (`avatar_<type>_<k>.png` sets with palette-slot fallback). |
| `Sources/Models/WorkstreamAgentStateTracker.swift` | Per-workstream roster + row-level state machine + stall sweep + live-session tracking + context usage. |
| `Sources/Views/MainAgentPortrait.swift` | Circular pixel portrait leading each workstream row; ring color/pulse encodes state. |
| `Sources/Views/WorkstreamAgentRosterView.swift` | Subagent mini cards under each workstream row. |
| `Sources/Views/ContextMeter.swift` | Context-window meter (bar + percentage) shared by the row and roster cards. |
| `Resources/AgentSprites/` | Avatar art (6 palettes). |
| `scripts/generate-avatars.swift` | Regenerates the 64×64 avatar PNGs from high-resolution source art. |

## Row-level states (`AgentRunState`)

Each workstream row leads with the main agent's portrait (~28pt, circular).
The ring around the character — and how much of the character shows through —
encodes the state:

| State | Portrait treatment | Trigger |
|---|---|---|
| `.idle` (live session) | Desaturated, slightly dimmed character with a thin gray ring | No active turn, but ≥1 hook event seen since app launch |
| `.idle` (dormant) | Character at ~20% opacity, no ring | No active turn and no harness activity this launch |
| `.working` | Full color, pulsing green ring + subtle green glow | `UserPromptSubmit`, tool activity after a permission grant |
| `.stalled` | Pulsing orange ring | No hook events for 45s mid-turn (swept every 15s) |
| `.needsAttention(.permission)` | Static orange ring + orange exclamation badge | Notification hook reports a permission prompt |
| `.needsAttention(.justFinished)` | Static blue ring | `Stop` on an unselected workstream; cleared by `markSeen` when selected |

Whether an idle workstream counts as "live" comes from
`WorkstreamAgentStateTracker.liveSessionIDs` — an in-memory set of
workstreams that saw any harness event this app launch. It is deliberately
not persisted: a workstream nobody touched today renders dormant regardless
of past sessions.

An invalid worktree path overrides all of the above: the row shows a dimmed
character with an orange warning-triangle badge instead of any state ring
(`MainAgentPortrait.isPathValid`).

## Roster lifecycle

- A run exists exactly from its create event (`UserPromptSubmit` /
  `SubagentStart`) to its stop event (`Stop` / `SubagentStop`) — no artificial
  collapse timers.
- The roster lists **subagents only**. The main agent's state ring, current
  activity line, and context meter render on the workstream row itself
  (`WorkstreamRow`), so no information is duplicated.
- Each live subagent renders as a two-line mini card: a 20pt circular portrait
  with its own state ring (green pulsing while working, orange when stalled),
  the agent name plus model chip on the first line, and the current activity
  on the second.
- The trailing side of a card shows, in order of precedence: **"Stalled"**
  (orange label) → **context-window meter** (when the harness reports per-run
  usage) → **elapsed time** since the run started.
- At most 4 cards render inline; extras collapse into "+N more".
- Clicking a card selects the workstream and focuses its Coding Agent tab.
- Removing/archiving/purging a workstream calls `clear(workstreamID:)` so no
  stale state lingers.

## Context window usage

How full the agent's context window is, shown as a small meter. Two sources
depending on harness:

**Claude Code** — every hook payload carries `transcript_path`. On main-agent
events the tracker re-reads the transcript through `TranscriptContextReader`.
Transcripts are append-only JSONL, so only the last 256KB is parsed; the
reader takes the *last* assistant entry carrying `message.usage` and sums
`input_tokens` + `cache_creation_input_tokens` + `cache_read_input_tokens`.
Reads are throttled to one per 5 seconds per workstream — except at turn end
(`Stop`), where the read is forced so the final totals always land. A failed
read keeps the previously known value.

**OpenCode** — the bundled plugin (`factoryfloor-opencode.js`) sums each
assistant message's cumulative tokens (`input` + `cache.read` +
`cache.write`) and forwards the total as `context_used` on `agent_info`
events. The dedup fingerprint includes the session id and the total, so
refreshed figures flow through even when name and model are unchanged, and a
new session never inherits the previous session's fingerprint.

Every plugin payload carries `session_id`. When a new top-level session
replaces the worktree's tracked conversation (e.g. `/new` in the TUI, or a
resumed session's first `chat.message`), the plugin sends `session_switched`
and the tracker resets that workstream — roster, context snapshot, and read
throttle are dropped so the new session's live figures show immediately. A
late `idle` from the superseded session is ignored rather than wiping the new
roster. The same guard exists for Claude: a changed `transcript_path`
mid-stream drops the old snapshot (roster untouched — concurrent Claudes
share the main run and can't be split).

The `question` tool (no dedicated bus event exists) is reported as
`tool_start` **plus** `permission_required`, so a pending user question shows
the orange "Waiting for approval" state and never decays into "Stalled". Its
activity text maps to "Asking question", never the raw tool name. Tool events
are deduped between the direct `tool.execute.*` hooks (primary) and the
`event:`-bus copies, so a future CLI version delivering both won't
double-fire and mask real stalls.

Limits come from `ContextLimits`: 200k tokens by default, 1M when the model
ID contains `[1m]` or `-1m` (case-insensitive, e.g.
`claude-sonnet-4-5[1m]`).

Display scope is the same for both harnesses: the main session's meter shows
on the workstream row itself (visible while the main agent is working or
stalled), preferring the transcript-derived figure and falling back to the
per-run totals OpenCode reports (`WorkstreamAgentStateTracker.mainContextUsage(for:)`),
while OpenCode child sessions carry their own figures
(`AgentRun.contextUsedTokens` / `contextLimitTokens`) from `agent_info`
events, shown on their roster cards. The meter itself is a 40×3pt bar plus a
percentage: green below 60%, orange below 85%, red at 85% or more
(`ContextMeter`).

## Avatars

`AgentSpriteStore` serves one portrait per agent run, resolved in order:

1. **Numbered per-type sets** — `Resources/AgentSprites/avatar_<type>_1.png`,
   `avatar_<type>_2.png`, … where `<type>` is the agent type normalized to
   lowercase alphanumerics (`avatar_explore_1.png`, `avatar_claude_1.png`,
   `avatar_generalpurpose_2.png`). Concurrent same-type agents pick distinct
   sprites: the tracker assigns each run the lowest variant index not held by
   a live same-type run, and the sprite shown is
   `set[variantIndex % count]` — so the 5th of 4 Explore sprites cycles back
   to sprite 1. A run keeps its sprite for its whole lifetime.
2. **Single type portrait** — `avatar_<type>.png` for types without variants.
3. **Palette slots** — `avatar_<0-5>.png` fallback.

Types with no art at all resolve to nil; views substitute a neutral SF Symbol
placeholder (`person.crop.circle.fill`).

Types can also **alias** to another set (`typeAliases` in `AgentSpriteStore`),
covering harnesses whose built-ins lack dedicated art: OpenCode's `build` →
claude, `general` → generalpurpose, `ask`/`scout` → explore. A type's own art
always wins — dropping `avatar_<type>_1.png` immediately overrides the alias,
no code changes.

Assets are 64×64 PNGs normalized to 32pt (`AgentSpriteStore.pointSize`);
views render them with `.interpolation(.none)` for crisp pixels on Retina.

To regenerate the numbered avatars from source art (1024×1024 PNGs):

```bash
swift scripts/generate-avatars.swift <source-dir> <output-dir>
```

The script crops each mapped source to its alpha bounding box, adds ~4%
padding per axis, squares the frame around the character's center, downscales
to exactly 64×64 with high-quality interpolation, and preserves transparency.
Its source map lives at the top of the script; add an entry there when
introducing new art (e.g. a new agent type).

To add sprites for a new agent type (or extend a set): drop 64×64
`avatar_<type>_<k>.png` files into `Resources/AgentSprites/` — they are
enumerated automatically, no code changes.

## Testing

```bash
# Full lifecycle test (requires app running with a workstream open)
bash scripts/test-hook-tracer.sh /path/to/worktree

# HookInstaller idempotency test
bash scripts/test-hook-installer.sh
```

Unit tests for roster transitions live alongside other XCTest suites.

## Troubleshooting

**No roster appears:** Check that hooks are installed:
```bash
cat ~/.claude/settings.json | python3 -m json.tool | grep ff-hook
```

**Port file missing:** The app writes `~/Library/Caches/factoryfloor/hook-port`
on startup. If it's missing, the receiver failed to bind — check Console.app
for `factoryfloor:hook-receiver` logs.

**Wrong workstream:** The hook's `CLAUDE_PROJECT_DIR` must match the stored
worktree path (e.g. `~/.factoryfloor/worktrees/project/workstream-name`). Watch routing logs:
```bash
log stream --predicate 'subsystem == "factoryfloor"' --info | grep -i hook
```
