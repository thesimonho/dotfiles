#!/bin/bash

# Colors
RED="\033[0;31m"
MAGENTA="\033[0;35m"
BRIGHT_BLUE="\033[0;94m"
BRIGHT_YELLOW="\033[0;93m"
BRIGHT_GREEN="\033[0;92m"
RESET="\033[0m"

input=$(cat)
NOW=$(date +%s)

# Pace thresholds: runway is "how much of remaining time your remaining quota covers" (100 = perfect pace)
# Raise them to be more aggressive (warn earlier), lower them to be more relaxed.
RUNWAY_RED=30    # quota lasts <30% of remaining time
RUNWAY_YELLOW=60 # quota lasts <60% of remaining time

# Helpers
apply_color() {
  local color=$1
  shift
  echo -e "${color}$*${RESET}"
}
format_duration() {
  local seconds=$(($1 / 1000))
  printf "%dm%ds" "$((seconds / 60))" "$((seconds % 60))"
}
make_bar() {
  local label="$1"
  local pct="${2:-0}"
  local color_override="$3"
  local width=10
  local filled=$((pct * width / 100))
  local empty=$((width - filled))

  local color
  if [ -n "$color_override" ]; then
    color="$color_override"
  elif [ "$pct" -ge 80 ]; then
    color="$RED"
  elif [ "$pct" -ge 60 ]; then
    color="$BRIGHT_YELLOW"
  else
    color="$BRIGHT_GREEN"
  fi

  printf "%s %s[" "$label" "$color"
  printf "█%.0s" $(seq 1 "$filled")
  printf "░%.0s" $(seq 1 "$empty")
  printf "]"
}
elapsed_pct() {
  local resets_at="$1" period_secs="$2"
  local start=$((resets_at - period_secs))
  local elapsed=$((NOW - start))
  if [ "$elapsed" -le 0 ]; then
    echo 0
  elif [ "$elapsed" -ge "$period_secs" ]; then
    echo 100
  else
    echo $((elapsed * 100 / period_secs))
  fi
}
pace_color() {
  local usage_pct="$1" time_elapsed_pct="$2"
  local remaining=$((100 - time_elapsed_pct))
  local remaining_usage=$((100 - usage_pct))
  # How much of remaining time would your remaining quota last?
  # runway 100 = perfect pace, 50 = quota lasts half the remaining time, 0 = already exhausted
  local runway
  if [ "$remaining" -le 0 ]; then
    # Period is over, just use threshold fallback
    echo ""
    return
  fi
  runway=$((remaining_usage * 100 / remaining))
  if [ "$runway" -le "$RUNWAY_RED" ]; then
    echo "$RED"
  elif [ "$runway" -le "$RUNWAY_YELLOW" ]; then
    echo "$BRIGHT_YELLOW"
  else
    echo "$BRIGHT_GREEN"
  fi
}
format_epoch() {
  local epoch="$1" fmt="$2"
  [[ -z "$epoch" ]] && return
  # macOS uses date -r, Linux uses date -d @
  if date -r 0 &>/dev/null 2>&1; then
    date -r "$epoch" "+$fmt"
  else
    date -d "@${epoch}" "+$fmt"
  fi
}

# Parse all values in a single jq call
eval "$(echo "$input" | jq -r '
  @sh "model_name=\(.model.display_name)",
  @sh "duration_ms=\(.cost.total_duration_ms)",
  @sh "cost_usd=\(.cost.total_cost_usd)",
  @sh "ctx_pct=\(.context_window.used_percentage // 0 | floor)",
  @sh "five_hr_pct=\(.rate_limits.five_hour.used_percentage // 0 | floor)",
  @sh "seven_day_pct=\(.rate_limits.seven_day.used_percentage // 0 | floor)",
  @sh "five_hr_resets=\(.rate_limits.five_hour.resets_at // empty)",
  @sh "seven_day_resets=\(.rate_limits.seven_day.resets_at // empty)"
')"

# Format values
model=$(apply_color "$RED" "$model_name")
duration=$(apply_color "$BRIGHT_BLUE" "$(format_duration "$duration_ms")")
cost=$(apply_color "$BRIGHT_BLUE" "\$$(echo "$cost_usd" | awk '{printf "%.2f", $1}')")

five_hr_reset_str=$(format_epoch "$five_hr_resets" "%-I%p" | tr '[:upper:]' '[:lower:]')
seven_day_reset_str=$(format_epoch "$seven_day_resets" "%a %-I%p" | tr '[:upper:]' '[:lower:]')

context_bar="$(make_bar "ctx" "$ctx_pct") ${ctx_pct}%${RESET}"

five_hr_color=""
if [ -n "$five_hr_resets" ]; then
  five_hr_elapsed=$(elapsed_pct "$five_hr_resets" 18000)
  five_hr_color=$(pace_color "$five_hr_pct" "$five_hr_elapsed")
fi
five_hour_bar="$(make_bar "5h" "$five_hr_pct" "$five_hr_color") ${five_hr_pct}%${five_hr_reset_str:+ ($five_hr_reset_str)}${RESET}"

seven_day_color=""
if [ -n "$seven_day_resets" ]; then
  seven_day_elapsed=$(elapsed_pct "$seven_day_resets" 604800)
  seven_day_color=$(pace_color "$seven_day_pct" "$seven_day_elapsed")
fi
seven_day_bar="$(make_bar "7d" "$seven_day_pct" "$seven_day_color") ${seven_day_pct}%${seven_day_reset_str:+ ($seven_day_reset_str)}${RESET}"

echo -e "${model}  |  ${duration} ${cost}  |  ${context_bar}  -  ${five_hour_bar}  -  ${seven_day_bar}"
