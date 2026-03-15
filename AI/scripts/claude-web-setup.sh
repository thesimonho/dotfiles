#!/usr/bin/env bash
# Setup script for Claude Code web environments.
# Clones the dotfiles repo and symlinks AI config into ~/.claude/
# so that web sessions get the same rules, agents, hooks, skills, and settings
# as the local Nix-managed setup.

set -euo pipefail

REPO_URL="https://github.com/thesimonho/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"
CLAUDE_DIR="$HOME/.claude"

echo "Starting Claude Code web setup..."

# Clone the repo (shallow clone for speed)
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone --depth 1 "$REPO_URL" "$DOTFILES_DIR"
else
  git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null || true
fi

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR"

# These mirror the claudeMappings in nix/modules/AI.nix
# (minus statusline — not supported in web UI)
NAMES="agents hooks rules scripts skills settings.json"
PATHS="AI/agents AI/hooks AI/rules AI/scripts AI/skills AI/settings/claude/settings.json"

set -- $PATHS
for name in $NAMES; do
  source_path="$DOTFILES_DIR/$1"
  target_path="$CLAUDE_DIR/$name"
  shift

  # Remove existing symlink
  if [ -L "$target_path" ]; then
    rm "$target_path"
  fi

  if [ -e "$source_path" ]; then
    ln -s "$source_path" "$target_path"
    echo "Linked $name -> $source_path"
  else
    echo "Warning: source not found: $source_path"
  fi
done

echo "Claude Code web setup complete."
