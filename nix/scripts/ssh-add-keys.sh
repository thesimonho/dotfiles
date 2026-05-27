#!/usr/bin/env bash
# shellcheck shell=bash
# Load SSH identity keys into the agent. The askpass wrapper handles
# lookup/store via libsecret; first invocation per key shows a GUI prompt,
# subsequent runs are silent.
#
# SSH_KEY_PATHS (space-separated absolute paths) is injected by ssh.nix via
# writeShellApplication; ssh-add comes from runtimeInputs, kdialog/notify-send
# from the ambient PATH.
set -euo pipefail

: "${SSH_KEY_PATHS:?injected by ssh.nix via writeShellApplication}"
read -ra _keys <<<"$SSH_KEY_PATHS"

# Surface ssh-add failures so they don't fail silently.
notify() {
  if [ -n "${KDE_FULL_SESSION:-}" ] && command -v kdialog >/dev/null 2>&1; then
    kdialog --title "SSH" --passivepopup "$1" 8 >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical "SSH" "$1" >/dev/null 2>&1 || true
  fi
  # Always echo to stderr too — the only signal on headless / no-notification
  # hosts (e.g. WSL); systemd captures it into the unit's journal.
  echo "ssh-add-keys: $1" >&2
}

# Load every key we can, then exit non-zero if any failed, so callers (and the
# per-boot shell hook's retry marker) can tell. Mirrors gpg-preset-driver.
rc=0
add_key() {
  local key="$1"
  [ -f "$key" ] || return 0
  if ! ssh-add -q "$key" </dev/null; then
    notify "Failed to load $key — run \`ssh-keys clear-one $key\` and retry."
    rc=1
  fi
}

for _key in "${_keys[@]}"; do
  add_key "$_key"
done

exit $rc
