#!/usr/bin/env bash
# shellcheck shell=bash
# Resolve + validate + store + preset ONE GPG signing passphrase. libsecret-
# backed; the argument is the GPG key id. On the unattended login path it
# retries the lookup (KWallet may still be mid-unlock) and never prompts. The
# GUI prompt fires only when invoked interactively (GPG_PRESET_INTERACTIVE=1,
# i.e. via `gpg-keys reload`).
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

# Read the stored passphrase, retrying briefly: the login oneshot races
# KWallet's unlock and the Secret Service returns empty until the wallet
# finishes opening. An interactive `gpg-keys reload` (GPG_PRESET_INTERACTIVE=1)
# skips the wait — the wallet is already up — so its seed prompt is prompt.
interactive="${GPG_PRESET_INTERACTIVE:-0}"
if [ "$interactive" = 1 ]; then lookup_tries=1; else lookup_tries=15; fi

lookup_passphrase() {
  local i=0 val=""
  while :; do
    val=$(secret-tool lookup gpg-passphrase "$KEY_ID" 2>/dev/null || true)
    [ -n "$val" ] && { printf '%s' "$val"; return 0; }
    i=$((i + 1))
    [ "$i" -ge "$lookup_tries" ] && return 1
    sleep 1
  done
}

newly_prompted=0
if passphrase=$(lookup_passphrase); then
  :
elif [ "$interactive" = 1 ]; then
  passphrase=$(prompt_gui) || exit 1
  newly_prompted=1
else
  # Unattended login: never pop a blocking dialog (that is the surprise prompt
  # and the 60s unit timeout). Defer to the next interactive sign's pinentry or
  # a manual `gpg-keys reload`.
  notify "no stored passphrase for $KEY_ID (KWallet not ready?) — run \`gpg-keys reload\`"
  exit 1
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
