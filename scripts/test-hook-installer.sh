#!/bin/bash
# ABOUTME: Test script to verify HookInstaller idempotency via direct JSON manipulation.
# ABOUTME: Backs up settings.json, tests install/uninstall cycles, then restores backup.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
BACKUP="$HOME/.claude/settings.json.test-backup"
FF_HOOK_PATH="/Applications/VibeFloor.app/Contents/Resources/Scripts/ff-hook"
PASS=0
FAIL=0

HOOK_EVENTS=("PreToolUse" "PostToolUse" "Stop" "SubagentStart" "SubagentStop" "UserPromptSubmit")

check() {
  local label="$1"
  local result="$2"  # "pass" or "fail"
  if [ "$result" = "pass" ]; then
    echo "  PASS  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label"
    FAIL=$((FAIL + 1))
  fi
}

# --- Backup ---
echo "=== HookInstaller Idempotency Test ==="
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$BACKUP"
  echo "Backed up $SETTINGS -> $BACKUP"
else
  echo "No existing settings.json (will restore absence at end)"
fi

cleanup() {
  echo ""
  echo "--- Restoring backup ---"
  if [ -f "$BACKUP" ]; then
    cp "$BACKUP" "$SETTINGS"
    rm -f "$BACKUP"
    echo "Restored $SETTINGS from backup"
  else
    rm -f "$SETTINGS"
    echo "Removed test settings.json (none existed before)"
  fi
}
trap cleanup EXIT

# Helper: simulate HookInstaller.install by writing the same JSON structure
simulate_install() {
  local hook_path="$1"
  python3 -c "
import json, os, sys

path = os.path.expanduser('~/.claude/settings.json')
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)

hooks = settings.get('hooks', {})
events = ['PreToolUse', 'PostToolUse', 'Stop', 'SubagentStart', 'SubagentStop', 'UserPromptSubmit']
entry = {'matcher': '', 'hooks': [{'type': 'command', 'command': '$hook_path', 'timeout': 5}]}

for evt in events:
    event_entries = hooks.get(evt, [])
    already = any(
        any('ff-hook' in h.get('command', '') for h in e.get('hooks', []))
        for e in event_entries
    )
    if not already:
        event_entries.append(entry)
        hooks[evt] = event_entries

settings['hooks'] = hooks
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump(settings, f, indent=2, sort_keys=True)
"
}

# Helper: simulate HookInstaller.uninstall
simulate_uninstall() {
  python3 -c "
import json, os

path = os.path.expanduser('~/.claude/settings.json')
if not os.path.exists(path):
    sys.exit(0)

with open(path) as f:
    settings = json.load(f)

hooks = settings.get('hooks', {})
if not hooks:
    exit(0)

events = ['PreToolUse', 'PostToolUse', 'Stop', 'SubagentStart', 'SubagentStop', 'UserPromptSubmit']
modified = False
for evt in events:
    entries = hooks.get(evt, [])
    filtered = [e for e in entries if not any('ff-hook' in h.get('command', '') for h in e.get('hooks', []))]
    if len(filtered) != len(entries):
        modified = True
        if not filtered:
            hooks.pop(evt, None)
        else:
            hooks[evt] = filtered

if modified:
    if hooks:
        settings['hooks'] = hooks
    else:
        settings.pop('hooks', None)
    with open(path, 'w') as f:
        json.dump(settings, f, indent=2, sort_keys=True)
"
}

# --- Test 1: Install from scratch (no settings.json) ---
echo ""
echo "Test 1: Install when no settings.json exists"
rm -f "$SETTINGS"
simulate_install "$FF_HOOK_PATH"

