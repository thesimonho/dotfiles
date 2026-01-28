#!/usr/bin/env bash
# Log Claude Code hook events and archive transcripts
# Usage: Called by Claude Code hooks with JSON on stdin
# Config: Set CLAUDE_LOG_DIR (default: ~/.claude-logs)

set -euo pipefail

# Configuration
LOG_DIR="${CLAUDE_LOG_DIR:-$HOME/.claude-logs}"

# Read JSON from stdin
if [ -t 0 ]; then
  echo "Error: Expected JSON on stdin" >&2
  exit 0
fi

stdin_data=$(cat)

# Validate JSON and extract fields
if ! session_id=$(echo "$stdin_data" | jq -r '.session_id // empty' 2>/dev/null); then
  echo "Error: Failed to parse JSON from stdin" >&2
  exit 0
fi

if [ -z "$session_id" ]; then
  echo "Error: No session_id found in JSON" >&2
  exit 0
fi

transcript_path=$(echo "$stdin_data" | jq -r '.transcript_path // empty' 2>/dev/null)

# Create session directory
SESSION_DIR="$LOG_DIR/$session_id"
mkdir -p "$SESSION_DIR"

HOOKS_LOG="$SESSION_DIR/hooks.jsonl"
TRANSCRIPT_FILE="$SESSION_DIR/transcript.jsonl"

# Build log entry with timestamp and session_id at top level
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
log_entry=$(echo "$stdin_data" | jq -c \
  --arg ts "$timestamp" \
  --arg sid "$session_id" \
  '{timestamp: $ts, session_id: $sid, data: .}')

# Append to hooks log
echo "$log_entry" >>"$HOOKS_LOG"

# Copy transcript if it exists and is readable
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ] && [ -r "$transcript_path" ]; then
  cp "$transcript_path" "$TRANSCRIPT_FILE" 2>/dev/null || {
    echo "Warning: Failed to copy transcript from $transcript_path" >&2
  }
else
  echo "Debug: transcript_path='$transcript_path', exists=$([ -f "$transcript_path" ] && echo yes || echo no)" >&2
fi

exit 0
