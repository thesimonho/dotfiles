#!/bin/bash
CACHE_FILE="$HOME/.cache/ccstatusline-usage.txt"
LOCK_FILE="$HOME/.cache/ccstatusline-usage.lock"

# Read input from stdin (the CC JSON)
CC_INPUT=$(cat)

# Extract context percentage from CC input
CTX_PERCENT=$(echo "$CC_INPUT" | jq -r '(.context_window.used_percentage // 0) | round')

# Function to generate progress bar
make_bar() {
  local pct="$1"
  local width=10
  local filled=$((pct * width / 100))
  local empty=$((width - filled))
  printf "["
  printf "█%.0s" $(seq 1 "$filled")
  printf "░%.0s" $(seq 1 "$empty")
  printf "]"
}

# Build context bar once
CTX_BAR=$(make_bar "$CTX_PERCENT")

# Helper to format final output with context prepended
format_output() {
  echo "C:$CTX_BAR ${CTX_PERCENT}% / $1"
}

# Use cache if < 180 seconds old
if [[ -f "$CACHE_FILE" ]]; then
  AGE=$(($(date +%s) - $(stat -c '%Y' "$CACHE_FILE")))
  if [[ $AGE -lt 180 ]]; then
    format_output "$(cat "$CACHE_FILE")"
    exit 0
  fi
fi

# Rate limit: only try API once per 30 seconds
if [[ -f "$LOCK_FILE" ]]; then
  LOCK_AGE=$(($(date +%s) - $(stat -c '%Y' "$LOCK_FILE")))
  if [[ $LOCK_AGE -lt 30 ]]; then
    if [[ -f "$CACHE_FILE" ]]; then
      format_output "$(cat "$CACHE_FILE")"
      exit 0
    fi
    format_output "[Timeout]"
    exit 1
  fi
fi

touch "$LOCK_FILE"

TOKEN="$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)"
if [[ -z "$TOKEN" ]]; then
  if [[ -f "$CACHE_FILE" ]]; then
    format_output "$(cat "$CACHE_FILE")"
    exit 0
  fi
  format_output "[No credentials]"
  exit 1
fi

RESPONSE=$(curl -s --max-time 5 "https://api.anthropic.com/api/oauth/usage" -H "Authorization: Bearer $TOKEN" -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)

if [[ -z "$RESPONSE" ]]; then
  if [[ -f "$CACHE_FILE" ]]; then
    format_output "$(cat "$CACHE_FILE")"
    exit 0
  fi
  format_output "[API Error]"
  exit 1
fi

SESSION=$(echo "$RESPONSE" | jq -r '(.five_hour.utilization // empty) | round' 2>/dev/null)
WEEKLY=$(echo "$RESPONSE" | jq -r '(.seven_day.utilization // empty) | round' 2>/dev/null)

if [[ -z "$SESSION" || -z "$WEEKLY" ]]; then
  if [[ -f "$CACHE_FILE" ]]; then
    format_output "$(cat "$CACHE_FILE")"
    exit 0
  fi
  format_output "[Parse Error]"
  exit 1
fi

SESSION_BAR=$(make_bar "$SESSION")
WEEKLY_BAR=$(make_bar "$WEEKLY")

OUTPUT="S:$SESSION_BAR ${SESSION}% / W:$WEEKLY_BAR ${WEEKLY}%"
echo "$OUTPUT" >"$CACHE_FILE"
format_output "$OUTPUT"
