#!/bin/sh

set -eu

session_directory=$1
session_lease=$2
process_start_time=$3
lock_directory="$session_directory/.lock"
script_directory=${0%/*}
# shellcheck disable=SC1091
. "$script_directory/service-lock.sh"

mkdir -p "$session_directory"
acquire_service_lock "$lock_directory"
trap 'release_service_lock "$lock_directory"' EXIT

printf '%s\n' "$process_start_time" >"$session_lease"
