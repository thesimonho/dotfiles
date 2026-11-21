#!/bin/bash
# Cloud agent environment setup. Mirrors nix/modules/ai/*.nix.
# Usage: setup_remote.sh claude|codex...

set -euo pipefail

warn() { echo "setup_remote: $*" >&2; }

[ $# -gt 0 ] || {
  warn "usage: $0 claude|codex..."
  exit 1
}

AGENTS_OK=0
CLAUDE_READY=0

prepare_claude() {
  [ "$CLAUDE_READY" = 0 ] || return 0
  D=/home/user/dotfiles
  [ -d "$D/AI" ] || {
    D="$HOME/dotfiles"
    [ -d "$D/AI" ] || git clone --depth 1 https://github.com/thesimonho/dotfiles.git "$D"
  }
  # Hooks and statusline call ~/dotfiles/...
  [ "$D" = "$HOME/dotfiles" ] || ln -sfn "$D" "$HOME/dotfiles"
  generate_agents "$D/AI/agents/.generated" "$HOME/.agents/skills"
  CLAUDE_READY=1
}

# Builds agents for every client in one run (needs node + Python yq)
generate_agents() {
  command -v yq >/dev/null || pip install --quiet yq >/dev/null 2>&1 || true
  if command -v node >/dev/null && command -v yq >/dev/null; then
    AGENTS_SOURCE_DIR="$D/AI/agents" AGENTS_OUTPUT_DIR="$1" \
      SHARED_SKILLS_DIR="$2" node "$D/AI/lib/agents/generate-agent-configs.js"
    AGENTS_OK=1
  else
    warn "node or yq missing; agents skipped"
  fi
}

link_agents() {
  [ "$AGENTS_OK" = 1 ] || return 0
  rm -rf "$3"
  ln -sfnrT "$2/$1" "$3"
}

# Own and vendored skills, one link each
link_skills() {
  local s n
  mkdir -p "$1"
  for s in "$D"/AI/skills/*/ "$D"/AI/skills/.agents/skills/*/; do
    [ -r "${s}SKILL.md" ] || continue
    n=$(basename "$s")
    rm -rf "${1:?}/$n"
    ln -sfnrT "${s%/}" "$1/$n"
  done
}

# Apps shared by all clients; best effort
install_apps() {
  npm i -g typescript typescript-language-server || warn "typescript LSP install failed"
  npm i -g pyright || warn "pyright install failed"
  go install golang.org/x/tools/gopls@latest || warn "gopls install failed"

  NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure nixpkgs#_1password-cli || warn "1password install failed"
}

setup_claude() {
  local C="$HOME/.claude"
  mkdir -p "$C"
  # Claude Code loads ~/.claude/rules/*.md
  rm -rf "$C/rules" "$C/instructions"
  ln -sfn "$D/AI/instructions/fragments" "$C/rules"
  link_agents claude "$D/AI/agents/.generated" "$C/agents"
  link_skills "$C/skills"
  ln -sf "$D/AI/settings/claude/settings.json" "$C/settings.json"
}

setup_codex() {
  local D C="${CODEX_CLOUD_PROFILE:-/workspace/.cloud-dotfiles}" AGENTS_OK=0 f
  D=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
  mkdir -p "$C"
  C=$(cd -- "$C" && pwd -P)

  # Codex reads one AGENTS.md built from the fragments
  for f in "$D"/AI/instructions/fragments/*.md; do
    cat "$f"
    echo ""
  done >"$C/AGENTS.md"

  link_skills "$C/skills"
  generate_agents "$C/generated-agents" "$C/skills"
  [ "$AGENTS_OK" = 1 ] || return 1
  link_agents codex "$C/generated-agents" "$C/agents"

  rm -rf "$C/rules"
  ln -sfnrT "$D/AI/settings/codex/rules" "$C/rules"
  # Point the managed hooks at this checkout instead of ~/dotfiles.
  sed "s|~/dotfiles/AI/lib/hooks/runners/codex[.]js|'$D/AI/lib/hooks/runners/codex.js'|g" \
    "$D/AI/settings/codex/hooks.json" >"$C/hooks.json"

  # Codex writes to config.toml, so merge managed keys instead of linking (needs tomlkit)
  python3 -c 'import tomlkit' 2>/dev/null || python3 -m pip install --quiet tomlkit
  python3 "$D/nix/modules/ai/scripts/merge-codex-config.py" \
    --managed "$D/AI/settings/codex/config.toml" \
    --local "$C/config.toml" \
    --state "$C/state/codex-managed-keys.json"
}

for client in "$@"; do
  case "$client" in
  claude)
    prepare_claude
    setup_claude
    ;;
  codex) setup_codex ;;
  *)
    warn "unknown client: $client"
    exit 1
    ;;
  esac
done
if [ "$CLAUDE_READY" = 1 ]; then
  install_apps
fi
