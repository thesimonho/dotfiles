#!/bin/sh

set -eu

session_directory=$1
session_lease=$2
compose_file=$3
service=$4
docker_context=$5
lock_file="$session_directory/.lock"

mkdir -p "$session_directory"

exec 9>"$lock_file"
flock 9

rm -f -- "$session_lease"

for lease in "$session_directory"/*.lease; do
  [ -f "$lease" ] || continue

  lease_name=${lease##*/}
  process_id=${lease_name%%-*}
  expected_start_time=$(sed -n '1p' "$lease")
  process_stat="/proc/$process_id/stat"

  if [ ! -r "$process_stat" ]; then
    rm -f -- "$lease"
    continue
  fi

  process_fields=$(sed 's/^[^)]*) //' "$process_stat")
  # Word splitting maps the stable /proc stat fields onto shell positional parameters.
  # shellcheck disable=SC2086
  set -- $process_fields
  actual_start_time=${20:-}

  if [ "$actual_start_time" != "$expected_start_time" ]; then
    rm -f -- "$lease"
  fi
done

for lease in "$session_directory"/*.lease; do
  if [ -f "$lease" ]; then
    exit 0
  fi
done

if [ -n "$docker_context" ]; then
  docker --context "$docker_context" compose --file "$compose_file" stop "$service"
else
  docker compose --file "$compose_file" stop "$service"
fi
