#!/usr/bin/env bash
# Installs JetBrainsMono Nerd Font for the current user on Ubuntu. Only matters
# where the terminal emulator runs: over SSH, install the font on the client instead.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

readonly NERD_FONTS_VERSION="3.5.1"
readonly FONT_SHA256="04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf"
readonly FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/JetBrainsMonoNerdFont"
readonly VERSION_STAMP="$FONT_DIR/.nerd-fonts-version"

usage() {
  echo "usage: $(basename "$0")" >&2
  exit 2
}

main() {
  [[ $# -eq 0 ]] || usage
  require_ubuntu
  command -v fc-cache >/dev/null || die "fc-cache not found; run install-deps.sh first"

  if [[ "$(cat "$VERSION_STAMP" 2>/dev/null || true)" == "$NERD_FONTS_VERSION" ]]; then
    log "JetBrainsMono Nerd Font $NERD_FONTS_VERSION already installed"
    return
  fi

  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064 # expand now: tmp is local and gone by EXIT time
  trap "rm -rf '$tmp'" EXIT

  download_verified \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONTS_VERSION}/JetBrainsMono.tar.xz" \
    "$FONT_SHA256" \
    "$tmp/JetBrainsMono.tar.xz"

  mkdir -p "$tmp/extract"
  tar -xJf "$tmp/JetBrainsMono.tar.xz" -C "$tmp/extract"

  rm -rf "${FONT_DIR:?}"
  mkdir -p "$FONT_DIR"
  find "$tmp/extract" -name '*.ttf' -exec cp {} "$FONT_DIR/" \;
  printf '%s\n' "$NERD_FONTS_VERSION" >"$VERSION_STAMP"

  fc-cache -f "$FONT_DIR"
  log "installed JetBrainsMono Nerd Font $NERD_FONTS_VERSION to $FONT_DIR"
  log "select 'JetBrainsMono Nerd Font' in your terminal emulator's profile"
}

main "$@"
