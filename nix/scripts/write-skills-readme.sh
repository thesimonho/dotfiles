#!/usr/bin/env bash
set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
skills_dir="$dotfiles_dir/AI/skills"
readme_path="$skills_dir/README.md"

skill_title_for() {
  local skill_file="$1"

  awk '
    /^name:/ {
      sub(/^name:[[:space:]]*/, "")
      print
      found = 1
      exit
    }
    /^# / {
      sub(/^# /, "")
      print
      found = 1
      exit
    }
    END {
      if (!found) exit 1
    }
  ' "$skill_file" 2>/dev/null || basename "$(dirname "$skill_file")"
}

skill_description_for() {
  local skill_file="$1"

  awk '
    /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      print
      exit
    }
  ' "$skill_file"
}

{
  echo "# AI Skills"
  echo
  echo "This directory contains custom skills and imported agent skills that are linked into configured AI clients by Home Manager."
  echo
  echo "## Custom Skills"
  echo
  echo "| Skill | Description |"
  echo "| --- | --- |"

  find "$skills_dir" -mindepth 2 -maxdepth 2 -name SKILL.md -print | sort |
    while IFS= read -r skill_file; do
      skill_name="$(basename "$(dirname "$skill_file")")"
      description="$(skill_description_for "$skill_file")"
      [ -n "$description" ] || description="$(skill_title_for "$skill_file")"
      printf '| `%s` | %s |\n' "$skill_name" "$description"
    done

  echo
  echo "## Imported Agent Skills"
  echo
  echo "| Skill | Description |"
  echo "| --- | --- |"

  if [ -d "$skills_dir/.agents/skills" ]; then
    find "$skills_dir/.agents/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print | sort |
      while IFS= read -r skill_file; do
        skill_name="$(basename "$(dirname "$skill_file")")"
        description="$(skill_description_for "$skill_file")"
        [ -n "$description" ] || description="$(skill_title_for "$skill_file")"
        printf '| `%s` | %s |\n' "$skill_name" "$description"
      done
  fi
} >"$readme_path"
