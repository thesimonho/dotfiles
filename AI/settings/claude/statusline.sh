#!/bin/bash

# ─── Colors ───────────────────────────────────────────────────────────────────

BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
BRIGHT_BLACK="\033[0;90m"
BRIGHT_RED="\033[0;91m"
BRIGHT_GREEN="\033[0;92m"
BRIGHT_YELLOW="\033[0;93m"
BRIGHT_BLUE="\033[0;94m"
BRIGHT_MAGENTA="\033[0;95m"
BRIGHT_CYAN="\033[0;96m"
BRIGHT_WHITE="\033[0;97m"
RESET="\033[0m"

# ─── Config ───────────────────────────────────────────────────────────────────

# Burn rate thresholds — how fast you're spending tokens relative to how many you have  remaining.
# 1.0 = perfect pace. spending at the rate you should be to cover your usage
# 1.5 = too fast. spending 50% faster than sustainable
# 2.0 = way too fast. spending twice as fast as sustainable
BURN_YELLOW=1.25 # bar turns yellow
BURN_RED=1.5     # bar turns red

FIVE_HOURS=18000  # 5 * 60 * 60
SEVEN_DAYS=604800 # 7 * 24 * 60 * 60

AUTH_TTL=3600 # 1 hour
AUTH_CACHE_DIR="/tmp/claude-statusline"
mkdir -p "$AUTH_CACHE_DIR"

# ─── Layout helpers ───────────────────────────────────────────────────────────

visible_len() {
	printf '%b' "$1" |
		sed $'s/\x1b\\][0-9]*;[^\a]*\a//g' |
		sed $'s/\x1b\\[[0-9;]*m//g' |
		sed 's/\\033\\[[0-9;]*m//g' |
		wc -L
}

