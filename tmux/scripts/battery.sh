#!/usr/bin/env bash
# Prints battery icon and percent (pmset on macOS, /sys/class/power_supply on Linux);
# prints nothing on machines without a battery.
set -euo pipefail

# Each reader prints "<percent> <on_ac>" (on_ac is 1 or 0), or nothing when there is no battery.
read_macos() {
  local line
  line="$(pmset -g batt 2>/dev/null | grep -E 'InternalBattery' || true)"
  [[ -n "$line" ]] || return 0
  [[ "$line" =~ ([0-9]+)% ]] || return 0
  local on_ac=0
  if [[ "$line" == *"; charging"* || "$line" == *"AC attached"* || "$line" == *"; charged"* ]]; then
    on_ac=1
  fi
  printf '%s %s' "${BASH_REMATCH[1]}" "$on_ac"
}

read_linux() {
  local supply
  for supply in /sys/class/power_supply/*; do
    [[ "$(cat "$supply/type" 2>/dev/null || true)" == "Battery" ]] || continue
    [[ -r "$supply/capacity" ]] || continue
    local pct status on_ac=0
    pct="$(cat "$supply/capacity")"
    status="$(cat "$supply/status" 2>/dev/null || true)"
    # "Not charging" = on AC but held below a charge threshold, same as pmset's "AC attached".
    case "$status" in
      Charging | Full | "Not charging") on_ac=1 ;;
    esac
    printf '%s %s' "$pct" "$on_ac"
    return 0
  done
}

case "$(uname -s)" in
  Darwin) reading="$(read_macos)" ;;
  Linux) reading="$(read_linux)" ;;
  *) exit 0 ;;
esac
[[ -n "$reading" ]] || exit 0
read -r pct on_ac <<<"$reading"
[[ "$pct" =~ ^[0-9]+$ ]] || exit 0
(( pct > 100 )) && pct=100

icons=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
icon="${icons[$(( pct / 10 ))]}"
if (( on_ac == 1 )); then
  icon="󰂄"
fi

if (( pct <= 15 )); then
  color='#f7768e'
elif (( pct <= 30 )); then
  color='#e0af68'
else
  color='#9ece6a'
fi

printf '#[fg=#3b4261] • #[fg=%s]%s %s%%' "$color" "$icon" "$pct"
