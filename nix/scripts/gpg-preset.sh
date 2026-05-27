#!/usr/bin/env bash
# shellcheck shell=bash
# Resolve + validate + store + preset ONE GPG signing passphrase. libsecret-
# backed, GUI-prompt-on-miss; the argument is the GPG key id.
#
# Unlike SSH's askpass, gpg-preset-passphrase does NOT validate the value it's
# given, so we test-sign throwaway data first and never store or preset a value
# that won't actually sign.
#
# Installed by gpg.nix via writeShellApplication; gpg/gpgconf come from
# runtimeInputs, secret-tool and kdialog/zenity from the ambient PATH.
set -euo pipefail

KEY_ID="${1:?usage: gpg-preset <keyId>}"
PRESET="$(gpgconf --list-dirs libexecdir)/gpg-preset-passphrase"

notify() {
  if [ -n "${KDE_FULL_SESSION:-}" ] && command -v kdialog >/dev/null 2>&1; then
    kdialog --title "GPG" --passivepopup "$1" 8 >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical "GPG" "$1" >/dev/null 2>&1 || true
  fi
  # Always echo to stderr — the only signal on headless WSL, where systemd
  # captures it into the unit journal.
  echo "gpg-preset: $1" >&2
}

# First sign-capable keygrip from colons output: the sec/ssb record whose
# capability field (12) contains 's', then its following grp line. Resolved at
# runtime so subkey rotation can't desync a hardcoded grip.
resolve_keygrip() {
  gpg --batch --with-colons --with-keygrip --list-secret-keys "$KEY_ID" 2>/dev/null \
    | awk -F: '
        /^(sec|ssb):/ { signcap = (index($12, "s") > 0) }
        /^grp:/       { if (signcap) { print $10; exit } }
      ' || true
}

# Pop a GUI passphrase prompt (KWallet via kdialog on KDE, else zenity).
prompt_gui() {
  local p=""
  if [ -n "${KDE_FULL_SESSION:-}" ] && command -v kdialog >/dev/null 2>&1; then
    p=$(kdialog --title "GPG passphrase" --password "Passphrase for GPG key $KEY_ID" 2>/dev/null || true)
  elif command -v zenity >/dev/null 2>&1; then
    p=$(zenity --password --title="GPG passphrase ($KEY_ID)" 2>/dev/null || true)
  else
    notify "no GUI prompter (kdialog/zenity) available for $KEY_ID"
    return 1
  fi
  [ -n "$p" ] || return 1
  printf '%s' "$p"
}

# Test-sign throwaway data via loopback; exit 0 only if the passphrase actually
# unlocks the signing key. This is the GPG self-heal.
validate() {
  printf 'validate' | gpg --batch --no-tty \
    --pinentry-mode loopback --passphrase-fd 3 \
    -u "$KEY_ID" -s -o /dev/null 3<<<"$1"
}

keygrip=$(resolve_keygrip)
if [ -z "$keygrip" ]; then
  notify "no sign-capable keygrip found for $KEY_ID"
  exit 1
fi

newly_prompted=0
passphrase=$(secret-tool lookup gpg-passphrase "$KEY_ID" 2>/dev/null || true)
if [ -z "$passphrase" ]; then
  passphrase=$(prompt_gui) || exit 1
  newly_prompted=1
fi

attempts=0
while ! validate "$passphrase"; do
  if [ "$newly_prompted" -eq 1 ] && [ "$attempts" -lt 2 ]; then
    attempts=$((attempts + 1))
    passphrase=$(prompt_gui) || exit 1
    continue
  fi
  if [ "$newly_prompted" -eq 1 ]; then
    notify "GPG passphrase for $KEY_ID rejected after retries"
    exit 1
  fi
  # Stored value is stale/poisoned: clear it and bail rather than loop on the
  # unattended boot path. Re-seed with `gpg-keys reload`.
  secret-tool clear gpg-passphrase "$KEY_ID" 2>/dev/null || true
  notify "stored GPG passphrase for $KEY_ID was invalid — cleared; run \`gpg-keys reload\`"
  exit 1
done

if [ "$newly_prompted" -eq 1 ]; then
  printf '%s' "$passphrase" \
    | secret-tool store --label="GPG passphrase for $KEY_ID" gpg-passphrase "$KEY_ID"
fi

# Preset into the agent. set -o pipefail propagates a preset failure.
printf '%s' "$passphrase" | "$PRESET" --preset "$keygrip"
