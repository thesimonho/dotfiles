#!/usr/bin/env bash
#
# clock.sh — time-budget tracker for the deep-research skill.
#
# Pull-based by design: a script cannot preempt an agent's reasoning loop, so
# the agent calls `check` between gather rounds and acts on the emitted verdict.
# The value here is consolidation + a directive (not a raw timestamp the agent
# has to subtract and self-police).
#
# Portable across agents: depends only on bash, date, and basic coreutils.
# State lives in a notes dir in the CURRENT working directory (the project),
# NOT next to this script — override with RESEARCH_DIR.
#
# Usage:
#   clock.sh start <budget_seconds>   # begin the clock (e.g. 600 for ~10 min)
#   clock.sh log <message...>         # append a timestamped trail entry
#   clock.sh check                    # emit "elapsed/budget (pct) -> VERDICT"
#   clock.sh elapsed                  # print elapsed seconds + mm:ss (for footer)
#   clock.sh end                      # run complete: clear scratch, keep report

set -euo pipefail

DIR="${RESEARCH_DIR:-docs/deep-research}"
CLOCK_FILE="$DIR/.clock" # one line: "<start_epoch> <budget_seconds>"
LOG_FILE="$DIR/timing.log"

now() { date +%s; }
stamp() { date +%H:%M:%S; }

die() {
  echo "clock.sh: $1" >&2
  exit 2
}

require_started() {
  [ -r "$CLOCK_FILE" ] ||
    die "clock not started — run 'clock.sh start <budget_seconds>' first"
}

fmt_mmss() {
  local s="$1"
  printf '%dm%02ds' "$((s / 60))" "$((s % 60))"
}

# Read the combined clock file into START_TS and BUDGET.
read_clock() {
  read -r START_TS BUDGET <"$CLOCK_FILE" || die "clock file unreadable"
  case "$START_TS$BUDGET" in
  '' | *[!0-9]*) die "clock file corrupt — re-run 'clock.sh start'" ;;
  esac
}

# Remove sub-question notes, the query anchor and clock state. Keeps the report
# (*.html) and, optionally, the pacing trace (timing.log). Used both at run
# start (fresh slate; also wipes the trace) and run end (leave the deliverable).
clear_workspace() {
  local keep_log="$1" # 1 = preserve timing.log, 0 = delete it too
  rm -f "$CLOCK_FILE" 2>/dev/null || true
  find "$DIR" -maxdepth 1 -type f -name '*.md' -delete 2>/dev/null || true
  [ "$keep_log" -eq 1 ] || rm -f "$LOG_FILE" 2>/dev/null || true
}

# Drop a self-contained .gitignore in the workspace so scratch state never gets
# committed, regardless of which project the skill runs in. Only the report is
# allowed through. Idempotent (rewritten each run).
write_gitignore() {
  cat >"$DIR/.gitignore" <<'EOF'
# deep-research workspace — scratch state, not for commit.
# Only the HTML report(s) are allowed through (reports carry task-relevant names).
*
!.gitignore
!*.html
EOF
}

cmd="${1:-}"
shift || true

case "$cmd" in
start)
  [ $# -ge 1 ] || die "usage: clock.sh start <budget_seconds>"
  case "$1" in
  '' | *[!0-9]*) die "budget must be a positive integer number of seconds" ;;
  esac
  [ "$1" -gt 0 ] || die "budget must be greater than zero seconds"
  mkdir -p "$DIR"
  clear_workspace 0
  write_gitignore
  printf '%s %s\n' "$(now)" "$1" >"$CLOCK_FILE"
  echo "$(stamp) | START — budget ${1}s" >>"$LOG_FILE"
  echo "clock started — budget ${1}s ($(fmt_mmss "$1"))"
  ;;

log)
  require_started
  [ $# -ge 1 ] || die "usage: clock.sh log <message...>"
  echo "$(stamp) | $*" >>"$LOG_FILE"
  ;;

check)
  require_started
  read_clock
  e=$(($(now) - START_TS))
  p=$((e * 100 / BUDGET))
  if [ "$p" -ge 80 ]; then
    v="STOP GATHERING — SYNTHESIZE NOW"
  elif [ "$p" -ge 50 ]; then
    v="HALFWAY — prioritize remaining sub-questions"
  else v="OK to continue"; fi
  line="elapsed ${e}s / budget ${BUDGET}s (${p}%) -> ${v}"
  echo "$(stamp) | CHECK — ${line}" >>"$LOG_FILE"
  echo "$line"
  ;;

elapsed)
  require_started
  read_clock
  e=$(($(now) - START_TS))
  echo "${e}s ($(fmt_mmss "$e"))"
  ;;

end)
  # Run complete. Clear working notes + clock state but keep the deliverable
  # (the *.html report) and the pacing trace (timing.log) for inspection.
  [ -f "$LOG_FILE" ] && echo "$(stamp) | END — cleared working notes" >>"$LOG_FILE"
  clear_workspace 1
  echo "run ended — cleared working notes (kept report + timing.log)"
  ;;

*)
  die "unknown command '${cmd:-}' — expected: start | log | check | elapsed | end"
  ;;
esac