justify_segments() {
	local target_len="$1"
	shift
	local segments=("$@")
	local count=${#segments[@]}

	local total_content=0
	for seg in "${segments[@]}"; do
		total_content=$((total_content + $(visible_len "$seg")))
	done

	local separators=$((count - 1))
	local total_gap=$((target_len - total_content - separators))
	[ "$total_gap" -lt 0 ] && total_gap=0
	[ "$separators" -le 0 ] && separators=1
	local gap_each=$((total_gap / separators))
	local gap_extra=$((total_gap % separators))

	for ((i = 0; i < count; i++)); do
		printf '%b' "${segments[$i]}"
		if [ "$i" -lt $((count - 1)) ]; then
			local g=$gap_each
			[ "$i" -lt "$gap_extra" ] && g=$((g + 1))
			local left_pad=$((g / 2))
			local right_pad=$((g - left_pad))
			printf "%*s${BLACK}•${RESET}%*s" "$left_pad" "" "$right_pad" ""
		fi
	done
}

# ─── Formatting helpers ───────────────────────────────────────────────────────

apply_color() {
	local color=$1
	shift
	echo -e "${color}$*${RESET}"
}

format_duration() {
	local seconds=$(($1 / 1000))
	printf "%dm %ds" "$((seconds / 60))" "$((seconds % 60))"
}

format_epoch() {
	local epoch="$1" fmt="$2"
	[[ -z "$epoch" ]] && return
	if date -r 0 &>/dev/null 2>&1; then
		date -r "$epoch" "+$fmt" # macOS
	else
		date -d "@${epoch}" "+$fmt" # Linux
	fi
}

# Rate limit helpers

make_bar() {
	local label="$1"
	local pct="${2:-0}"
	local color_override="$3"
	local marker_pct="$4"
	local width=10
	local filled=$((pct > 0 ? (pct * width + 99) / 100 : 0))
	local marker_pos=$((marker_pct > 0 ? (marker_pct * width + 99) / 100 : 0))

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
	for ((i = 1; i <= width; i++)); do
		if [ "$marker_pos" -gt 0 ] && [ "$i" -eq "$marker_pos" ]; then
			printf "▒"
		elif [ "$i" -le "$filled" ]; then
			printf "▓"
		else
			printf "░"
		fi
	done
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

# Convert burn rate thresholds (e.g. 1.5) to integer x100 for bash math
BURN_YELLOW_I=$(echo "$BURN_YELLOW" | awk '{printf "%d", $1 * 100}')
BURN_RED_I=$(echo "$BURN_RED" | awk '{printf "%d", $1 * 100}')

pace_color() {
	local usage_pct="$1" time_elapsed_pct="$2"
	local remaining=$((100 - time_elapsed_pct))
	local remaining_usage=$((100 - usage_pct))
	if [ "$remaining" -le 0 ] || [ "$remaining_usage" -le 0 ]; then
		echo "$RED"
		return
	fi
	# burn_rate = (time_remaining / quota_remaining), scaled by 100
	local burn_rate=$((remaining * 100 / remaining_usage))
	if [ "$burn_rate" -ge "$BURN_RED_I" ]; then
		echo "$RED"
	elif [ "$burn_rate" -ge "$BURN_YELLOW_I" ]; then
		echo "$BRIGHT_YELLOW"
	else
		echo "$BRIGHT_GREEN"
	fi
}

# ─── Data ─────────────────────────────────────────────────────────────────────

input=$(cat)
NOW=$(date +%s)

# Parse statusline JSON
eval "$(echo "$input" | jq -r '
  @sh "model_name=\(.model.display_name)",
  @sh "duration_ms=\(.cost.total_duration_ms)",
  @sh "cost_usd=\(.cost.total_cost_usd)",
  @sh "ctx_pct=\(.context_window.used_percentage // 0 | floor)",
  @sh "five_hr_pct=\(.rate_limits.five_hour.used_percentage // 0 | floor)",
  @sh "seven_day_pct=\(.rate_limits.seven_day.used_percentage // 0 | floor)",
  @sh "five_hr_resets=\(.rate_limits.five_hour.resets_at // empty)",
  @sh "seven_day_resets=\(.rate_limits.seven_day.resets_at // empty)",
  @sh "cwd=\(.cwd // empty)",
  @sh "session_id=\(.session_id // empty)"
')"

# Account email (cached per session)
auth_cache="${AUTH_CACHE_DIR}/auth-${session_id}"
if [ ! -f "$auth_cache" ] || [ $((NOW - $(stat -c %Y "$auth_cache" 2>/dev/null || echo 0))) -gt $AUTH_TTL ]; then
	claude auth status --json 2>/dev/null >"$auth_cache" &
fi
account_email=$(jq -r '.email // empty' "$auth_cache" 2>/dev/null)

# ─── Format segments ─────────────────────────────────────────────────────────

# identity & session
account="${account_email:+${BRIGHT_MAGENTA}${account_email}${RESET}}"
short_cwd="${cwd/#$HOME/~}"
session_short="${session_id:0:8}"
model=$(apply_color "$RED" "$model_name")
remote_url=$(git remote get-url origin 2>/dev/null | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')
if [ -n "$remote_url" ]; then
	repo_name=$(echo "$remote_url" | sed 's|.*/\([^/]*/[^/]*\)$|\1|')
	repo_link="${CYAN}🌐 \e]8;;${remote_url}\a${repo_name}\e]8;;\a${RESET}"
fi
duration=$(apply_color "$BRIGHT_BLUE" "⏳ $(format_duration "$duration_ms")")
cost=$(apply_color "$BRIGHT_BLUE" "💰 \$$(echo "$cost_usd" | awk '{printf "%.2f", $1}')")

# usage
context_bar="$(make_bar "ctx" "$ctx_pct") ${ctx_pct}%${RESET}"

five_hr_reset_str=$(format_epoch "$five_hr_resets" "%-I:%M%p" | tr '[:upper:]' '[:lower:]')
five_hr_color=""
if [ -n "$five_hr_resets" ]; then
	five_hr_elapsed=$(elapsed_pct "$five_hr_resets" $FIVE_HOURS)
	five_hr_color=$(pace_color "$five_hr_pct" "$five_hr_elapsed")
fi
five_hour_bar="$(make_bar "5h" "$five_hr_pct" "$five_hr_color" "$five_hr_elapsed") ${five_hr_pct}%${five_hr_reset_str:+ ($five_hr_reset_str)}${RESET}"

seven_day_reset_str=$(format_epoch "$seven_day_resets" "%a/%-I:%M%p" | awk -F/ '{printf "%s%s/%s", toupper(substr($1,1,1)), substr($1,2), tolower($2)}')
seven_day_color=""
if [ -n "$seven_day_resets" ]; then
	seven_day_elapsed=$(elapsed_pct "$seven_day_resets" $SEVEN_DAYS)
	seven_day_color=$(pace_color "$seven_day_pct" "$seven_day_elapsed")
fi
seven_day_bar="$(make_bar "7d" "$seven_day_pct" "$seven_day_color" "$seven_day_elapsed") ${seven_day_pct}%${seven_day_reset_str:+ ($seven_day_reset_str)}${RESET}"

# ─── Output ───────────────────────────────────────────────────────────────────

if [ -n "$account_email" ]; then
	line1=("${account}" "${CYAN}${short_cwd}${RESET}")
else
	line1=("${CYAN}${short_cwd}${RESET}")
fi
[ -n "$repo_link" ] && line1+=("${repo_link}")
line1+=("${BRIGHT_BLUE}${session_short}${RESET}" "${duration} | ${cost}")
line2=("${model}" "${context_bar}" "${five_hour_bar}" "${seven_day_bar}")

# Match both lines to the wider one
width1=0
for s in "${line1[@]}"; do width1=$((width1 + $(visible_len "$s"))); done
width2=0
for s in "${line2[@]}"; do width2=$((width2 + $(visible_len "$s"))); done
seps1=$(((${#line1[@]} - 1) * 3))
seps2=$(((${#line2[@]} - 1) * 3))
target1=$((width1 + seps1))
target2=$((width2 + seps2))
target=$((target1 > target2 ? target1 : target2))

justify_segments "$target" "${line1[@]}"
echo
justify_segments "$target" "${line2[@]}"
echo
