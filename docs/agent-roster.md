# Agent Roster — Architecture

The sidebar shows live agent status per workstream: a state dot on each row, an
active-agent count badge, and — while agents are running — a compact roster of
one line per agent (main + subagents) showing who is doing what right now.

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
  → Sidebar: WorkstreamRow dot/badge + WorkstreamAgentRosterView lines
```

## Hook registration

On app launch, `HookInstaller` writes entries into `~/.claude/settings.json`
for these events:

| Hook Event | What it means | AgentEvent | Sidebar effect |
|---|---|---|---|
| `PreToolUse` | Agent is about to use a tool | `agentToolStart` (+ activity) | Run's activity text updates |
| `PostToolUse` | Tool execution finished | `agentToolDone` | Activity cleared |
| `Stop` | Main agent finished its turn | `agentIdle` | Main run line removed; blue "finished" dot if unselected |
| `UserPromptSubmit` | User sent a message | `agentWaiting` | Main run line appears/updates (working) |
| `SubagentStart` | Subagent spawned | `agentCreated` | New roster line for the subagent |
| `SubagentStop` | Subagent finished | `agentRemoved` | That roster line removed |
| `Notification` | Permission prompt / idle nudge | `agentStatus` | Orange permission dot |

Each hook entry uses `type: "command"` pointing to the bundled `ff-hook` script.

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
| `Sources/PixelAgents/HookEventReceiver.swift` | NWListener singleton. Parses HTTP POST, maps hook events to `AgentEvent`, derives activity strings from tool name + input. |
| `Sources/PixelAgents/HookEventRouter.swift` | Singleton registry routing events by normalized path. |
| `Sources/PixelAgents/HookInstaller.swift` | Idempotent install/uninstall of hook entries in `~/.claude/settings.json`. |
| `Sources/PixelAgents/AgentEvent.swift` | Event model: `agentCreated`, `agentRemoved`, `agentStatus`, `agentToolStart`, `agentToolDone`, `agentIdle`, `agentWaiting`. |
| `Sources/PixelAgents/AgentSpriteStore.swift` | Loads agent portraits for the roster (`avatar_N.png`, falling back to cropped legacy sheets). |
| `Sources/Models/WorkstreamAgentStateTracker.swift` | Per-workstream roster + row-level state machine + stall sweep. |
| `Sources/Views/WorkstreamAgentRosterView.swift` | Roster lines under each workstream row. |
| `Resources/AgentSprites/` | Avatar art (6 palettes). |

## Row-level states (`AgentRunState`)

| State | Dot | Trigger |
|---|---|---|
| `.idle` | gray | No active turn |
| `.working` | pulsing green | `UserPromptSubmit`, tool activity after a permission grant |
| `.stalled` | pulsing amber | No hook events for 45s mid-turn (swept every 15s) |
| `.needsAttention(.permission)` | solid orange | Notification hook reports a permission prompt |
| `.needsAttention(.justFinished)` | solid blue | `Stop` on an unselected workstream; cleared by `markSeen` when selected |

## Roster lifecycle

- A run line exists exactly from its create event (`UserPromptSubmit` /
  `SubagentStart`) to its stop event (`Stop` / `SubagentStop`) — no artificial
  collapse timers.
- Stalled runs keep their line but turn amber with a "Stalled" label.
- At most 4 lines render inline; extras collapse into "+N more".
- Clicking a line selects the workstream and focuses its Coding Agent tab.
- Removing/archiving/purging a workstream calls `clear(workstreamID:)` so no
  stale state lingers.

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
4. **Legacy sheets** — `char_<0-5>.png` 112×96 sprite sheets; the head of the
   front-facing idle frame (frame 1 at x=16..32, y=0..16) is cropped.

To add sprites for a new agent type (or extend a set): drop 32×32
`avatar_<type>_<k>.png` files into `Resources/AgentSprites/` — they are
enumerated automatically, no code changes. Portraits are cropped to the
character with ~4% padding, downscaled with high-quality resampling, keep a
transparent background, and render with `.interpolation(.none)` for crisp
pixels on Retina.

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
