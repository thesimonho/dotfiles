#!/bin/sh

get_process_start_time() {
  # macOS ps pads lstart with trailing spaces; trim both ends so this value
  # compares equal to the Lua side's trimmed reading.
  ps -o lstart= -p "$1" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

is_process_identity_current() {
  actual_start_time=$(get_process_start_time "$1")
  [ -n "$actual_start_time" ] && [ "$actual_start_time" = "$2" ]
}

acquire_service_lock() {
  service_lock_path=$1
  service_lock_candidate="$service_lock_path.owner.$$"
  service_lock_start=$(get_process_start_time "$$")
  printf '%s\n%s\n' "$$" "$service_lock_start" >"$service_lock_candidate"

  while :; do
    # Clean up directory locks left by older versions of this helper.
    if [ -d "$service_lock_path" ]; then
      rmdir "$service_lock_path" 2>/dev/null || true
      sleep 0.05
      continue
    fi

    if ln "$service_lock_candidate" "$service_lock_path" 2>/dev/null; then
      break
    fi

    owner_pid=$(sed -n '1p' "$service_lock_path" 2>/dev/null || true)
    expected_start_time=$(sed -n '2p' "$service_lock_path" 2>/dev/null || true)
    if ! is_process_identity_current "$owner_pid" "$expected_start_time"; then
      rm -f -- "$service_lock_path"
    fi
    sleep 0.05
  done
}

release_service_lock() {
  service_lock_path=$1
  service_lock_candidate="$service_lock_path.owner.$$"
  if cmp -s "$service_lock_candidate" "$service_lock_path"; then
    rm -f -- "$service_lock_path"
  fi
  rm -f -- "$service_lock_candidate"
}
