#!/usr/bin/env bash
# Installs the pinned Neovim release to /usr/local on Ubuntu. apt's Neovim is
# too old for this config (it relies on vim.pack, added in 0.12).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

readonly NVIM_VERSION="0.12.6"
declare -A NVIM_SHA256=(
  [x86_64]="474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87"
  [arm64]="8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815"
)
readonly NVIM_SHA256
readonly PREFIX="/usr/local"
readonly INSTALL_DIR="$PREFIX/lib/nvim-$NVIM_VERSION"

usage() {
  echo "usage: $(basename "$0")" >&2
  exit 2
}

main() {
  [[ $# -eq 0 ]] || usage
  require_ubuntu

  if [[ "$("$PREFIX/bin/nvim" --version 2>/dev/null | head -n 1 || true)" == "NVIM v$NVIM_VERSION" ]]; then
    log "Neovim $NVIM_VERSION already installed"
    return
  fi

  local arch tmp
  arch="$(detect_arch)"
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064 # expand now: tmp is local and gone by EXIT time
  trap "rm -rf '$tmp'" EXIT

  download_verified \
    "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-${arch}.tar.gz" \
    "${NVIM_SHA256[$arch]}" \
    "$tmp/nvim.tar.gz"

  tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"

  # Versioned dir + symlink: the previous version stays usable until the link is swapped.
  sudo rm -rf "${INSTALL_DIR:?}"
  sudo mkdir -p "$PREFIX/lib"
  # cp as root (not mv) so the tree is root-owned like the rest of /usr/local.
  sudo cp -R "$tmp/nvim-linux-${arch}" "$INSTALL_DIR"
  sudo ln -sfn "$INSTALL_DIR/bin/nvim" "$PREFIX/bin/nvim"

  log "installed $("$PREFIX/bin/nvim" --version | head -n 1)"
  if [[ "$(command -v nvim)" != "$PREFIX/bin/nvim" ]]; then
    log "warning: '$(command -v nvim)' shadows $PREFIX/bin/nvim on PATH; remove the apt package: sudo apt remove neovim"
  fi
}

main "$@"
