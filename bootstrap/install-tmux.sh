#!/usr/bin/env bash
# Builds the pinned tmux release from source into /usr/local on Ubuntu. apt's
# tmux is too old for tmux.conf (extended-keys-format needs 3.5+).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

readonly TMUX_VERSION="3.8"
readonly TMUX_SHA256="e79c699c7e949dccd0a4a125e17b8d1261e311b16979dbc8eb34542f3966d82e"
readonly PREFIX="/usr/local"
readonly BUILD_DEPS=(build-essential pkg-config bison libevent-dev libncurses-dev curl ca-certificates)

usage() {
  echo "usage: $(basename "$0")" >&2
  exit 2
}

main() {
  [[ $# -eq 0 ]] || usage
  require_ubuntu

  if [[ "$("$PREFIX/bin/tmux" -V 2>/dev/null || true)" == "tmux $TMUX_VERSION" ]]; then
    log "tmux $TMUX_VERSION already installed"
    return
  fi

  log "installing build dependencies"
  sudo apt-get update
  sudo apt-get install -y "${BUILD_DEPS[@]}"

  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064 # expand now: tmp is local and gone by EXIT time
  trap "rm -rf '$tmp'" EXIT

  download_verified \
    "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz" \
    "$TMUX_SHA256" \
    "$tmp/tmux.tar.gz"

  tar -xzf "$tmp/tmux.tar.gz" -C "$tmp"
  (
    cd "$tmp/tmux-${TMUX_VERSION}"
    ./configure --prefix="$PREFIX"
    make -j"$(nproc)"
    sudo make install
  )

  log "installed $("$PREFIX/bin/tmux" -V)"
  if [[ "$(command -v tmux)" != "$PREFIX/bin/tmux" ]]; then
    log "warning: '$(command -v tmux)' shadows $PREFIX/bin/tmux on PATH; remove the apt package: sudo apt remove tmux"
  fi
  log "restart any running tmux server (tmux kill-server) to pick up the new version"
}

main "$@"
