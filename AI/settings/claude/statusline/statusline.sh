#!/bin/bash

# Normal colors
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

# Bright colors
BRIGHT_BLACK="\033[0;90m"
BRIGHT_RED="\033[0;91m"
BRIGHT_GREEN="\033[0;92m"
BRIGHT_YELLOW="\033[0;93m"
BRIGHT_BLUE="\033[0;94m"
BRIGHT_MAGENTA="\033[0;95m"
BRIGHT_CYAN="\033[0;96m"
BRIGHT_WHITE="\033[0;97m"

# Reset
RESET="\033[0m"

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
input=$(cat)

# Helpers
apply_color() {
  local color=$1
  shift
  echo -e "${color}$*${RESET}"
}
format_duration() {
  local ms=$1
  local seconds=$((ms / 1000))
  local minutes=$((seconds / 60))
  local remaining_seconds=$((seconds % 60))
  printf "%dm%ds" "$minutes" "$remaining_seconds"
}
get_model_name() { echo "$input" | jq -r '.model.display_name'; }
get_current_dir() { echo "$input" | jq -r '.workspace.current_dir'; }
get_project_dir() { echo "$input" | jq -r '.workspace.project_dir'; }
get_version() { echo "$input" | jq -r '.version'; }
get_cost() { echo "$input" | jq -r '.cost.total_cost_usd'; }
get_duration() { echo "$input" | jq -r '.cost.total_duration_ms'; }
get_lines_added() { echo "$input" | jq -r '.cost.total_lines_added'; }
get_lines_removed() { echo "$input" | jq -r '.cost.total_lines_removed'; }
get_input_tokens() { echo "$input" | jq -r '.context_window.total_input_tokens'; }
get_output_tokens() { echo "$input" | jq -r '.context_window.total_output_tokens'; }
get_context_window_size() { echo "$input" | jq -r '.context_window.context_window_size'; }

# Use absolute path based on script location
model=$(apply_color "$RED" $(get_model_name))
duration=$(apply_color "$BRIGHT_BLUE" "$(format_duration $(get_duration))")
cost=$(apply_color "$BRIGHT_BLUE" "\$$(get_cost | awk '{printf "%.2f", $1}')")
usage=$(apply_color "$MAGENTA" "$(echo "$input" | "${SCRIPT_DIR}/modules/ccusage.sh")")

echo -e "${model}  |  ${duration} ${cost}  |  ${usage}"
