#!/usr/bin/env bash
# shellcheck shell=bash
# Manage SSH passphrases stored in libsecret/Secret Service.
# SSH_KEY_PATHS (space-separated absolute paths) is injected by ssh.nix.
set -euo pipefail

: "${SSH_KEY_PATHS:?injected by ssh.nix via writeShellApplication}"
read -ra keys <<<"$SSH_KEY_PATHS"
cmd="${1:-list}"

case "$cmd" in
list)
  for k in "${keys[@]}"; do
    if secret-tool lookup ssh-passphrase "$k" >/dev/null 2>&1; then
      printf '  stored: %s\n' "$k"
    else
      printf '  empty:  %s\n' "$k"
    fi
  done
  ;;
clear)
  for k in "${keys[@]}"; do
    if secret-tool clear ssh-passphrase "$k" 2>/dev/null; then
      printf '  cleared: %s\n' "$k"
    fi
  done
  ;;
clear-one)
  : "${2:?usage: ssh-keys clear-one <key-path>}"
  secret-tool clear ssh-passphrase "$2"
  ;;
show)
  # Print stored passphrases in plaintext. Limit to a single key when one
  # is passed.
  targets=("${keys[@]}")
  [ -n "${2:-}" ] && targets=("$2")
  for k in "${targets[@]}"; do
    if val=$(secret-tool lookup ssh-passphrase "$k" 2>/dev/null) && [ -n "$val" ]; then
      printf '%s: %s\n' "$k" "$val"
    else
      printf '%s: (empty)\n' "$k"
    fi
  done
  ;;
reload)
  systemctl --user start ssh-add-keys.service
  ;;
*)
  echo "usage: ssh-keys [list|show [path]|clear|clear-one <path>|reload]" >&2
  exit 1
  ;;
esac
