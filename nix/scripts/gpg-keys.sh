#!/usr/bin/env bash
# shellcheck shell=bash
# Manage GPG signing passphrases stored in libsecret/Secret Service.
# GPG_SIGNING_KEY_IDS (space-separated) is injected by gpg.nix.
set -euo pipefail

: "${GPG_SIGNING_KEY_IDS:?injected by gpg.nix via writeShellApplication}"
read -ra keys <<<"$GPG_SIGNING_KEY_IDS"
cmd="${1:-list}"

case "$cmd" in
list)
  for k in "${keys[@]}"; do
    if secret-tool lookup gpg-passphrase "$k" >/dev/null 2>&1; then
      printf '  stored: %s\n' "$k"
    else
      printf '  empty:  %s\n' "$k"
    fi
  done
  ;;
show)
  targets=("${keys[@]}")
  [ -n "${2:-}" ] && targets=("$2")
  for k in "${targets[@]}"; do
    if val=$(secret-tool lookup gpg-passphrase "$k" 2>/dev/null) && [ -n "$val" ]; then
      printf '%s: %s\n' "$k" "$val"
    else
      printf '%s: (empty)\n' "$k"
    fi
  done
  ;;
clear)
  for k in "${keys[@]}"; do
    if secret-tool clear gpg-passphrase "$k" 2>/dev/null; then
      printf '  cleared: %s\n' "$k"
    fi
  done
  ;;
clear-one)
  : "${2:?usage: gpg-keys clear-one <keyId>}"
  secret-tool clear gpg-passphrase "$2"
  ;;
reload)
  # Run the driver interactively so a missing passphrase can be (re)seeded via
  # the GUI prompt. The systemd oneshot stays non-interactive (retry-then-defer,
  # never a dialog), so this is the one path allowed to prompt.
  GPG_PRESET_INTERACTIVE=1 gpg-preset-driver
  ;;
*)
  echo "usage: gpg-keys [list|show [keyId]|clear|clear-one <keyId>|reload]" >&2
  exit 1
  ;;
esac
