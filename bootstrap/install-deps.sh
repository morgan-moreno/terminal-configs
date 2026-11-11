#!/usr/bin/env bash
# Installs the build and tool dependencies the nvim and tmux configs expect on Ubuntu.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$script_dir/lib.sh"

# Keep in step with the tree-sitter used on the Mac; nvim-treesitter (main) needs the CLI to build parsers.
readonly TREE_SITTER_VERSION="0.27.2"
declare -A TREE_SITTER_SHA256=(
  [x86_64]="7ed56d152c52437397b9fcaa43cf341f49933cecc1ca291843f0d347c6e2cb3a"
  [arm64]="34fcc5c4fa7bdd2058a2a45a03b6eb9a49b03a93b6d52ec750f99b1516d98d33"
)
readonly TREE_SITTER_SHA256
declare -A TREE_SITTER_ASSET_ARCH=([x86_64]="x64" [arm64]="arm64")
readonly TREE_SITTER_ASSET_ARCH

readonly APT_PACKAGES=(
  build-essential # make + C compiler: telescope-fzf-native, LuaSnip jsregexp, treesitter parsers
  git
  curl
  ca-certificates
  unzip
  xz-utils
  gzip
  tar
  ripgrep
  fd-find
  jq            # tmux/scripts/claude.sh
  python3-venv  # mason Python-based tools
  nodejs
  npm           # mason Node-based tools (e.g. markdownlint)
  xclip         # nvim clipboard on X11
  wl-clipboard  # nvim clipboard on Wayland
  fontconfig    # fc-cache for install-font.sh
)

usage() {
  echo "usage: $(basename "$0")" >&2
  exit 2
}

install_apt_packages() {
  log "installing apt packages"
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}"
}

# Ubuntu ships fd as `fdfind` to avoid a name clash; tools and muscle memory expect `fd`.
link_fd() {
  local target
  target="$(command -v fdfind)" || die "fdfind not found after install"
  if [[ "$(readlink /usr/local/bin/fd 2>/dev/null || true)" == "$target" ]]; then
    return
  fi
  if [[ -e /usr/local/bin/fd ]]; then
    log "/usr/local/bin/fd exists and is not our symlink; leaving it"
    return
  fi
  sudo ln -s "$target" /usr/local/bin/fd
}

install_tree_sitter() {
  if [[ "$(tree-sitter --version 2>/dev/null || true)" == "tree-sitter $TREE_SITTER_VERSION"* ]]; then
    log "tree-sitter $TREE_SITTER_VERSION already installed"
    return
  fi

  local arch asset_arch tmp
  arch="$(detect_arch)"
  asset_arch="${TREE_SITTER_ASSET_ARCH[$arch]}"
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064 # expand now: tmp is local and gone by EXIT time
  trap "rm -rf '$tmp'" EXIT

  download_verified \
    "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-linux-${asset_arch}.gz" \
    "${TREE_SITTER_SHA256[$arch]}" \
    "$tmp/tree-sitter.gz"
  gunzip "$tmp/tree-sitter.gz"
  sudo install -m 0755 "$tmp/tree-sitter" /usr/local/bin/tree-sitter
  log "installed $(tree-sitter --version)"
}

main() {
  [[ $# -eq 0 ]] || usage
  require_ubuntu
  install_apt_packages
  link_fd
  install_tree_sitter
}

main "$@"