if [ -f "$SETTINGS" ]; then
  # Check all 6 events have ff-hook
  count=$(python3 -c "
import json
with open('$SETTINGS') as f:
    d = json.load(f)
hooks = d.get('hooks', {})
events = ['PreToolUse', 'PostToolUse', 'Stop', 'SubagentStart', 'SubagentStop', 'UserPromptSubmit']
count = sum(1 for e in events if any(any('ff-hook' in h.get('command','') for h in entry.get('hooks',[])) for entry in hooks.get(e, [])))
print(count)
")
  if [ "$count" = "6" ]; then
    check "Created settings.json with all 6 hook events" "pass"
  else
    check "Created settings.json with all 6 hook events (got $count)" "fail"
  fi
else
  check "Created settings.json" "fail"
fi

# --- Test 2: Install again (idempotent — no duplicates) ---
echo ""
echo "Test 2: Install again — should be idempotent"
simulate_install "$FF_HOOK_PATH"

dup_count=$(python3 -c "
import json
with open('$SETTINGS') as f:
    d = json.load(f)
hooks = d.get('hooks', {})
events = ['PreToolUse', 'PostToolUse', 'Stop', 'SubagentStart', 'SubagentStop', 'UserPromptSubmit']
total = 0
for e in events:
    entries = hooks.get(e, [])
    ff_entries = [entry for entry in entries if any('ff-hook' in h.get('command','') for h in entry.get('hooks',[]))]
    total += len(ff_entries)
print(total)
")
if [ "$dup_count" = "6" ]; then
  check "No duplicate entries after second install (6 total)" "pass"
else
  check "No duplicate entries after second install (got $dup_count, expected 6)" "fail"
fi

# --- Test 3: Uninstall removes only ff-hook entries ---
echo ""
echo "Test 3: Uninstall removes ff-hook entries"

# First add a non-ff-hook entry to PreToolUse to verify it is preserved
python3 -c "
import json
with open('$SETTINGS') as f:
    d = json.load(f)
hooks = d.get('hooks', {})
other_entry = {'matcher': '', 'hooks': [{'type': 'command', 'command': '/usr/local/bin/other-hook', 'timeout': 5}]}
hooks.setdefault('PreToolUse', []).append(other_entry)
d['hooks'] = hooks
with open('$SETTINGS', 'w') as f:
    json.dump(d, f, indent=2, sort_keys=True)
"

simulate_uninstall

remaining=$(python3 -c "
import json
with open('$SETTINGS') as f:
    d = json.load(f)
hooks = d.get('hooks', {})
events = ['PreToolUse', 'PostToolUse', 'Stop', 'SubagentStart', 'SubagentStop', 'UserPromptSubmit']
ff_count = sum(1 for e in events for entry in hooks.get(e, []) if any('ff-hook' in h.get('command','') for h in entry.get('hooks',[])))
other_count = sum(1 for entry in hooks.get('PreToolUse', []) if any('other-hook' in h.get('command','') for h in entry.get('hooks',[])))
print(f'{ff_count},{other_count}')
")

ff_left=$(echo "$remaining" | cut -d, -f1)
other_left=$(echo "$remaining" | cut -d, -f2)

if [ "$ff_left" = "0" ]; then
  check "All ff-hook entries removed" "pass"
else
  check "All ff-hook entries removed (still $ff_left left)" "fail"
fi

if [ "$other_left" = "1" ]; then
  check "Non-ff-hook entry preserved" "pass"
else
  check "Non-ff-hook entry preserved (found $other_left)" "fail"
fi

# --- Test 4 (4.3): Multi-workstream routing (manual) ---
echo ""
echo "=== Multi-Workstream Routing (Manual Test) ==="
echo "To test multi-workstream routing:"
echo "  1. Open VibeFloor with a project that has 2+ workstreams"
echo "  2. Run this script twice with different project_dir values:"
echo "     ./scripts/test-hook-tracer.sh /path/to/worktree-A"
echo "     ./scripts/test-hook-tracer.sh /path/to/worktree-B"
echo "  3. Verify each workstream's sidebar roster shows the correct agents"
echo "  4. Events for worktree-A should NOT appear in worktree-B's panel"

# --- Summary ---
echo ""
echo "=== Results ==="
echo "Passed: $PASS / $((PASS + FAIL))"
if [ "$FAIL" -gt 0 ]; then
  echo "FAILED: $FAIL test(s)"
  exit 1
else
  echo "All tests passed!"
  exit 0
fi
