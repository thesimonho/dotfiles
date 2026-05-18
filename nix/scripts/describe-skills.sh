#!/usr/bin/env bash
set -euo pipefail

flake_dir="${1:-.}"
host="${2:-desktop}"
mode="${3:-table}"
dotfiles_dir="$(cd "$flake_dir/.." && pwd)"
skills_dir="$dotfiles_dir/AI/skills"
external_skills_dir="$skills_dir/.agents/skills"
nix_eval_errors="$(mktemp)"
trap 'rm -f "$nix_eval_errors"' EXIT

nix_eval_skill_targets() {
  if ! nix --extra-experimental-features 'nix-command flakes' \
    eval --json "$flake_dir#homeConfigurations.$host.config.home.file" \
    --apply 'files: builtins.filter (name: builtins.match ".*skills/.*" name != null) (builtins.attrNames files)' \
    2> "$nix_eval_errors"; then
    cat "$nix_eval_errors" >&2
    return 1
  fi
}

print_skill_rows() {
  local source_type="$1"
  local root="$2"

  [ -d "$root" ] || return 0

  find "$root" -mindepth 2 -maxdepth 2 -name SKILL.md -print |
    while IFS= read -r skill_file; do
      local skill_dir skill_name configured_target_count current_link_count target

      skill_dir="$(dirname "$skill_file")"
      skill_name="$(basename "$skill_dir")"
      configured_target_count=0
      current_link_count=0

      while IFS= read -r target; do
        [[ "$target" == */"$skill_name" ]] || continue
        configured_target_count=$((configured_target_count + 1))

        if [ -L "$HOME/$target" ]; then
          current_link_count=$((current_link_count + 1))
        fi
      done <<< "$configured_skill_targets"

      if [ "$mode" = "tsv" ]; then
        printf '%s\t%s\t%s\t%s\t%s\n' \
          "$skill_name" "$source_type" "$configured_target_count" "$current_link_count" "$skill_dir"
      else
        printf '%-32s %-10s %-10s %-7s %s\n' \
          "$skill_name" "$source_type" "$configured_target_count" "$current_link_count" "$skill_dir"
      fi
    done
}

configured_skill_targets="$(
  nix_eval_skill_targets | jq -r '.[]'
)"

if [ "$mode" = "tsv" ]; then
  printf '%s\t%s\t%s\t%s\t%s\n' "skill" "source" "configured" "linked" "path"
else
  printf 'host: %s\n' "$host"
  printf '%-32s %-10s %-10s %-7s %s\n' "skill" "source" "configured" "linked" "path"
  printf '%-32s %-10s %-10s %-7s %s\n' "-----" "------" "----------" "------" "----"
fi

print_skill_rows "custom" "$skills_dir"
print_skill_rows "external" "$external_skills_dir"
