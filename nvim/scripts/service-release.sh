#!/bin/sh

set -eu

session_directory=$1
session_lease=$2
shift 2
[ "${1:-}" = "--" ] && shift

lock_directory="$session_directory/.lock"
operation_lock_directory="$session_directory/.operation-lock"
script_directory=${0%/*}
# shellcheck disable=SC1091
. "$script_directory/service-lock.sh"
acquire_service_lock "$operation_lock_directory"
acquire_service_lock "$lock_directory"
is_session_lock_held=true
cleanup() {
  if [ "$is_session_lock_held" = true ]; then
    release_service_lock "$lock_directory"
  fi
  release_service_lock "$operation_lock_directory"
}
trap cleanup EXIT

rm -f -- "$session_lease"

for lease in "$session_directory"/*.lease; do
  [ -f "$lease" ] || continue
  process_id=${lease##*/}
  process_id=${process_id%.lease}
  expected_start_time=$(sed -n '1p' "$lease")
  actual_start_time=$(ps -o lstart= -p "$process_id" 2>/dev/null | sed 's/^[[:space:]]*//')
  if [ -z "$actual_start_time" ] || [ "$actual_start_time" != "$expected_start_time" ]; then
    rm -f -- "$lease"
  fi
done

for lease in "$session_directory"/*.lease; do
  [ -f "$lease" ] && exit 0
done

release_service_lock "$lock_directory"
is_session_lock_held=false
"$@"
