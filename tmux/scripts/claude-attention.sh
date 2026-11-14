#!/usr/bin/env bash
# Tracks which tmux panes hold a Claude Code session that needs attention.
#   hook   Claude Code hook entry point; reads the hook payload on stdin.
#   count  status-right segment summarising attention across all sessions.
#   jump   switch to the oldest pane needing attention, other than the current one.
#   menu   pick a pane needing attention from a menu.
# State lives in pane options: @claude_state (waiting|error|done) and @claude_since (epoch).
set -euo pipefail

PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
iterm_bundle_id="com.googlecode.iterm2"

usage() { echo "usage: $0 hook|count|jump|menu" >&2; exit 2; }

pane_state() {
  tmux display-message -p -t "$1" '#{@claude_state}' 2>/dev/null || true
}

set_state() {
  local pane="$1" state="$2"
  tmux set-option -p -t "$pane" @claude_state "$state" \; \
    set-option -p -t "$pane" @claude_since "$(date +%s)"
}

clear_state() {
  local pane="$1"
  tmux set-option -p -u -t "$pane" @claude_state \; \
    set-option -p -u -t "$pane" @claude_since
}

# "Visible" means the pane is the active pane of the active window in an attached session.
pane_visible() {
  [[ "$(tmux display-message -p -t "$1" \
    '#{&&:#{session_attached},#{&&:#{window_active},#{pane_active}}}')" == "1" ]]
}

iterm_frontmost() {
  lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null | grep -q "$iterm_bundle_id"
}

notify() {
  local pane="$1" title="$2" message="$3" socket target click
  command -v terminal-notifier >/dev/null || return 0
  socket="$(tmux display-message -p '#{socket_path}')"
  target="$(tmux display-message -p -t "$pane" '#{session_name}:#{window_index}.#{pane_index} #{window_name}')"
  printf -v click '%q -S %q switch-client -t %q \\; select-window -t %q \\; select-pane -t %q' \
    "$(command -v tmux)" "$socket" "$pane" "$pane" "$pane"
  # Backgrounded so the Claude Code hook never waits on Notification Center.
  terminal-notifier \
    -group "claude-${pane}" \
    -title "$title" \
    -subtitle "$target" \
    -message "$message" \
    -sound default \
    -activate "$iterm_bundle_id" \
    -execute "$click" >/dev/null 2>&1 &
}

withdraw_notification() {
  command -v terminal-notifier >/dev/null || return 0
  terminal-notifier -remove "claude-$1" >/dev/null 2>&1 &
}

alert() {
  local pane="$1" state="$2" title="$3" message="$4" previous
  previous="$(pane_state "$pane")"
  set_state "$pane" "$state"
  # PermissionRequest and Notification both fire for one prompt; only the transition alerts.
  [[ "$previous" == "$state" ]] && return 0
  if pane_visible "$pane" && iterm_frontmost; then
    return 0
  fi
  notify "$pane" "$title" "$message"
}

resolve() {
  local pane="$1" previous
  previous="$(pane_state "$pane")"
  [[ -n "$previous" ]] || return 0
  clear_state "$pane"
  [[ "$previous" == "done" ]] || withdraw_notification "$pane"
}

cmd_hook() {
  local payload event ntype message tool
  payload="$(cat)"
  [[ -n "${TMUX_PANE:-}" ]] || exit 0
  command -v jq >/dev/null || { echo "claude-attention: jq not found" >&2; exit 1; }

  # Unit separator, not tab: tab is IFS whitespace, so read would collapse empty fields.
  IFS=$'\x1f' read -r event ntype tool message < <(
    jq -r '[.hook_event_name // "", .notification_type // "", .tool_name // "", (.message // "" | gsub("[\u001f\n]"; " "))] | join("\u001f")' <<<"$payload"
  )

  case "$event" in
    PermissionRequest)
      alert "$TMUX_PANE" waiting "Claude needs permission" "${tool:-A tool} is waiting for approval"
      ;;
    Notification)
      case "$ntype" in
        permission_prompt) alert "$TMUX_PANE" waiting "Claude needs permission" "${message:-Waiting for approval}" ;;
        elicitation_dialog) alert "$TMUX_PANE" waiting "Claude has a question" "${message:-Waiting for input}" ;;
        *) ;;
      esac
      ;;
    Elicitation)
      alert "$TMUX_PANE" waiting "Claude has a question" "${message:-Waiting for input}"
      ;;
    StopFailure)
      alert "$TMUX_PANE" error "Claude stopped with an error" "${message:-The turn failed}"
      ;;
    Stop)
      if pane_visible "$TMUX_PANE"; then
        resolve "$TMUX_PANE"
      else
        withdraw_notification "$TMUX_PANE"
        set_state "$TMUX_PANE" "done"
      fi
      ;;
    UserPromptSubmit | PostToolUse | PostToolUseFailure | ElicitationResult | SessionEnd)
      resolve "$TMUX_PANE"
      ;;
    *) ;;
  esac
}

cmd_count() {
  local waiting=0 errored=0 done_count=0 state out=""
  while IFS= read -r state; do
    case "$state" in
      waiting) waiting=$((waiting + 1)) ;;
      error) errored=$((errored + 1)) ;;
      done) done_count=$((done_count + 1)) ;;
      *) ;;
    esac
  done < <(tmux list-panes -a -F '#{@claude_state}')
  (( waiting + errored + done_count > 0 )) || exit 0
  (( waiting > 0 )) && out+=" #[fg=#f7768e]● ${waiting}"
  (( errored > 0 )) && out+=" #[fg=#f7768e]✕ ${errored}"
  (( done_count > 0 )) && out+=" #[fg=#e0af68]● ${done_count}"
  printf '#[fg=#3b4261] •%s' "$out"
}

# Prints "<pane_id>\t<label>" for panes needing attention: waiting/error first, then done, oldest first.
attention_panes() {
  tmux list-panes -a -F '#{@claude_state}	#{@claude_since}	#{pane_id}	#{session_name}:#{window_index}.#{pane_index} #{window_name}' |
    awk -F '\t' '$1 != "" { rank = ($1 == "done") ? 1 : 0; print rank "\t" $2 "\t" $3 "\t" $1 "  " $4 }' |
    sort -t $'\t' -k1,1n -k2,2n |
    cut -f3-
}

go_to() {
  tmux switch-client -t "$1" \; select-window -t "$1" \; select-pane -t "$1"
}

cmd_jump() {
  local current pane label
  current="$(tmux display-message -p '#{pane_id}')"
  while IFS=$'\t' read -r pane label; do
    [[ "$pane" == "$current" ]] && continue
    go_to "$pane"
    return 0
  done < <(attention_panes)
  tmux display-message "No Claude sessions need attention"
}

cmd_menu() {
  local pane label key=0 args=()
  while IFS=$'\t' read -r pane label; do
    key=$((key + 1))
    args+=("$label" "$(( key % 10 ))" "switch-client -t $pane ; select-window -t $pane ; select-pane -t $pane")
  done < <(attention_panes)
  if (( ${#args[@]} == 0 )); then
    tmux display-message "No Claude sessions need attention"
    return 0
  fi
  tmux display-menu -T "#[align=centre] Claude " -x C -y C "${args[@]}"
}

[[ $# -ge 1 ]] || usage
case "$1" in
  hook) cmd_hook ;;
  count) cmd_count ;;
  jump) cmd_jump ;;
  menu) cmd_menu ;;
  *) usage ;;
esac
