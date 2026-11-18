#!/bin/bash
# Cloud agent environment setup. Mirrors nix/modules/ai/*.nix.
# Usage: setup_remote.sh claude|codex...

set -euo pipefail

warn() { echo "setup_remote: $*" >&2; }

[ $# -gt 0 ] || {
  warn "usage: $0 claude|codex..."
  exit 1
}

D=/home/user/dotfiles
[ -d "$D/AI" ] || {
  D="$HOME/dotfiles"
  [ -d "$D/AI" ] || git clone --depth 1 https://github.com/thesimonho/dotfiles.git "$D"
}
# Hooks and statusline call ~/dotfiles/...
[ "$D" = "$HOME/dotfiles" ] || ln -sfn "$D" "$HOME/dotfiles"

AGENTS_OK=0

# Builds agents for every client in one run (needs node + Python yq)
generate_agents() {
  command -v yq >/dev/null || pip install --quiet yq >/dev/null 2>&1 || true
  if command -v node >/dev/null && command -v yq >/dev/null; then
    AGENTS_SOURCE_DIR="$D/AI/agents" AGENTS_OUTPUT_DIR="$D/AI/agents/.generated" \
      SHARED_SKILLS_DIR="$HOME/.agents/skills" node "$D/AI/lib/agents/generate-agent-configs.js"
    AGENTS_OK=1
  else
    warn "node or yq missing; agents skipped"
  fi
}

link_agents() {
  [ "$AGENTS_OK" = 1 ] || return 0
  rm -rf "$2"
  ln -sfn "$D/AI/agents/.generated/$1" "$2"
}

# Own and vendored skills, one link each
link_skills() {
  mkdir -p "$1"
  for s in "$D"/AI/skills/*/ "$D"/AI/skills/.agents/skills/*/; do
    n=$(basename "$s")
    rm -rf "${1:?}/$n"
    ln -sfn "${s%/}" "$1/$n"
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
  link_agents claude "$C/agents"
  link_skills "$C/skills"
  ln -sf "$D/AI/settings/claude/settings.json" "$C/settings.json"
}

setup_codex() {
  local C="$HOME/.codex"
  mkdir -p "$C"
  # Codex reads one AGENTS.md built from the fragments
  for f in "$D"/AI/instructions/fragments/*.md; do
    cat "$f"
    echo ""
  done >"$D/AI/instructions/AGENTS.generated.md"
  ln -sf "$D/AI/instructions/AGENTS.generated.md" "$C/AGENTS.md"
  link_agents codex "$C/agents"
  # Codex reads the shared skills folder
  link_skills "$HOME/.agents/skills"
  ln -sf "$D/AI/settings/codex/hooks.json" "$C/hooks.json"
  rm -rf "$C/rules"
  ln -sfn "$D/AI/settings/codex/rules" "$C/rules"
  # Codex writes to config.toml, so merge managed keys instead of linking (needs tomlkit)
  python3 -c 'import tomlkit' 2>/dev/null || pip install --quiet tomlkit >/dev/null 2>&1 || true
  python3 "$D/nix/modules/ai/scripts/merge-codex-config.py" \
    --managed "$D/AI/settings/codex/config.toml" \
    --local "$C/config.toml" \
    --state "$HOME/.local/state/dotfiles/codex/codex-managed-keys.json" ||
    warn "codex config merge failed"
}

generate_agents
for client in "$@"; do
  case "$client" in
  claude) setup_claude ;;
  codex) setup_codex ;;
  *)
    warn "unknown client: $client"
    exit 1
    ;;
  esac
done
install_apps
