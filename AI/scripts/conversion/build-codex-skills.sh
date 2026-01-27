#!/usr/bin/env bash
set -euo pipefail

#######################################
# Paths
#######################################
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENTS_ROOT="$REPO_ROOT/agents"
SKILLS_OUTPUT="$REPO_ROOT/agents/codex_generated"

#######################################
# Preconditions
#######################################
echo $AGENTS_ROOT
if [[ ! -d "$AGENTS_ROOT" ]]; then
  echo "ERROR: /agents directory not found" >&2
  exit 1
fi

#######################################
# Materialize agent skills
#
# /agents/foo.md -> /skills/foo/SKILL.md
#######################################
shopt -s nullglob
for agent_md in "$AGENTS_ROOT"/*.md; do
  name="$(basename "$agent_md" .md)"
  skill_dir="$SKILLS_OUTPUT/$name"
  mkdir -p "$skill_dir"
  cp "$agent_md" "$skill_dir/SKILL.md"
done

echo "✓ Converted agents to skills for codex"
