#!/usr/bin/env bash
set -euo pipefail

flake_dir="${1:-.}"
host="${2:-desktop}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$script_dir/doctor-output.sh"

skill_report="$(./scripts/describe-skills.sh "$flake_dir" "$host" tsv)"
problem_rows="$(printf '%s\n' "$skill_report" | awk -F '\t' 'NR > 1 && $3 != $4')"

echo
doctor_header "skills"
echo "host: $host"

if [ -z "$problem_rows" ]; then
  skill_count="$(printf '%s\n' "$skill_report" | awk 'NR > 1 { count++ } END { print count + 0 }')"
  echo "status: $(doctor_ok) ($skill_count skills linked as configured)"
else
  echo "status: $(doctor_missing)"
  echo
  printf '%s\n' "$skill_report" |
    awk -F '\t' 'NR == 1 || $3 != $4 {
      printf "%-32s %-10s %-10s %-7s %s\n", $1, $2, $3, $4, $5
    }'
  exit 1
fi
