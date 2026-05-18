#!/usr/bin/env bash
set -euo pipefail

flake_dir="${1:-.}"
host="${2:-desktop}"
secrets_dir="$HOME/.secrets"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix_eval_errors="$(mktemp)"
trap 'rm -f "$nix_eval_errors"' EXIT

source "$script_dir/lib/doctor-output.sh"

nix_eval_config() {
  if ! nix --extra-experimental-features 'nix-command flakes' \
    eval --json "$flake_dir#homeConfigurations.$host.config" \
    --apply 'config: {
      identities = config.my.identities;
      secrets = config.my.secrets;
      ageSecretNames = builtins.attrNames config.age.secrets;
      ageSecretPaths = builtins.mapAttrs (_: secret: secret.path) config.age.secrets;
    }' \
    2> "$nix_eval_errors"; then
    cat "$nix_eval_errors" >&2
    return 1
  fi
}

config_json="$(nix_eval_config)"

echo
doctor_header "secrets"
echo "host: $host"
if [ -f "$secrets_dir/age_identity" ]; then
  echo "age identity: $(doctor_ok) ($secrets_dir/age_identity)"
else
  echo "age identity: $(doctor_missing) ($secrets_dir/age_identity)"
fi

echo
echo "identities:"
printf '%s\n' "$config_json" | jq -r '.identities[]? // empty' | sed 's/^/- /'

echo
echo "standalone secrets:"
printf '%s\n' "$config_json" | jq -r '.secrets[]? // empty' | sed 's/^/- /'

echo
echo "outputs:"
printf '%s\n' "$config_json" |
  jq -r '.ageSecretPaths | to_entries[] | "\(.key)\t\(.value)"' |
  while IFS=$'\t' read -r name path; do
    if [ -e "$path" ]; then
      printf '%-7s %-28s %s\n' "$(doctor_ok)" "$name" "$path"
    else
      printf '%-7s %-28s %s\n' "$(doctor_missing)" "$name" "$path"
    fi
  done
