#!/usr/bin/env bash
# Prints "✻ 5H <used>% 7D <used>%" from the cache written by ~/.claude/statusline-usage-cache.sh.
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/claude/usage.json"
stale_after=1800

[[ -r "$cache_file" ]] || exit 0
command -v jq >/dev/null || exit 0

color_for() {
  local left="$1"
  if (( left < 20 )); then
    printf '#f7768e'
  elif (( left < 50 )); then
    printf '#e0af68'
  else
    printf '#9ece6a'
  fi
}

format_remaining() {
  local label="$1" secs="$2" d h m
  d=$(( secs / 86400 ))
  h=$(( secs % 86400 / 3600 ))
  m=$(( secs % 3600 / 60 ))
  if [[ "$label" == "7D" ]]; then
    printf '%dd %02dh %02dm' "$d" "$h" "$m"
  else
    printf '%dh %02dm' "$(( d * 24 + h ))" "$m"
  fi
}

window_segment() {
  local label="$1" used="$2" resets_at="$3" now="$4" left remaining=""
  if [[ -z "$used" ]]; then
    printf '#[fg=#565f89]%s --%%' "$label"
    return
  fi
  # A window past its reset time has been refilled even if no session has reported since.
  if [[ -n "$resets_at" ]] && (( now >= resets_at )); then
    used=0
  elif [[ -n "$resets_at" ]]; then
    remaining=" #[fg=#565f89]$(format_remaining "$label" "$(( resets_at - now ))")"
  fi
  used=${used%.*}
  (( used > 100 )) && used=100
  # Color still keys on what is left, so red means nearly exhausted.
  left=$(( 100 - used ))
  printf '#[fg=#565f89]%s #[fg=%s]%s%%%s' "$label" "$(color_for "$left")" "$used" "$remaining"
}

now="$(date +%s)"
read -r updated_at h_used h_reset d_used d_reset < <(
  jq -r '[
    .updated_at,
    (.five_hour.used_percentage // ""), (.five_hour.resets_at // ""),
    (.seven_day.used_percentage // ""), (.seven_day.resets_at // "")
  ] | map(if . == "" then "-" else tostring end) | join(" ")' "$cache_file"
)
[[ "$h_used" == "-" ]] && h_used=""
[[ "$h_reset" == "-" ]] && h_reset=""
[[ "$d_used" == "-" ]] && d_used=""
[[ "$d_reset" == "-" ]] && d_reset=""

icon_color='#bb9af7'
if (( now - updated_at > stale_after )); then
  icon_color='#565f89'
fi

printf '#[fg=#3b4261] • #[fg=%s]✻ %s %s' \
  "$icon_color" \
  "$(window_segment 5H "$h_used" "$h_reset" "$now")" \
  "$(window_segment 7D "$d_used" "$d_reset" "$now")"
