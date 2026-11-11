#!/usr/bin/env bash
# Prints the pane path with $HOME shortened to ~, truncated to the last two
# components when longer than 40 characters
dir="${1:-$PWD}"
case "$dir" in
	"$HOME") dir="~" ;;
	"$HOME"/*) dir="~${dir#"$HOME"}" ;;
esac
if [ "${#dir}" -gt 40 ]; then
	dir=".../$(basename "$(dirname "$dir")")/$(basename "$dir")"
fi
printf '%s' "$dir"
