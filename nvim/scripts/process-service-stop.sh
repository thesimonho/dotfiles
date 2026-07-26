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
  actual_start_time=$(ps -o lstart= -p "$process_id" 2>/dev/null | sed 's/^[[:space:]]*//')
  [ -n "$actual_start_time" ] && [ "$actual_start_time" = "$expected_start_time" ]
}

if ! is_owned_process; then
  rm -f -- "$pid_file"
  exit 0
fi

kill -TERM "$process_id" 2>/dev/null || true
elapsed_ms=0
while is_owned_process && [ "$elapsed_ms" -lt "$timeout_ms" ]; do
  sleep 0.1
  elapsed_ms=$((elapsed_ms + 100))
done

if is_owned_process; then
  kill -KILL "$process_id" 2>/dev/null || true
fi
rm -f -- "$pid_file"
