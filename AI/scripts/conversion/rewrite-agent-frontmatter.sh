#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Mutates SKILL.md files in-place
# Only touches files that contain `skills:` in frontmatter

find ../../agents/codex_generated -name SKILL.md | while read -r file; do
  awk '
    BEGIN {
      in_frontmatter = 0
      frontmatter_done = 0
      skills_line = ""
      body_started = 0
    }

    /^---$/ && in_frontmatter == 0 {
      in_frontmatter = 1
      print
      next
    }

    /^---$/ && in_frontmatter == 1 {
      in_frontmatter = 0
      frontmatter_done = 1
      print
      next
    }

    in_frontmatter && /^skills:[[:space:]]*/ {
      skills_line = $0
      next
    }

    in_frontmatter && /^model:[[:space:]]*/ {
      next
    }

    frontmatter_done && body_started == 0 {
      body_started = 1

      if (skills_line != "") {
        sub(/^skills:[[:space:]]*/, "", skills_line)
        gsub(/[[:space:]]*,[[:space:]]*/, ", ", skills_line)
        print "Use the " skills_line " skills"
        print ""
      }

      print
      next
    }

    { print }
  ' "$file" >"$file.tmp"

  mv "$file.tmp" "$file"
done
