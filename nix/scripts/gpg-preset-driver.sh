#!/usr/bin/env bash
# shellcheck shell=bash
# Preset every signing identity's passphrase at login by delegating to
# gpg-preset. Propagates failure (no exit-swallow) so a bad passphrase shows
# up as a failed unit instead of failing silently.
#
# GPG_SIGNING_KEY_IDS (space-separated) is injected by gpg.nix; gpg-preset
# comes from runtimeInputs.
set -euo pipefail

: "${GPG_SIGNING_KEY_IDS:?injected by gpg.nix via writeShellApplication}"
read -ra _ids <<<"$GPG_SIGNING_KEY_IDS"

rc=0
for _id in "${_ids[@]}"; do
  gpg-preset "$_id" || rc=1
done

exit $rc
