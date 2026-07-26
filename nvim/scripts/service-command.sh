#!/bin/sh

set -eu

lock_directory=$1
shift
[ "${1:-}" = "--" ] && shift
script_directory=${0%/*}
# shellcheck disable=SC1091
. "$script_directory/service-lock.sh"

acquire_service_lock "$lock_directory"
trap 'release_service_lock "$lock_directory"' EXIT
"$@"
