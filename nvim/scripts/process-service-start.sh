#!/bin/sh

set -eu

pid_file=$1
log_file=$2
working_directory=$3
shift 3
[ "${1:-}" = "--" ] && shift

state_directory=${pid_file%/*}
lock_directory="$state_directory/.lock"
pid_file_buffer="$pid_file.$$"
script_directory=${0%/*}
# shellcheck disable=SC1091
. "$script_directory/service-lock.sh"

mkdir -p "$state_directory" "${log_file%/*}"
acquire_service_lock "$lock_directory"
trap 'rm -f -- "$pid_file_buffer"; release_service_lock "$lock_directory"' EXIT

if [ -f "$pid_file" ]; then
  existing_pid=$(sed -n '1p' "$pid_file")
  expected_start_time=$(sed -n '2p' "$pid_file")
  actual_start_time=$(ps -o lstart= -p "$existing_pid" 2>/dev/null | sed 's/^[[:space:]]*//')
  if [ -n "$actual_start_time" ] && [ "$actual_start_time" = "$expected_start_time" ]; then
    exit 0
  fi
  rm -f -- "$pid_file"
fi

if [ -n "$working_directory" ]; then
  cd "$working_directory"
fi
nohup "$@" >>"$log_file" 2>&1 &
process_id=$!

process_start_time=""
attempt=0
while [ -z "$process_start_time" ] && [ "$attempt" -lt 20 ]; do
  process_start_time=$(ps -o lstart= -p "$process_id" 2>/dev/null | sed 's/^[[:space:]]*//')
  attempt=$((attempt + 1))
  [ -n "$process_start_time" ] || sleep 0.05
done

if [ -z "$process_start_time" ]; then
  kill -TERM "$process_id" 2>/dev/null || true
  exit 1
fi
printf '%s\n%s\n' "$process_id" "$process_start_time" >"$pid_file_buffer"
mv -f -- "$pid_file_buffer" "$pid_file"
