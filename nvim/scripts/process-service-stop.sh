#!/bin/sh

set -eu

pid_file=$1
timeout_ms=$2
state_directory=${pid_file%/*}
lock_directory="$state_directory/.lock"
script_directory=${0%/*}
# shellcheck disable=SC1091
. "$script_directory/service-lock.sh"

mkdir -p "$state_directory"
acquire_service_lock "$lock_directory"
trap 'release_service_lock "$lock_directory"' EXIT

[ -f "$pid_file" ] || exit 0
process_id=$(sed -n '1p' "$pid_file")
expected_start_time=$(sed -n '2p' "$pid_file")
is_owned_process() {
  is_process_identity_current "$process_id" "$expected_start_time"
}

if ! is_owned_process; then
  rm -f -- "$pid_file"
  exit 0
fi

# Signalling the tracked pid alone leaves its children running: a service that
# forks worker processes (inference servers, in practice) leaves them behind
# when it dies, and they pile up one per start/stop cycle until something
# notices the port is busy.
#
# The start script gives the service a process group of its own, so the whole
# tree can be signalled at once. Only do that when the group *is* the service:
# pgid == pid proves this pid leads its own group. A pid file written before
# that change points at a process still sitting in Neovim's group, where a
# group kill would take the editor down -- so an unequal pgid degrades to the
# single-pid behaviour rather than guessing.
process_group=$(ps -o pgid= -p "$process_id" 2>/dev/null | tr -d ' ')
if [ "$process_group" = "$process_id" ]; then
  signal_target="-$process_id"
else
  signal_target="$process_id"
fi

signal_service() {
  kill -"$1" -- "$signal_target" 2>/dev/null || true
}

wait_for() {
  elapsed_ms=0
  while "$1" && [ "$elapsed_ms" -lt "$timeout_ms" ]; do
    sleep 0.1
    elapsed_ms=$((elapsed_ms + 100))
  done
}

signal_service TERM
wait_for is_owned_process
if is_owned_process; then
  signal_service KILL
fi

# The leader exiting does not mean the group is empty -- that is exactly the
# case that stranded orphans before, since the loop above only ever watched
# the leader. Sweep whatever is left in the group on its own budget.
if [ "$process_group" = "$process_id" ]; then
  group_has_members() {
    pgrep -g "$process_id" >/dev/null 2>&1
  }
  if group_has_members; then
    signal_service TERM
    wait_for group_has_members
    if group_has_members; then
      signal_service KILL
    fi
  fi
fi

rm -f -- "$pid_file"
