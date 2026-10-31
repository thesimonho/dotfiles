#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf '1Password check: %s\n' "$*" >&2
  exit 1
}

[[ $(uname -s) == Linux && -x /usr/bin/pacman ]] ||
  fail 'This check supports native Arch Linux installations only.'

op_path=$(command -v op || true)
[[ -n "$op_path" ]] || fail 'Install the native 1password-cli package first.'
[[ $(readlink -f "$op_path") == /usr/bin/op ]] ||
  fail 'Another op executable shadows /usr/bin/op. Remove that PATH conflict.'
[[ $(pacman -Qqo /usr/bin/op) == 1password-cli ]] ||
  fail '/usr/bin/op must be owned by the native 1password-cli package.'
[[ $(stat -c %U:%G /usr/bin/op) == root:onepassword-cli && -g /usr/bin/op ]] ||
  fail 'Reinstall 1password-cli to restore root:onepassword-cli ownership and setgid permissions.'

# Do not mistake service-account, Connect, or cached session authentication for
# successful desktop integration. Check names only; never print their values.
for variable in ${!OP_SESSION_@} OP_SERVICE_ACCOUNT_TOKEN OP_CONNECT_HOST OP_CONNECT_TOKEN; do
  [[ -z ${!variable:-} ]] ||
    fail 'Remove OP_SESSION_*, OP_SERVICE_ACCOUNT_TOKEN and OP_CONNECT_* overrides for this desktop check.'
done

printf 'Native CLI: '
/usr/bin/op --version
stat -c '%A %U:%G %n' /usr/bin/op
printf 'Requesting desktop authorization (vault inventory is suppressed).\n'
if ! /usr/bin/op vault list --format=json >/dev/null; then
  fail 'Desktop authentication failed. Check Settings → Security → system authentication and Settings → Developer → CLI integration, and the KDE Polkit agent.'
fi
printf 'CLI authentication succeeded. Confirm the desktop prompt; repeat from Ghostty with 1Password locked.\n'

run_help=$(/usr/bin/op run --help)
[[ "$run_help" == *--environment* ]] ||
  fail 'This CLI lacks op run --environment. Install native CLI 2.41.0 or newer before migrating application secrets.'
printf '1Password Environments CLI support is available.\n'

# The Arch desktop package may omit the vendor's MCP helper setup.
if [[ -x /opt/1Password/1password-mcp ]]; then
  [[ $(stat -c %U:%G /opt/1Password/1password-mcp) == root:onepassword-mcp && -g /opt/1Password/1password-mcp ]] ||
    fail 'The MCP helper lacks the vendor-required root:onepassword-mcp group/setgid setup. Check the native desktop package installer before using Environment import.'
  [[ $(readlink -f "$(command -v 1password-mcp || true)") == /opt/1Password/1password-mcp ]] ||
    fail 'Expose the installed /opt/1Password/1password-mcp on PATH for MCP clients.'
  printf 'Native MCP helper permissions and command path are available.\n'
fi
