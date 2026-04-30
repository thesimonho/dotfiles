#!/usr/bin/env bash
set -euo pipefail

#######################################
# Paths
#######################################
# Use env vars if provided (by Nix), otherwise derive from script location
if [[ -n "${AGENTS_ROOT:-}" ]] && [[ -n "${SKILLS_OUTPUT:-}" ]]; then
  : # Already set by caller
else
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  AGENTS_ROOT="$REPO_ROOT/AI/agents"
  SKILLS_OUTPUT="$HOME/.codex/skills"
fi

#######################################
# Preconditions
#######################################
if [[ ! -d "$AGENTS_ROOT" ]]; then
  echo "ERROR: $AGENTS_ROOT directory not found" >&2
  exit 1
fi

#######################################
# Ensure output directory exists
#######################################
mkdir -p "$SKILLS_OUTPUT"

#######################################
# Clean out old generated agent skills
# Only removes directories that have a corresponding .md file in agents/
#######################################
for skill_dir in "$SKILLS_OUTPUT"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"

  # If this corresponds to an agent file, remove it (will be regenerated)
  if [[ -f "$AGENTS_ROOT/$name.md" ]]; then
    rm -rf "$skill_dir"
  fi
done

#######################################
# Materialize agent skills
#
# /AI/agents/foo.md -> ~/.codex/skills/foo/SKILL.md
#######################################
shopt -s nullglob
for agent_md in "$AGENTS_ROOT"/*.md; do
  name="$(basename "$agent_md" .md)"
  skill_dir="$SKILLS_OUTPUT/$name"
  mkdir -p "$skill_dir"
  cp "$agent_md" "$skill_dir/SKILL.md"
done

echo "✓ Converted agents to skills for codex at $SKILLS_OUTPUT"
