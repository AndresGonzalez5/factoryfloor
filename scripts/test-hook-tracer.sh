#!/bin/bash
# ABOUTME: Test script to verify the full hook-based agent event lifecycle.
# ABOUTME: Posts all 9 event types in sequence and verifies HTTP 200 responses.

set -euo pipefail

PROJECT_DIR="${1:-/Users/andresgonzalez/.factoryfloor/worktrees/crm-backend/queue-short-fifo}"
PORT_FILE="$HOME/Library/Caches/factoryfloor/hook-port"
SESSION_ID="test-session-$(date +%s)"
PASS=0
FAIL=0

if [ ! -f "$PORT_FILE" ]; then
  echo "ERROR: No port file found at $PORT_FILE"
  echo "Is VibeFloor running?"
  exit 1
fi

PORT=$(cat "$PORT_FILE")
echo "=== Hook Event Lifecycle Test ==="
echo "Port: $PORT"
echo "Project dir: $PROJECT_DIR"
echo "Session: $SESSION_ID"
echo ""

post_event() {
  local label="$1"
  local json="$2"
  local http_code

  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "http://127.0.0.1:${PORT}/hook" \
    -H "Content-Type: application/json" \
    -d "$json" \
    --max-time 5)

  if [ "$http_code" = "200" ]; then
    echo "  PASS  [$label] -> HTTP $http_code"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  [$label] -> HTTP $http_code (expected 200)"
    FAIL=$((FAIL + 1))
  fi
}

# --- Step 1: PreToolUse (Edit) ---
echo "Step 1: PreToolUse (Edit)"
post_event "PreToolUse Edit" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"PreToolUse\",
    \"tool_name\": \"Edit\",
    \"tool_input\": {},
    \"tool_use_id\": \"tu-001\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 2: PostToolUse ---
echo "Step 2: PostToolUse"
post_event "PostToolUse" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"PostToolUse\",
    \"tool_name\": \"Edit\",
    \"tool_input\": {},
    \"tool_use_id\": \"tu-001\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 3: PreToolUse (Read) ---
echo "Step 3: PreToolUse (Read)"
post_event "PreToolUse Read" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"PreToolUse\",
    \"tool_name\": \"Read\",
    \"tool_input\": {},
    \"tool_use_id\": \"tu-002\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 4: PostToolUse ---
echo "Step 4: PostToolUse"
post_event "PostToolUse" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"PostToolUse\",
    \"tool_name\": \"Read\",
    \"tool_input\": {},
    \"tool_use_id\": \"tu-002\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 5: UserPromptSubmit ---
echo "Step 5: UserPromptSubmit"
post_event "UserPromptSubmit" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"UserPromptSubmit\",
    \"prompt\": \"Fix the login bug\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 6: Stop ---
echo "Step 6: Stop"
post_event "Stop" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"Stop\",
    \"stop_hook_active\": true,
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 7: SubagentStart ---
echo "Step 7: SubagentStart (sub-1, Explore)"
post_event "SubagentStart" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"SubagentStart\",
    \"agent_id\": \"sub-1\",
    \"agent_type\": \"Explore\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 8: PreToolUse with agent_id sub-1 (Grep) ---
echo "Step 8: PreToolUse (Grep) on sub-1"
post_event "PreToolUse sub-1 Grep" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"PreToolUse\",
    \"tool_name\": \"Grep\",
    \"tool_input\": {},
    \"tool_use_id\": \"tu-003\",
    \"agent_id\": \"sub-1\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"
sleep 1

# --- Step 9: SubagentStop ---
echo "Step 9: SubagentStop (sub-1)"
post_event "SubagentStop sub-1" "{
  \"event_input\": {
    \"session_id\": \"$SESSION_ID\",
    \"hook_event_name\": \"SubagentStop\",
    \"agent_id\": \"sub-1\",
    \"agent_type\": \"Explore\",
    \"agent_transcript_path\": \"/tmp/sub-1.jsonl\",
    \"cwd\": \"/tmp\",
    \"transcript_path\": \"/tmp/test.jsonl\"
  },
  \"project_dir\": \"$PROJECT_DIR\"
}"

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
