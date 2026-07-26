#!/bin/sh

acquire_service_lock() {
  service_lock_path=$1
  service_lock_candidate="$service_lock_path.owner.$$"
  service_lock_start=$(ps -o lstart= -p "$$" | sed 's/^[[:space:]]*//')
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
    actual_start_time=$(ps -o lstart= -p "$owner_pid" 2>/dev/null | sed 's/^[[:space:]]*//')
    if [ -z "$actual_start_time" ] || [ "$actual_start_time" != "$expected_start_time" ]; then
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
