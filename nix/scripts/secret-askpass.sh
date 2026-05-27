#!/usr/bin/env bash
# shellcheck shell=bash
# ssh-askpass wrapper that persists passphrases via the freedesktop
# Secret Service API (libsecret / secret-tool). First call per key
# prompts the user; subsequent calls retrieve silently.
#
# If the same parent ssh-add asks twice (i.e. the cached passphrase
# didn't work) we clear the stale entry and fall through to a fresh
# GUI prompt — self-healing against a wrong saved value.
#
# Installed by ssh.nix via writeShellApplication. secret-tool, kdialog/
# zenity and sha1sum are resolved from the ambient PATH.
set -euo pipefail

PROMPT="${1:-}"

# Extract the SSH key path from the prompt as a stable attribute
# for libsecret. Both ssh-add and openssh include the path; trim
# trailing punctuation (e.g. the ":" in "for key '/path/key':").
KEY_PATH=$(printf '%s' "$PROMPT" | grep -oE '/[A-Za-z0-9_./~-]+' | head -1 || true)
KEY_ID="${KEY_PATH:-$PROMPT}"

# Track invocations per ssh-add parent + key. If the marker exists
# we're on a retry — the cached value just failed.
state_dir="${XDG_RUNTIME_DIR:-/tmp}/secret-askpass"
mkdir -p "$state_dir" 2>/dev/null || true
key_hash=$(printf '%s' "$KEY_ID" | sha1sum | cut -c1-16)
marker="$state_dir/$PPID-$key_hash"
# Purge stale markers (>1h) so reused PIDs don't poison us.
find "$state_dir" -maxdepth 1 -type f -mmin +60 -delete 2>/dev/null || true

if [ -f "$marker" ]; then
  # Retry — clear the bad cache and force a fresh prompt below.
  secret-tool clear ssh-passphrase "$KEY_ID" 2>/dev/null || true
else
  touch "$marker"
  if command -v secret-tool >/dev/null 2>&1; then
    if PASSPHRASE=$(secret-tool lookup ssh-passphrase "$KEY_ID" 2>/dev/null) && [ -n "$PASSPHRASE" ]; then
      printf '%s\n' "$PASSPHRASE"
      exit 0
    fi
  fi
fi

PASSPHRASE=""
if [ -n "${KDE_FULL_SESSION:-}" ] && command -v kdialog >/dev/null 2>&1; then
  PASSPHRASE=$(kdialog --title "SSH passphrase" --password "$PROMPT" 2>/dev/null || true)
elif command -v zenity >/dev/null 2>&1; then
  PASSPHRASE=$(zenity --password --title="SSH passphrase" 2>/dev/null || true)
else
  echo "secret-askpass: no GUI prompter (kdialog/zenity) available" >&2
  exit 1
fi

if [ -z "$PASSPHRASE" ]; then
  exit 1
fi

if command -v secret-tool >/dev/null 2>&1; then
  printf '%s' "$PASSPHRASE" \
    | secret-tool store --label="SSH passphrase for $KEY_ID" ssh-passphrase "$KEY_ID" 2>/dev/null \
    || true
fi

printf '%s\n' "$PASSPHRASE"
