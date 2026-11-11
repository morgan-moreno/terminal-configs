#!/usr/bin/env bash
# Prints " <branch> +staged ~modified ?untracked ↑ahead ↓behind" for the given directory.
set -euo pipefail

usage() { echo "usage: $0 <directory>" >&2; exit 2; }
[[ $# -eq 1 ]] || usage
dir="$1"
[[ -d "$dir" ]] || exit 0

status="$(git -C "$dir" status --porcelain=v1 --branch 2>/dev/null)" || exit 0

branch="" ahead=0 behind=0 staged=0 modified=0 untracked=0
while IFS= read -r line; do
  case "$line" in
    '## '*)
      header="${line#\#\# }"
      if [[ "$header" == "HEAD (no branch)" ]]; then
        branch="$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo detached)"
      else
        branch="${header%%...*}"
        branch="${branch#No commits yet on }"
        branch="${branch%% *}"
      fi
      [[ "$header" =~ ahead\ ([0-9]+) ]] && ahead="${BASH_REMATCH[1]}"
      [[ "$header" =~ behind\ ([0-9]+) ]] && behind="${BASH_REMATCH[1]}"
      ;;
    '??'*) untracked=$((untracked + 1)) ;;
    *)
      [[ "${line:0:1}" != " " ]] && staged=$((staged + 1))
      [[ "${line:1:1}" != " " ]] && modified=$((modified + 1))
      ;;
  esac
done <<<"$status"

out="#[fg=#3b4261] • #[fg=#7aa2f7] ${branch}"
(( staged > 0 )) && out+=" #[fg=#9ece6a]+${staged}"
(( modified > 0 )) && out+=" #[fg=#e0af68]~${modified}"
(( untracked > 0 )) && out+=" #[fg=#565f89]?${untracked}"
(( ahead > 0 )) && out+=" #[fg=#7dcfff]↑${ahead}"
(( behind > 0 )) && out+=" #[fg=#f7768e]↓${behind}"
printf '%s' "$out"
